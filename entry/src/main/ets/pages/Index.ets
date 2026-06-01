import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import http from '@ohos.net.http';
import { authRepository, LoginProfile } from '../repository/AuthRepository';
import {
  FocusSmallUiAsset,
  LoginFeaturePill,
  SoftIconBadge,
  TabMinimalIcon
} from '../components/FocusVisuals';
import { ProfileView } from '../components/ProfileView';
import { ReviewView } from '../components/ReviewView';
import { TasksView } from '../components/TasksView';
import { QuickAddTaskCard, TodayView } from '../components/TodayView';
import { FocusSessionContent, FocusSettingsPanel } from '../components/FocusSessionView';
import { focusAiCoachService } from '../services/FocusAiCoachService';
import { ResourcesView } from '../components/ResourcesView';
import {
  ambientDisplayName,
  focusAmbientService,
  normalizeAmbientType
} from '../services/FocusAmbientService';
import { focusDatabase } from '../services/FocusDatabase';
import { focusSettingsService } from '../services/FocusSettingsService';
import { focusStore } from '../services/FocusStore';
import { focusSyncService } from '../services/FocusSyncService';
import { FocusBackgroundService, FocusNotificationService } from '../services/FocusNativeServices';
import {
  focusStateText as formatFocusStateText,
  formatDueText,
  formatTimerText,
  priorityColor as formatPriorityColor,
  priorityName as formatPriorityName,
  priorityTint as formatPriorityTint
} from '../utils/FocusFormatters';
import {
  ROUTE_RESOURCE_DETAIL,
  ROUTE_REVIEW_DETAIL,
  ROUTE_SETTINGS_DETAIL,
  ROUTE_SYNC_DETAIL
} from '../utils/FocusRoutes';
import {
  ACCENT,
  ACCENT_SOFT,
  BORDER,
  BORDER_SOFT,
  CARD_BG,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  CARD_SOFT,
  DANGER,
  DANGER_SOFT,
  FAINT_ON_DARK,
  GLOW_BLUE,
  GLOW_PURPLE,
  GRADIENT_ACCENT_END,
  GRADIENT_ACCENT_START,
  GRADIENT_HERO_1,
  GRADIENT_HERO_2,
  GRADIENT_HERO_3,
  MUTED_ON_DARK,
  PAGE_BG,
  PAGE_BG_END,
  PAGE_BG_MID,
  PAGE_BG_START,
  RADIUS_LG,
  RADIUS_XL,
  SHADOW_CARD_COLOR,
  SHADOW_CARD_OFFSET_X,
  SHADOW_CARD_OFFSET_Y,
  SHADOW_CARD_RADIUS,
  SHADOW_FLOAT_COLOR,
  SHADOW_FLOAT_OFFSET_X,
  SHADOW_FLOAT_OFFSET_Y,
  SHADOW_FLOAT_RADIUS,
  SPACING_LG,
  SPACING_XL,
  SPACING_XXL,
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_DIM,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  WARNING_SOFT
} from '../utils/FocusDesignTokens';
import {
  AiCoachAdvice,
  AiCoachSettings,
  FocusProject,
  FocusSettings,
  FocusTask,
  PomodoroRecord,
  PomodoroStatus,
  ResourceInsight,
  StudyResource,
  StudyResourceStatus,
  TaskStatus
} from '../models/FocusModels';

@Entry
@Component
struct Index {
  @State isAuthed: boolean = false;
  @State loginName: string = 'kyc';
  @State loginNickname: string = '本地学习者';
  @State currentNickname: string = '';
  @State currentModeText: string = '本地优先';
  @State activeTab: number = 0;
  @State tasks: FocusTask[] = focusStore.tasks;
  @State records: PomodoroRecord[] = focusStore.pomodoros;
  @State resources: StudyResource[] = focusStore.resources;
  @State settings: FocusSettings = focusStore.settings;
  @State selectedTaskId: number = 1;
  @State timerStatus: PomodoroStatus = PomodoroStatus.IDLE;
  @State remainingSeconds: number = 25 * 60;
  @State elapsedSeconds: number = 0;
  @State interruptionReason: string = '';
  @State showInterruptDialog: boolean = false;
  @State serviceMessage: string = '后台任务待机';
  @State notificationReady: boolean = false;
  @State viewportWidth: number = 390;
  @State pulseOn: boolean = false;
  @State aiAdvice: AiCoachAdvice = {
    source: '远程 AI',
    headline: '联网 AI 已接入，刷新后生成学习建议',
    nextAction: '选择一个任务并点击刷新建议。',
    sessionPlan: '根据当前任务、番茄记录和资料状态生成安排',
    risk: '若网络不可用会显示远程请求状态。',
    estimatedMinutes: 0,
    confidence: 0,
    generatedAt: Date.now()
  };
  @State aiSettings: AiCoachSettings = focusAiCoachService.defaultSettings();
  @State aiEndpointInput: string = '';
  @State aiModelInput: string = '';
  @State aiApiKeyInput: string = '';
  @State aiLoading: boolean = false;
  @State aiSettingsMessage: string = '远程 AI 默认联网接入';
  @State focusSettingsMessage: string = '时长与白噪音会自动保存到本机';
  @State newResourceTitle: string = '';
  @State newResourceContent: string = '';
  @State resourceType: string = 'note';
  @State resourceProjectId: number = 0;
  @State resourceFilterProjectId: number = 0;
  @State resourceWorkspace: string = 'library';
  @State showArchivedResources: boolean = false;
  @State selectedResourceId: number = 0;
  @State resourceLoading: boolean = false;
  @State pickedFileUri: string = '';
  @State resourceMessage: string = '资料保存到本地 RDB，并可直接联网 AI 提炼';
  @State latestResourceInsight: ResourceInsight = {
    source: '未提炼',
    summary: '选择一份资料后，可使用远程 AI 生成摘要、要点和下一步任务。',
    keyPoints: ['配置远程 AI', '选择学习资料', '生成专注任务'],
    nextTaskTitle: '等待 AI 提炼资料',
    estimatedMinutes: 25,
    generatedAt: Date.now()
  };
  @State showFocusTimer: boolean = false;
  @Provide('pathStack') navStack: NavPathStack = new NavPathStack();
  @State aiLastRefreshTime: number = 0;
  @State showAiSettingsDialog: boolean = false;
  @State syncUsername: string = '';
  @State syncPassword: string = '';
  @State syncBaseUrl: string = 'http://10.0.2.2:8080';
  @State syncStatus: string = '';
  @State aiModelList: string[] = [];
  @State aiModelLoading: boolean = false;
  private timerId: number = -1;

  aboutToAppear() {
    this.remainingSeconds = this.settings.focusMinutes * 60;
    this.initNativeStore();
  }

  aboutToDisappear() {
    this.stopTicker();
  }

  async initNativeStore() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await focusDatabase.init(context);
      await focusSettingsService.init(context);
      await focusStore.refresh();
      focusStore.settings = await focusSettingsService.loadSettings();
      this.syncFromStore();
      await authRepository.init(context);
      await focusAiCoachService.init(context);
      await focusSyncService.init(context);
      this.syncBaseUrl = focusSyncService.getBaseUrl();
      await this.loadAiSettings();
      const profile: LoginProfile | null = await authRepository.currentProfile();
      if (profile !== null) {
        this.applyProfile(profile);
      }
    } catch (err) {
      console.error(`init database failed: ${JSON.stringify(err)}`);
    }
  }

  private applyProfile(profile: LoginProfile): void {
    this.isAuthed = true;
    this.currentNickname = profile.nickname;
    this.currentModeText = profile.guest ? '游客模式 / 本地演示' : '本地账户 / 后端同步';
    AppStorage.setOrCreate<string>('auth.nickname', profile.nickname);
    AppStorage.setOrCreate<boolean>('auth.guest', profile.guest);
  }

  private async doLocalLogin(): Promise<void> {
    const profile: LoginProfile = await authRepository.loginLocal(this.loginName, this.loginNickname);
    this.applyProfile(profile);
  }

  private async doGuestLogin(): Promise<void> {
    const profile: LoginProfile = await authRepository.guest();
    this.applyProfile(profile);
  }

  private async logout(): Promise<void> {
    await authRepository.logout();
    this.isAuthed = false;
    this.currentNickname = '';
    this.navStack.clear();
  }

  private openDetailRoute(routeName: string): void {
    this.navStack.pushPathByName(routeName, null);
  }

  private closeDetailRoute(): void {
    this.navStack.pop();
  }

  private syncFromStore(): void {
    this.tasks = focusStore.tasks.slice();
    this.records = focusStore.pomodoros.slice();
    this.resources = focusStore.resources.slice();
    this.settings = focusStore.settings;
    const selected: StudyResource | undefined = this.resources.find((resource: StudyResource) => resource.id === this.selectedResourceId);
    if (selected === undefined) {
      this.selectedResourceId = this.resources.length > 0 ? this.resources[0].id : 0;
    }
  }

  private async persistFocusSettings(message: string): Promise<void> {
    const saved: FocusSettings = await focusSettingsService.saveSettings(this.settings);
    focusStore.settings = saved;
    this.settings = saved;
    if (this.timerStatus === PomodoroStatus.IDLE) {
      this.remainingSeconds = this.settings.focusMinutes * 60;
    }
    this.focusSettingsMessage = message;
  }

  private updateDurationSetting(label: string, value: number): void {
    if (label === '专注') {
      this.settings.focusMinutes = value;
      if (this.timerStatus === PomodoroStatus.IDLE) {
        this.remainingSeconds = this.settings.focusMinutes * 60;
      }
    } else if (label === '短休') {
      this.settings.shortBreakMinutes = value;
    } else {
      this.settings.longBreakMinutes = value;
    }
    this.persistFocusSettings('时长设置已保存到本机').catch(() => {
      this.focusSettingsMessage = '时长已在本次会话生效，暂未写入本机';
    });
  }

  private updateNoiseSetting(noise: string): void {
    const normalizedNoise: string = normalizeAmbientType(noise);
    this.settings.noise = normalizedNoise;
    const displayName: string = ambientDisplayName(normalizedNoise);
    if (this.timerStatus === PomodoroStatus.RUNNING) {
      focusAmbientService.play(normalizedNoise, getContext(this) as common.UIAbilityContext).catch(() => {
        this.focusSettingsMessage = `${displayName} 已保存，当前播放启动失败`;
      });
    }
    this.persistFocusSettings(`白噪音已切换为 ${displayName}`).catch(() => {
      this.focusSettingsMessage = '白噪音已在本次会话生效，暂未写入本机';
    });
  }

  private async loadAiSettings(): Promise<void> {
    const settings: AiCoachSettings = await focusAiCoachService.loadSettings();
    this.aiSettings = settings;
    this.aiEndpointInput = settings.endpoint;
    this.aiModelInput = settings.model;
    this.aiApiKeyInput = '';
    this.aiSettingsMessage = settings.apiKey.length > 0 ? 'AI 已配置' : 'AI Key 待确认';
  }

  private async refreshAiCoach(useRemote: boolean): Promise<void> {
    if (this.aiLoading) {
      return;
    }
    this.aiLoading = true;
    try {
      if (useRemote) {
        this.aiAdvice = await focusAiCoachService.requestAdvice(
          this.aiSettings,
          this.tasks,
          focusStore.projects,
          this.records,
          this.settings,
          this.selectedTaskId
        );
        this.aiSettingsMessage = 'AI 建议已更新';
      } else {
        this.aiSettingsMessage = '远程 AI 已默认接入，请直接刷新建议';
      }
    } catch (err) {
      this.aiSettingsMessage = 'AI 请求失败，请检查接口地址或服务状态';
    } finally {
      this.aiLoading = false;
    }
  }

  private async saveAiSettings(): Promise<void> {
    const nextApiKey: string = this.aiApiKeyInput.trim().length > 0 ? this.aiApiKeyInput : this.aiSettings.apiKey;
    const settings: AiCoachSettings = {
      enabled: this.aiSettings.enabled,
      endpoint: this.aiEndpointInput,
      model: this.aiModelInput,
      apiKey: nextApiKey
    };
    this.aiSettings = await focusAiCoachService.saveSettings(settings);
    this.aiEndpointInput = this.aiSettings.endpoint;
    this.aiModelInput = this.aiSettings.model;
    this.aiApiKeyInput = '';
    this.aiSettingsMessage = `已保存：${this.aiSettings.endpoint}`;
    this.showAiSettingsDialog = false;
  }

  private async fetchModelList(): Promise<void> {
    if (this.aiModelLoading) {
      return;
    }
    this.aiModelLoading = true;
    this.aiSettingsMessage = '正在拉取模型列表...';

    try {
      const endpoint: string = this.aiEndpointInput.trim().length > 0 ? this.aiEndpointInput : this.aiSettings.endpoint;
      const apiKey: string = this.aiApiKeyInput.trim().length > 0 ? this.aiApiKeyInput : this.aiSettings.apiKey;

      if (apiKey.length === 0) {
        this.aiSettingsMessage = '请先填写 API Key';
        this.aiModelLoading = false;
        return;
      }

      const url: string = endpoint.endsWith('/v1') ? `${endpoint}/models` : `${endpoint}/v1/models`;

      const request: http.HttpRequest = http.createHttp();
      try {
        const response: http.HttpResponse = await request.request(url, {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 15000,
          readTimeout: 20000,
          header: {
            'Authorization': `Bearer ${apiKey}`
          }
        });

        const responseCode: number = Number(response.responseCode);
        if (responseCode >= 200 && responseCode < 300) {
          const resultStr: string = `${response.result}`;
          const resultObj: object = JSON.parse(resultStr);
          const data: object[] = (resultObj as Record<string, object[]>)['data'] || [];
          this.aiModelList = data.map((item: object) => (item as Record<string, string>)['id'] || '');
          this.aiSettingsMessage = `已获取 ${this.aiModelList.length} 个模型`;
        } else {
          this.aiSettingsMessage = `拉取失败：HTTP ${responseCode}`;
        }
      } finally {
        request.destroy();
      }
    } catch (err) {
      this.aiSettingsMessage = '拉取失败，请检查 API 地址或服务状态';
    } finally {
      this.aiModelLoading = false;
    }
  }

  private toggleRemoteAi(): void {
    this.aiSettings = {
      enabled: !this.aiSettings.enabled,
      endpoint: this.aiSettings.endpoint,
      model: this.aiSettings.model,
      apiKey: this.aiSettings.apiKey
    };
    this.aiSettingsMessage = this.aiSettings.enabled ? '远程 AI 开关已打开，保存后生效' : '远程 AI 已关闭';
  }

  private maskedAiKey(): string {
    const key: string = this.aiSettings.apiKey.trim();
    if (key.length === 0) {
      return '未配置';
    }
    return '已保存';
  }

  private isRemoteAdvice(): boolean {
    return this.aiAdvice.source === '远程 AI';
  }

  private adviceSourceLabel(): string {
    if (this.aiAdvice.source === '远程 AI') {
      return this.aiAdvice.source;
    }
    return '待配置';
  }

  private selectTask(taskId: number): void {
    this.selectedTaskId = taskId;
    const task: FocusTask | undefined = this.tasks.find((item: FocusTask) => item.id === taskId);
    AppStorage.setOrCreate<string>('focus.taskTitle', task === undefined ? '专注任务' : task.title);
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.startAbility({
        bundleName: 'com.example.myapplication',
        abilityName: 'FocusAbility',
        parameters: {
          taskId: taskId,
          taskTitle: task === undefined ? '专注任务' : task.title
        }
      }).catch(() => {
        this.showFocusTimer = true;
      });
    } catch (err) {
      this.showFocusTimer = true;
    }
  }

  private getSelectedTask(): FocusTask {
    const found: FocusTask | undefined = this.tasks.find((task: FocusTask) => task.id === this.selectedTaskId);
    if (found !== undefined && found.status !== TaskStatus.DELETED) {
      return found;
    }
    const fallback: FocusTask | undefined = this.tasks.find((task: FocusTask) => task.status === TaskStatus.TODO);
    return fallback === undefined ? this.tasks[0] : fallback;
  }

  private async addQuickTask(titleInput: string): Promise<void> {
    const title: string = titleInput.trim();
    if (title.length === 0) {
      return;
    }
    const projectId: number = this.defaultProjectId();
    const task: FocusTask = await focusStore.addTask(title, projectId, 1, 8);
    this.selectedTaskId = task.id;
    this.syncFromStore();
  }

  private defaultProjectId(): number {
    const defaultProject: FocusProject | undefined =
      focusStore.projects.find((project: FocusProject) => project.name === '移动开发') ||
      focusStore.projects[0];
    return defaultProject === undefined ? 1 : defaultProject.id;
  }

  private selectedResourceProjectId(): number {
    if (this.resourceProjectId > 0) {
      return this.resourceProjectId;
    }
    return this.defaultProjectId();
  }

  private async toggleTask(taskId: number): Promise<void> {
    await focusStore.toggleTask(taskId);
    this.syncFromStore();
  }

  private async deleteTask(taskId: number): Promise<void> {
    await focusStore.softDeleteTask(taskId);
    this.syncFromStore();
  }

  private async restoreTask(taskId: number): Promise<void> {
    await focusStore.restoreTask(taskId);
    this.syncFromStore();
  }

  private isRemoteAiReady(): boolean {
    return this.aiSettings.enabled && this.aiSettings.apiKey.length > 0;
  }

  private switchResourceWorkspace(mode: string): void {
    this.resourceWorkspace = mode;
    if (mode === 'memo') {
      this.resourceType = 'note';
    } else if (mode === 'upload') {
      this.resourceType = 'file';
    }
  }

  private fileNameFromUri(uri: string): string {
    const clean: string = uri.split('?')[0];
    const index: number = clean.lastIndexOf('/');
    const name: string = index >= 0 && index < clean.length - 1 ? clean.substring(index + 1) : clean;
    return name.length > 0 ? name.replace(/%20/g, ' ') : '导入文件';
  }

  private resourceInsightForDisplay(resource: StudyResource): ResourceInsight {
    const hasSavedInsight: boolean = resource.summary.length > 0 && resource.summary !== '待 AI 提炼摘要';
    return {
      source: hasSavedInsight ? '已保存提炼' : '未提炼',
      summary: hasSavedInsight ? resource.summary : '配置远程 AI 后，可为这份资料生成摘要、要点和下一步任务。',
      keyPoints: resource.keyPoints.length > 0 ? resource.keyPoints : ['配置远程 AI', '选择资料', '生成任务'],
      nextTaskTitle: hasSavedInsight ? `复习「${resource.title}」` : '等待 AI 提炼资料',
      estimatedMinutes: 25,
      generatedAt: Date.now()
    };
  }

  private selectResource(resourceId: number): void {
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      return;
    }
    this.selectedResourceId = resource.id;
    this.latestResourceInsight = this.resourceInsightForDisplay(resource);
    this.resourceMessage = `已选择：${resource.title}`;
  }

  private activeResourceCount(): number {
    return this.resources.filter((resource: StudyResource) => resource.status === StudyResourceStatus.ACTIVE).length;
  }

  private archivedResourceCount(): number {
    return this.resources.filter((resource: StudyResource) => resource.status === StudyResourceStatus.ARCHIVED).length;
  }

  private async addResource(): Promise<void> {
    const title: string = this.newResourceTitle.trim();
    const content: string = this.newResourceContent.trim();
    if (title.length === 0 || content.length === 0) {
      this.resourceMessage = '请补充资料标题和正文摘录';
      return;
    }
    const saved: StudyResource = await focusStore.addStudyResource(title, this.resourceType, this.selectedResourceProjectId(), content);
    this.newResourceTitle = '';
    this.newResourceContent = '';
    this.selectedResourceId = saved.id;
    this.syncFromStore();
    this.latestResourceInsight = this.resourceInsightForDisplay(saved);
    this.resourceMessage = '资料已写入本地，可继续提炼或生成任务';
  }

  private async pickResourceFile(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['学习资料|.pdf,.doc,.docx,.ppt,.pptx,.txt,.md'];
      const uris: Array<string> = await documentPicker.select(options);
      if (uris.length === 0) {
        this.resourceMessage = '没有选择文件';
        return;
      }
      const uri: string = uris[0];
      this.pickedFileUri = uri;
      this.resourceType = 'file';
      if (this.newResourceTitle.trim().length === 0) {
        this.newResourceTitle = this.fileNameFromUri(uri);
      }
      this.resourceMessage = `已选择文件：${this.fileNameFromUri(uri)}`;
    } catch (err) {
      this.resourceMessage = '文件选择暂不可用，可先用备忘录保存文件名和摘录';
    }
  }

  private async savePickedFileResource(): Promise<void> {
    if (this.pickedFileUri.length === 0) {
      this.resourceMessage = '请先选择一个文件';
      return;
    }
    const title: string = this.newResourceTitle.trim().length > 0 ? this.newResourceTitle.trim() : this.fileNameFromUri(this.pickedFileUri);
    const note: string = this.newResourceContent.trim();
    const content: string = note.length > 0 ?
      `文件：${this.pickedFileUri}\n备注：${note}` :
      `文件：${this.pickedFileUri}`;
    const saved: StudyResource = await focusStore.addStudyResource(title, 'file', this.selectedResourceProjectId(), content);
    this.newResourceTitle = '';
    this.newResourceContent = '';
    this.pickedFileUri = '';
    this.selectedResourceId = saved.id;
    this.syncFromStore();
    this.latestResourceInsight = this.resourceInsightForDisplay(saved);
    this.resourceMessage = '文件资料已保存到本地资料库';
  }

  private async extractResource(resourceId: number): Promise<void> {
    if (this.resourceLoading) {
      return;
    }
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      this.resourceMessage = '请先选择一份资料';
      return;
    }
    if (!this.isRemoteAiReady()) {
      this.resourceMessage = '请先在 AI 设置中启用远程模型并填写 API Key';
      this.latestResourceInsight = this.resourceInsightForDisplay(resource);
      return;
    }
    this.resourceLoading = true;
    try {
      const insight: ResourceInsight = await focusAiCoachService.requestResourceInsight(this.aiSettings, resource);
      this.latestResourceInsight = insight;
      this.resourceMessage = insight.source;
      if (insight.source === '远程 AI') {
        await focusStore.updateResourceInsight(resource.id, insight);
        this.syncFromStore();
      }
    } finally {
      this.resourceLoading = false;
    }
  }

  private async createTaskFromResource(resourceId: number): Promise<void> {
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      this.resourceMessage = '请先选择一份资料';
      return;
    }
    const insight: ResourceInsight = resource.id === this.selectedResourceId ?
      this.latestResourceInsight :
      this.resourceInsightForDisplay(resource);
    if (insight.source !== '远程 AI' && insight.source !== '已保存提炼') {
      this.resourceMessage = '请先使用远程 AI 提炼资料，再生成任务';
      return;
    }
    const saved: FocusTask | undefined = await focusStore.createTaskFromResource(resource.id, insight.nextTaskTitle, insight.estimatedMinutes);
    this.syncFromStore();
    if (saved !== undefined) {
      this.selectedTaskId = saved.id;
      this.resourceMessage = '已从资料生成专注任务';
    }
  }

  private async archiveResource(resourceId: number): Promise<void> {
    await focusStore.archiveResource(resourceId);
    this.syncFromStore();
    this.resourceMessage = '资料已归档';
  }

  private async restoreResource(resourceId: number): Promise<void> {
    await focusStore.restoreResource(resourceId);
    this.syncFromStore();
    this.resourceMessage = '资料已恢复';
  }

  @Builder
  ResourceWorkspaceView(showHero: boolean, showFlowHint: boolean) {
    ResourcesView({
      resources: this.resources,
      resourceWorkspace: this.resourceWorkspace,
      showArchivedResources: this.showArchivedResources,
      selectedResourceId: this.selectedResourceId,
      resourceFilterProjectId: this.resourceFilterProjectId,
      resourceType: this.resourceType,
      selectedResourceProjectId: this.selectedResourceProjectId(),
      newResourceTitle: this.newResourceTitle,
      newResourceContent: this.newResourceContent,
      pickedFileUri: this.pickedFileUri,
      resourceLoading: this.resourceLoading,
      resourceMessage: this.resourceMessage,
      latestResourceInsight: this.latestResourceInsight,
      remoteAiReady: this.isRemoteAiReady(),
      remoteAiEnabled: this.aiSettings.enabled,
      activeResourceCount: this.activeResourceCount(),
      archivedResourceCount: this.archivedResourceCount(),
      extractedResourceCount: focusStore.extractedResourceCount(),
      showHero: showHero,
      showFlowHint: showFlowHint,
      onWorkspaceChange: (mode: string) => {
        this.switchResourceWorkspace(mode);
      },
      onTitleChange: (value: string) => {
        this.newResourceTitle = value;
      },
      onContentChange: (value: string) => {
        this.newResourceContent = value;
      },
      onResourceTypeChange: (type: string) => {
        this.resourceType = type;
      },
      onProjectChange: (projectId: number) => {
        this.resourceProjectId = projectId;
      },
      onAddResource: () => {
        this.addResource();
      },
      onPickFile: () => {
        this.pickResourceFile();
      },
      onClearPickedFile: () => {
        this.pickedFileUri = '';
        this.resourceMessage = '已清空待导入文件';
      },
      onSavePickedFile: () => {
        this.savePickedFileResource();
      },
      onExtractResource: (resourceId: number) => {
        this.extractResource(resourceId);
      },
      onCreateTaskFromResource: (resourceId: number) => {
        this.createTaskFromResource(resourceId);
      },
      onShowArchivedChange: (showArchived: boolean) => {
        this.showArchivedResources = showArchived;
      },
      onFilterProjectChange: (projectId: number) => {
        this.resourceFilterProjectId = projectId;
      },
      onSelectResource: (resourceId: number) => {
        this.selectResource(resourceId);
      },
      onArchiveResource: (resourceId: number) => {
        this.archiveResource(resourceId);
      },
      onRestoreResource: (resourceId: number) => {
        this.restoreResource(resourceId);
      },
      taskTitleForResource: (taskId: number): string => this.taskTitle(taskId)
    })
  }

  private startPomodoro(): void {
    if (this.timerStatus === PomodoroStatus.RUNNING) {
      return;
    }
    if (this.timerStatus === PomodoroStatus.IDLE || this.timerStatus === PomodoroStatus.FINISHED) {
      this.remainingSeconds = this.settings.focusMinutes * 60;
      this.elapsedSeconds = 0;
    }
    this.timerStatus = PomodoroStatus.RUNNING;
    this.serviceMessage = FocusBackgroundService.startPomodoroGuard();
    this.startTicker();
    focusAmbientService.play(this.settings.noise, getContext(this) as common.UIAbilityContext).catch((err: Error) => {
      console.error(`[Index] Failed to play ambient: ${JSON.stringify(err)}`);
    });
  }

  private pausePomodoro(): void {
    if (this.timerStatus !== PomodoroStatus.RUNNING) {
      return;
    }
    this.timerStatus = PomodoroStatus.PAUSED;
    this.stopTicker();
  }

  private resetPomodoro(): void {
    this.stopTicker();
    this.timerStatus = PomodoroStatus.IDLE;
    this.remainingSeconds = this.settings.focusMinutes * 60;
    this.elapsedSeconds = 0;
    this.interruptionReason = '';
    this.serviceMessage = FocusBackgroundService.stopPomodoroGuard();
  }

  private async completePomodoro(): Promise<void> {
    const task: FocusTask = this.getSelectedTask();
    const duration: number = Math.max(this.elapsedSeconds, this.settings.focusMinutes * 60);
    this.stopTicker();
    this.timerStatus = PomodoroStatus.FINISHED;
    await focusStore.recordPomodoro(task.id, duration, true, '');
    this.syncFromStore();
    this.remainingSeconds = this.settings.shortBreakMinutes * 60;
    this.elapsedSeconds = 0;
    this.serviceMessage = FocusBackgroundService.stopPomodoroGuard();
    FocusNotificationService.publishBasic('番茄完成', `${task.title} 已收获 1 个番茄`);
    await focusAmbientService.stop();
  }

  private async interruptPomodoro(): Promise<void> {
    const task: FocusTask = this.getSelectedTask();
    const reason: string = this.interruptionReason.trim().length === 0 ? '未填写原因' : this.interruptionReason.trim();
    this.stopTicker();
    this.timerStatus = PomodoroStatus.IDLE;
    await focusStore.recordPomodoro(task.id, Math.max(this.elapsedSeconds, 60), false, reason);
    this.syncFromStore();
    this.remainingSeconds = this.settings.focusMinutes * 60;
    this.elapsedSeconds = 0;
    this.interruptionReason = '';
    this.showInterruptDialog = false;
    this.serviceMessage = FocusBackgroundService.stopPomodoroGuard();
    await focusAmbientService.stop();
  }

  private startTicker(): void {
    this.stopTicker();
    this.timerId = setInterval(() => {
      if (this.timerStatus !== PomodoroStatus.RUNNING) {
        return;
      }
      if (this.remainingSeconds <= 1) {
        this.completePomodoro();
        return;
      }
      this.remainingSeconds = this.remainingSeconds - 1;
      this.elapsedSeconds = this.elapsedSeconds + 1;
      this.pulseOn = !this.pulseOn;
    }, 1000);
  }

  private stopTicker(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private async requestNotification(): Promise<void> {
    this.notificationReady = await FocusNotificationService.requestPermission();
    this.settings.notificationEnabled = this.notificationReady;
    await this.persistFocusSettings(this.notificationReady ? '通知偏好已保存到本机' : '通知未开启，偏好已保存');
  }

  private timeText(seconds: number): string {
    return formatTimerText(seconds);
  }

  private dueText(timestamp: number): string {
    return formatDueText(timestamp);
  }

  private priorityName(priority: number): string {
    return formatPriorityName(priority);
  }

  private priorityColor(priority: number): string {
    return formatPriorityColor(priority);
  }

  private priorityTint(priority: number): string {
    return formatPriorityTint(priority);
  }

  private timerProgress(): number {
    const total: number = this.settings.focusMinutes * 60;
    const done: number = Math.max(0, total - this.remainingSeconds);
    return Math.min(100, Math.round(done * 100 / total));
  }

  private taskTitle(taskId: number): string {
    const task: FocusTask | undefined = this.tasks.find((item: FocusTask) => item.id === taskId);
    return task === undefined ? '未绑定任务' : task.title;
  }

  private focusStateText(): string {
    return formatFocusStateText(this.timerStatus);
  }

  @Builder
  tabBarItem(title: string, index: number) {
    Column() {
      TabMinimalIcon({ index: index, active: this.activeTab === index })
      Text(title)
        .fontSize(11)
        .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.activeTab === index ? ACCENT : TEXT_MUTED)
        .margin({ top: 2 })
      if (this.activeTab === index) {
        Column()
          .width(20)
          .height(3)
          .borderRadius(2)
          .linearGradient({
            angle: 90,
            colors: [[ACCENT, 0.0], [SUCCESS, 1.0]]
          })
          .margin({ top: 3 })
      } else {
        Column()
          .width(20)
          .height(3)
          .margin({ top: 3 })
          .opacity(0)
      }
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    if (!this.isAuthed) {
      this.LoginScreen()
    } else {
      Navigation(this.navStack) {
        Stack() {
        Column() {
          Tabs({ index: this.activeTab, barPosition: BarPosition.End }) {
            TabContent() {
              TodayView({
                tasks: this.tasks,
                selectedTask: this.getSelectedTask(),
                totalFocusMinutes: focusStore.totalFocusMinutes(),
                notificationReady: this.notificationReady,
                onStartFocus: (taskId: number) => {
                  this.selectTask(taskId);
                },
                onToggleTask: (taskId: number) => {
                  this.toggleTask(taskId);
                },
                onDeleteTask: (taskId: number) => {
                  this.deleteTask(taskId);
                },
                onRestoreTask: (taskId: number) => {
                  this.restoreTask(taskId);
                },
                onAddTask: (title: string) => {
                  this.addQuickTask(title);
                },
                onRequestNotification: () => {
                  this.requestNotification();
                }
              })
            }
            .tabBar(this.tabBarItem('今日', 0))

            TabContent() {
              this.TasksTab()
            }
            .tabBar(this.tabBarItem('任务', 1))

            TabContent() {
              ProfileView({
                currentNickname: this.currentNickname,
                currentModeText: this.currentModeText,
                activeResourceCount: this.activeResourceCount(),
                recordCount: this.records.length,
                onLogout: () => {
                  this.logout();
                }
              })
            }
            .tabBar(this.tabBarItem('我的', 2))
          }
          .barMode(BarMode.Fixed)
          .barBackgroundColor('#E6FFFFFF')
          .barBackgroundBlurStyle(BlurStyle.COMPONENT_THIN)
          .animationDuration(220)
          .onChange((index: number) => {
            this.activeTab = index;
          })
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [[PAGE_BG_START, 0.0], [PAGE_BG_MID, 0.5], [PAGE_BG_END, 1.0]]
        })
        .onAreaChange((oldArea: Area, newArea: Area) => {
          if (typeof newArea.width === 'number') {
            this.viewportWidth = newArea.width;
          }
        })

        if (this.showInterruptDialog) {
          this.InterruptDialog()
        }

        if (this.showFocusTimer) {
          this.FocusTimerOverlay()
        }

        if (this.showAiSettingsDialog) {
          this.AiSettingsDialog()
        }
        }
        .width('100%')
        .height('100%')
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .navDestination(this.buildDestination)
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  private buildDestination(name: string, param: Object) {
    if (name === ROUTE_RESOURCE_DETAIL) {
      NavDestination() {
        this.ResourceDetailOverlay()
      }
      .hideTitleBar(true)
    } else if (name === ROUTE_REVIEW_DETAIL) {
      NavDestination() {
        this.ReviewDetailOverlay()
      }
      .hideTitleBar(true)
    } else if (name === ROUTE_SYNC_DETAIL) {
      NavDestination() {
        this.SyncDetailOverlay()
      }
      .hideTitleBar(true)
    } else if (name === ROUTE_SETTINGS_DETAIL) {
      NavDestination() {
        this.SettingsDetailOverlay()
      }
      .hideTitleBar(true)
    }
  }

  @Builder
  LoginScreen() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [[PAGE_BG_START, 0.0], [PAGE_BG_MID, 0.45], [PAGE_BG_END, 1.0]]
        })

      Column() {
        Column() {
          Row() {
            SoftIconBadge({ variant: 'timer', badgeSize: 44, fill: ACCENT_SOFT })
            Column() {
              Text('知序')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
              Text('让学习资料变成行动')
                .fontSize(13)
                .fontColor(TEXT_MUTED)
                .margin({ top: 3 })
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('资料、任务和专注记录都先落在端侧，打开就能继续。')
            .fontSize(14)
            .fontColor(TEXT_SUB)
            .lineHeight(20)
            .margin({ top: 18 })
          Row() {
            LoginFeaturePill({ variant: 'local', title: '本地数据' })
            LoginFeaturePill({ variant: 'timer', title: '番茄闭环' })
            LoginFeaturePill({ variant: 'settings', title: '灵活设置' })
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 22 })

        Column() {
          Row() {
            SoftIconBadge({ variant: 'local', badgeSize: 38, fill: SUCCESS_SOFT })
            Column() {
              Text('欢迎回来')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
              Text('选择本地账户或游客模式，稍后也可以补充同步配置。')
                .fontSize(12)
                .fontColor(TEXT_MUTED)
                .lineHeight(18)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 10 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 18 })

          Text('账号 / 本地用户名')
            .fontSize(11)
            .fontColor(TEXT_SUB)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 6 })
          TextInput({ placeholder: '例如：kyc', text: this.loginName })
            .height(46)
            .backgroundColor(CARD_SOFT)
            .borderRadius(12)
            .border({ width: 1, color: BORDER_SOFT })
            .padding({ left: 14, right: 14 })
            .fontSize(14)
            .onChange((value: string) => {
              this.loginName = value;
            })
          Text('昵称')
            .fontSize(11)
            .fontColor(TEXT_SUB)
            .alignSelf(ItemAlign.Start)
            .margin({ top: 12, bottom: 6 })
          TextInput({ placeholder: '本地学习者', text: this.loginNickname })
            .height(46)
            .backgroundColor(CARD_SOFT)
            .borderRadius(12)
            .border({ width: 1, color: BORDER_SOFT })
            .padding({ left: 14, right: 14 })
            .fontSize(14)
            .onChange((value: string) => {
              this.loginNickname = value;
            })

          Button('进入本地账户')
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(ACCENT)
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 14, color: '#253A7A1A', offsetX: 0, offsetY: 6 })
            .margin({ top: 18 })
            .onClick(() => {
              this.doLocalLogin();
            })

          Button('以游客模式继续')
            .width('100%')
            .height(44)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(SURFACE_ALT)
            .fontColor(TEXT_SUB)
            .borderRadius(12)
            .margin({ top: 10 })
            .onClick(() => {
              this.doGuestLogin();
            })

          Text('核心数据保存在端侧 RDB / Preferences，并可与 Spring Boot 后端数据库同步。')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .lineHeight(16)
            .margin({ top: 14 })
        }
        .width('100%')
        .constraintSize({ maxWidth: 440 })
        .padding(24)
        .backgroundColor(CARD_GLASS)
        .backdropBlur(CARD_GLASS_BLUR)
        .borderRadius(20)
        .border({ width: 1, color: BORDER_SOFT })
        .shadow({ radius: 28, color: SHADOW_FLOAT_COLOR, offsetX: 0, offsetY: 12 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Column() {
      Row() {
        Column() {
          Text('知序')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.currentNickname.length === 0 ? '本地学习者' : this.currentNickname)
            .fontSize(12)
            .fontColor(MUTED_ON_DARK)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          Row() {
            Text('🔥')
              .fontSize(11)
              .margin({ right: 4 })
            Text(`${focusStore.streakDays()}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text(' 天')
              .fontSize(10)
              .fontColor('#B8FFFFFF')
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#1AFFFFFF')
          .borderRadius(14)
          Button('退出')
            .height(28)
            .fontSize(11)
            .backgroundColor('#1AFFFFFF')
            .fontColor('#CCFFFFFF')
            .borderRadius(14)
            .padding({ left: 10, right: 10 })
            .margin({ left: 8 })
            .onClick(() => {
              this.logout();
            })
        }
      }
      .width('100%')

      Row() {
        Text('●')
          .fontSize(8)
          .fontColor(SUCCESS)
          .margin({ right: 6 })
        Text(this.currentModeText)
          .fontSize(11)
          .fontColor('#CCFFFFFF')
        Text(' · 已保存到本地')
          .fontSize(11)
          .fontColor(FAINT_ON_DARK)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 18 })
    .linearGradient({
      angle: 160,
      colors: [[GRADIENT_HERO_1, 0.0], [GRADIENT_HERO_2, 0.5], [GRADIENT_HERO_3, 1.0]]
    })
  }

  @Builder
  DarkHeroStat(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text(label)
        .fontSize(10)
        .fontColor('#99FFFFFF')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 4, right: 4 })
  }

  @Builder
  NextFocusCard() {
    Row() {
      Image($r('app.media.focus_ui_next_marker'))
        .microAssetStyle(58)
        .margin({ right: 12 })
      Column() {
        Text('下一段专注')
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .letterSpacing(1)
        Text(this.getSelectedTask().title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
        Row() {
          this.ProjectPill(this.getSelectedTask().projectId)
          Text('·')
            .fontSize(11)
            .fontColor(TEXT_DIM)
            .margin({ left: 8, right: 8 })
          Text(this.priorityName(this.getSelectedTask().priority))
            .fontSize(11)
            .fontColor(this.priorityColor(this.getSelectedTask().priority))
          Text('·')
            .fontSize(11)
            .fontColor(TEXT_DIM)
            .margin({ left: 8, right: 8 })
          Text(this.dueText(this.getSelectedTask().dueAt))
            .fontSize(11)
            .fontColor(TEXT_MUTED)
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Button('开始')
        .height(36)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(ACCENT)
          .linearGradient({
            angle: 90,
            colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
          })
          .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
        .fontColor('#FFFFFF')
        .borderRadius(10)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.selectTask(this.getSelectedTask().id);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(16)
    .border({ width: { left: 3 }, color: { left: ACCENT } })
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Center)
    .shadow({ radius: 22, color: '#0D0F1A34', offsetX: 0, offsetY: 10 })
  }

  @Builder
  AiCoachMetric(label: string, value: string, icon: string) {
    Row() {
      FocusSmallUiAsset({ variant: icon, assetSize: 28 })
      Column() {
        Text(label)
          .fontSize(10)
          .fontColor(TEXT_MUTED)
        Text(value)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
    }
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  TasksTab() {
    Scroll() {
      Column() {
        QuickAddTaskCard({
          notificationReady: this.notificationReady,
          onAddTask: (title: string) => {
            this.addQuickTask(title);
          },
          onRequestNotification: () => {
            this.requestNotification();
          }
        })
        TasksView({
          tasks: this.tasks,
          onToggleTask: (taskId: number) => {
            this.toggleTask(taskId);
          },
          onStartFocus: (taskId: number) => {
            this.selectTask(taskId);
          },
          onDeleteTask: (taskId: number) => {
            this.deleteTask(taskId);
          },
          onRestoreTask: (taskId: number) => {
            this.restoreTask(taskId);
          }
        })
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ProjectPill(projectId: number) {
    Row() {
      Column()
        .width(7)
        .height(7)
        .borderRadius(3.5)
        .backgroundColor(focusStore.getProject(projectId).color)
      Text(focusStore.getProject(projectId).name)
        .fontSize(11)
        .fontColor(TEXT_SUB)
        .margin({ left: 6 })
    }
  }


  @Builder
  SettingsSection() {
    Column() {
      Row() {
        FocusSmallUiAsset({ variant: 'settings', assetSize: 42 })
        Column() {
          Text('设置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('专注时长、白噪音、AI 配置')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 14 })

      FocusSettingsPanel({
        settings: this.settings,
        aiAdvice: this.aiAdvice,
        aiSettings: this.aiSettings,
        aiEndpointInput: this.aiEndpointInput,
        aiModelInput: this.aiModelInput,
        aiApiKeyInput: this.aiApiKeyInput,
        aiLoading: this.aiLoading,
        aiSettingsMessage: this.aiSettingsMessage,
        focusSettingsMessage: this.focusSettingsMessage,
        maskedAiKey: this.maskedAiKey(),
        records: this.records,
        compactAiCard: false,
        showHistory: false,
        onRefreshAi: () => {
          this.refreshAiCoach(true);
        },
        onOpenAiSettings: () => {
          this.showAiSettingsDialog = true;
        },
        onToggleRemoteAi: () => {
          this.toggleRemoteAi();
        },
        onAiEndpointChange: (value: string) => {
          this.aiEndpointInput = value;
        },
        onAiModelChange: (value: string) => {
          this.aiModelInput = value;
        },
        onAiApiKeyChange: (value: string) => {
          this.aiApiKeyInput = value;
        },
        onSaveAiSettings: () => {
          this.saveAiSettings();
        },
        onDurationChange: (label: string, value: number) => {
          this.updateDurationSetting(label, value);
        },
        onNoiseChange: (noise: string) => {
          this.updateNoiseSetting(noise);
        },
        taskTitleForRecord: (taskId: number) => this.taskTitle(taskId)
      })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  FocusTimerOverlay() {
    Column() {
      // 顶部关闭按钮
      Row() {
        Button('返回')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#1AFFFFFF')
          .fontColor('#CCFFFFFF')
          .borderRadius(10)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.showFocusTimer = false;
          })
        Blank()
        Text('专注模式')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Text(this.focusStateText())
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#1AFFFFFF')
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      }
      .width('100%')
      .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_XXL })

      Scroll() {
        Column() {
          FocusSessionContent({
            selectedTask: this.getSelectedTask(),
            settings: this.settings,
            timerStatus: this.timerStatus,
            remainingSeconds: this.remainingSeconds,
            timerProgressValue: this.timerProgress(),
            focusStateText: this.focusStateText(),
            serviceMessage: this.serviceMessage,
            interruptedCount: focusStore.interruptedPomodoros(),
            aiAdvice: this.aiAdvice,
            aiSettings: this.aiSettings,
            aiEndpointInput: this.aiEndpointInput,
            aiModelInput: this.aiModelInput,
            aiApiKeyInput: this.aiApiKeyInput,
            aiLoading: this.aiLoading,
            aiSettingsMessage: this.aiSettingsMessage,
            focusSettingsMessage: this.focusSettingsMessage,
            maskedAiKey: this.maskedAiKey(),
            records: this.records,
            onStartPomodoro: () => {
              this.startPomodoro();
            },
            onPausePomodoro: () => {
              this.pausePomodoro();
            },
            onCompletePomodoro: () => {
              this.completePomodoro();
            },
            onInterruptPomodoro: () => {
              this.showInterruptDialog = true;
            },
            onResetPomodoro: () => {
              this.resetPomodoro();
            },
            onRefreshAi: () => {
              this.refreshAiCoach(true);
            },
            onOpenAiSettings: () => {
              this.showAiSettingsDialog = true;
            },
            onToggleRemoteAi: () => {
              this.toggleRemoteAi();
            },
            onAiEndpointChange: (value: string) => {
              this.aiEndpointInput = value;
            },
            onAiModelChange: (value: string) => {
              this.aiModelInput = value;
            },
            onAiApiKeyChange: (value: string) => {
              this.aiApiKeyInput = value;
            },
            onSaveAiSettings: () => {
              this.saveAiSettings();
            },
            onDurationChange: (label: string, value: number) => {
              this.updateDurationSetting(label, value);
            },
            onNoiseChange: (noise: string) => {
              this.updateNoiseSetting(noise);
            },
            taskTitleForRecord: (taskId: number) => this.taskTitle(taskId)
          })
        }
        .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_LG, bottom: SPACING_XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 160,
      colors: [[GRADIENT_HERO_1, 0.0], [GRADIENT_HERO_2, 0.5], [GRADIENT_HERO_3, 1.0]]
    })
  }

  @Builder
  ResourceDetailOverlay() {
    Column() {
      // 顶部关闭按钮
      Row() {
        Button('返回')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.closeDetailRoute();
          })
        Blank()
        Text('学习资源库')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text(`${this.activeResourceCount()} 份`)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(SURFACE_ALT)
          .borderRadius(8)
      }
      .width('100%')
      .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_XXL })

      // 资源详情内容
      Scroll() {
        Column() {
          this.ResourceWorkspaceView(true, false)
        }
        .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_LG, bottom: SPACING_XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }

  @Builder
  ReviewDetailOverlay() {
    Column() {
      Row() {
        Button('返回')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.closeDetailRoute();
          })
        Blank()
        Text('复盘统计')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text('')
          .width(60)
      }
      .width('100%')
      .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_XXL })

      Scroll() {
        Column() {
          ReviewView({
            recordCount: this.records.length,
            viewportWidth: this.viewportWidth,
            includeWeb: true
          })
        }
        .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_LG, bottom: SPACING_XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }

  @Builder
  SettingsDetailOverlay() {
    Column() {
      Row() {
        Button('返回')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.closeDetailRoute();
          })
        Blank()
        Text('设置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text('')
          .width(60)
      }
      .width('100%')
      .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_XXL })

      Scroll() {
        Column() {
          this.SettingsSection()
        }
        .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_LG, bottom: SPACING_XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }

  @Builder
  SyncDetailOverlay() {
    Column() {
      Row() {
        Button('返回')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.closeDetailRoute();
          })
        Blank()
        Text('云同步')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text('')
          .width(60)
      }
      .width('100%')
      .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_XXL })

      Scroll() {
        Column({ space: SPACING_LG }) {
          Column() {
            Row() {
              FocusSmallUiAsset({ variant: 'cloud', assetSize: 42 })
              Column() {
              Text('云端数据同步')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
                Text(focusSyncService.isLoggedIn() ? `当前服务器：${focusSyncService.getBaseUrl()}` : '模拟器用 10.0.2.2；真机请填电脑局域网 IP')
                  .fontSize(11)
                  .fontColor(TEXT_MUTED)
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 14 })

            Row() {
              SoftIconBadge({
                variant: focusSyncService.isLoggedIn() ? 'sync' : 'shield',
                badgeSize: 34,
                fill: focusSyncService.isLoggedIn() ? SUCCESS_SOFT : WARNING_SOFT
              })
              Column() {
                Text(focusSyncService.isLoggedIn() ? '已连接后端服务' : '连接前先确认后端已启动')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(TEXT_MAIN)
                Text(focusSyncService.isLoggedIn() ? '点击同步会先拉取服务器数据，再上推本地修改。' : '运行 .\\start-backend.ps1；默认演示账号 demo / secret。')
                  .fontSize(11)
                  .fontColor(TEXT_MUTED)
                  .lineHeight(16)
                  .margin({ top: 3 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(SURFACE_ALT)
            .borderRadius(12)
            .margin({ bottom: 14 })

            if (!focusSyncService.isLoggedIn()) {
              Text('服务器地址')
                .fontSize(12)
                .fontColor(TEXT_SUB)
                .alignSelf(ItemAlign.Start)
              TextInput({ placeholder: 'http://电脑IP:8080', text: this.syncBaseUrl })
                .height(42)
                .backgroundColor(SURFACE_ALT)
                .borderRadius(10)
                .padding({ left: 12, right: 12 })
                .fontSize(13)
                .margin({ top: 6, bottom: 10 })
                .onChange((value: string) => {
                  this.syncBaseUrl = value;
                })

              Row() {
                Button('模拟器 10.0.2.2')
                  .height(30)
                  .layoutWeight(1)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(SURFACE_ALT)
                  .fontColor(TEXT_SUB)
                  .borderRadius(9)
                  .onClick(() => {
                    this.syncBaseUrl = 'http://10.0.2.2:8080';
                  })
                Button('当前电脑 IP')
                  .height(30)
                  .layoutWeight(1)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(SURFACE_ALT)
                  .fontColor(TEXT_SUB)
                  .borderRadius(9)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.syncStatus = '请把“电脑IP”替换为本机局域网地址，例如 http://192.168.x.x:8080';
                    this.syncBaseUrl = 'http://电脑IP:8080';
                  })
              }
              .width('100%')
              .margin({ bottom: 10 })

              Text('用户名')
                .fontSize(12)
                .fontColor(TEXT_SUB)
                .alignSelf(ItemAlign.Start)
              TextInput({ placeholder: '输入用户名', text: this.syncUsername })
                .height(42)
                .backgroundColor(SURFACE_ALT)
                .borderRadius(10)
                .padding({ left: 12, right: 12 })
                .fontSize(13)
                .margin({ top: 6, bottom: 10 })
                .onChange((value: string) => {
                  this.syncUsername = value;
                })

              Text('密码')
                .fontSize(12)
                .fontColor(TEXT_SUB)
                .alignSelf(ItemAlign.Start)
              TextInput({ placeholder: '输入密码', text: this.syncPassword })
                .height(42)
                .type(InputType.Password)
                .backgroundColor(SURFACE_ALT)
                .borderRadius(10)
                .padding({ left: 12, right: 12 })
                .fontSize(13)
                .margin({ top: 6, bottom: 14 })
                .onChange((value: string) => {
                  this.syncPassword = value;
                })

              Button('登录')
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .backgroundColor(ACCENT)
                .fontColor('#FFFFFF')
                .borderRadius(12)
                .onClick(async () => {
                  if (this.syncUsername.length === 0 || this.syncPassword.length === 0) {
                    this.syncStatus = '请填写用户名和密码';
                    return;
                  }
                  this.syncStatus = '登录中...';
                  await focusSyncService.init(getContext(this) as common.UIAbilityContext);
                  await focusSyncService.saveBaseUrl(this.syncBaseUrl);
                  const result = await focusSyncService.login(this.syncUsername, this.syncPassword);
                  this.syncStatus = result.message;
                  if (result.success) {
                    this.syncPassword = '';
                  }
                })
            } else {
              Text('已登录')
                .fontSize(14)
                .fontColor(SUCCESS)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 10 })

              Button('同步数据')
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .backgroundColor(SUCCESS)
                .fontColor('#FFFFFF')
                .borderRadius(12)
                .margin({ bottom: 10 })
                .onClick(async () => {
                  this.syncStatus = '同步中...';
                  await focusSyncService.init(getContext(this) as common.UIAbilityContext);
                  const result = await focusSyncService.syncBidirectional();
                  this.syncStatus = result.message;
                  if (result.success) {
                    await focusStore.refresh();
                    this.syncFromStore();
                  }
                })

              Button('退出登录')
                .width('100%')
                .height(40)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(SURFACE_ALT)
                .fontColor(TEXT_SUB)
                .borderRadius(12)
                .onClick(async () => {
                  await focusSyncService.logout();
                  this.syncStatus = '已退出登录';
                })
            }

            if (this.syncStatus.length > 0) {
              Text(this.syncStatus)
                .fontSize(12)
                .fontColor(this.syncStatus.includes('成功') || this.syncStatus.includes('欢迎') ? SUCCESS : this.syncStatus.includes('失败') || this.syncStatus.includes('错误') ? DANGER : TEXT_MUTED)
                .margin({ top: 10 })
                .textAlign(TextAlign.Center)
                .width('100%')
            }
          }
          .width('100%')
          .padding(SPACING_LG)
          .backgroundColor(CARD_GLASS)
          .backdropBlur(CARD_GLASS_BLUR)
          .borderRadius(RADIUS_LG)
          .border({ width: 1, color: BORDER_SOFT })
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_LG, bottom: SPACING_XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }

  @Builder
  InterruptDialog() {
    Column() {
      Column() {
        Text('为什么中断？')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Text('记录原因有助于复盘注意力风险')
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .margin({ top: 4 })
        TextInput({ placeholder: '例如：临时消息、疲劳、环境干扰', text: this.interruptionReason })
          .height(46)
          .backgroundColor(SURFACE_ALT)
          .borderRadius(12)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.interruptionReason = value;
          })
        Row() {
          Button('取消')
            .height(42)
            .layoutWeight(1)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(SURFACE_ALT)
            .fontColor(TEXT_SUB)
            .borderRadius(12)
            .onClick(() => {
              this.showInterruptDialog = false;
            })
          Button('记录中断')
            .height(42)
            .layoutWeight(1)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(DANGER)
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 10 })
            .onClick(() => {
              this.interruptPomodoro();
            })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('86%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .alignItems(HorizontalAlign.Start)
      .shadow({ radius: 28, color: '#0B102622', offsetX: 0, offsetY: 14 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#0B102680')
  }

  @Builder
  AiSettingsDialog() {
    Column() {
      Column() {
        Row() {
          Text('AI 设置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Blank()
          Button('关闭')
            .height(28)
            .fontSize(12)
            .backgroundColor(SURFACE_ALT)
            .fontColor(TEXT_SUB)
            .borderRadius(8)
            .onClick(() => {
              this.showAiSettingsDialog = false;
            })
        }
        .width('100%')

        Text('配置远程 AI 服务')
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .margin({ top: 4 })

        // Base URL
        Text('API 地址')
          .fontSize(12)
          .fontColor(TEXT_SUB)
          .margin({ top: 16 })
        TextInput({ placeholder: 'https://api.example.com', text: this.aiEndpointInput })
          .height(42)
          .backgroundColor(SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .fontSize(13)
          .margin({ top: 6 })
          .onChange((value: string) => {
            this.aiEndpointInput = value;
          })

        // API Key
        Text('API Key')
          .fontSize(12)
          .fontColor(TEXT_SUB)
          .margin({ top: 12 })
        TextInput({ placeholder: '输入 API Key（留空保持原值）', text: this.aiApiKeyInput })
          .height(42)
          .backgroundColor(SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .fontSize(13)
          .margin({ top: 6 })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.aiApiKeyInput = value;
          })

        // Model
        Text('模型')
          .fontSize(12)
          .fontColor(TEXT_SUB)
          .margin({ top: 12 })
        Row() {
          TextInput({ placeholder: '选择或输入模型', text: this.aiModelInput })
            .height(42)
            .backgroundColor(SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .fontSize(13)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.aiModelInput = value;
            })
          Button(this.aiModelLoading ? '加载中' : '拉取模型')
            .height(42)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(ACCENT_SOFT)
            .fontColor(ACCENT)
            .borderRadius(10)
            .margin({ left: 8 })
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.fetchModelList();
            })
        }
        .width('100%')
        .margin({ top: 6 })

        // Model List
        if (this.aiModelList.length > 0) {
          Column() {
            Text('可用模型')
              .fontSize(11)
              .fontColor(TEXT_MUTED)
              .margin({ bottom: 6 })
            ForEach(this.aiModelList, (model: string) => {
              Row() {
                Text(model)
                  .fontSize(12)
                  .fontColor(TEXT_MAIN)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                if (this.aiModelInput === model) {
                  Text('✓')
                    .fontSize(12)
                    .fontColor(ACCENT)
                    .fontWeight(FontWeight.Bold)
                }
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor(this.aiModelInput === model ? ACCENT_SOFT : Color.Transparent)
              .borderRadius(8)
              .onClick(() => {
                this.aiModelInput = model;
              })
            })
          }
          .width('100%')
          .margin({ top: 10 })
          .padding(10)
          .backgroundColor(SURFACE_ALT)
          .borderRadius(10)
        }

        // Save Button
        Row() {
          Button('保存设置')
            .height(42)
            .layoutWeight(1)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(ACCENT)
            .linearGradient({
              angle: 90,
              colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
            })
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .onClick(() => {
              this.saveAiSettings();
            })
        }
        .width('100%')
        .margin({ top: 16 })

        Text(this.aiSettingsMessage)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .margin({ top: 8 })
          .maxLines(2)
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .alignItems(HorizontalAlign.Start)
      .shadow({ radius: 28, color: '#0B102622', offsetX: 0, offsetY: 14 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#0B102680')
  }
}

@Extend(Column)
function cardStyle() {
  .width('100%')
  .padding(SPACING_XL)
  .backgroundColor(CARD_GLASS)
  .backdropBlur(CARD_GLASS_BLUR)
  .borderRadius(RADIUS_XL)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
}

@Extend(Column)
function cardStyleTight() {
  .width('100%')
  .padding(SPACING_LG)
  .backgroundColor(CARD_GLASS)
  .backdropBlur(CARD_GLASS_BLUR)
  .borderRadius(RADIUS_LG)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_CARD_RADIUS, color: SHADOW_CARD_COLOR, offsetX: SHADOW_CARD_OFFSET_X, offsetY: SHADOW_CARD_OFFSET_Y })
}

@Extend(Image)
function microAssetStyle(size: number) {
  .width(size)
  .height(size)
  .objectFit(ImageFit.Cover)
  .borderRadius(Math.round(size / 4))
}
