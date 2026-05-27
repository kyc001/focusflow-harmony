import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import webview from '@ohos.web.webview';
import { authRepository, LoginProfile } from '../repository/AuthRepository';
import { focusAiCoachService } from '../services/FocusAiCoachService';
import { focusDatabase } from '../services/FocusDatabase';
import { focusSettingsService } from '../services/FocusSettingsService';
import { focusStore } from '../services/FocusStore';
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
  AiCoachAdvice,
  AiCoachSettings,
  FocusProject,
  FocusSettings,
  FocusTask,
  ForestPlant,
  PomodoroRecord,
  PomodoroStatus,
  ResourceInsight,
  StatPoint,
  StudyResource,
  StudyResourceStatus,
  TaskStatus
} from '../models/FocusModels';

const PAGE_BG: string = '#F3F6FB';
const CARD_BG: string = '#F8FFFFFF';
const CARD_SOFT: string = '#F1F6FA';
const BORDER: string = '#E4E9F2';
const BORDER_SOFT: string = '#DDE6F3';

const TEXT_MAIN: string = '#0E1626';
const TEXT_SUB: string = '#3F4A60';
const TEXT_MUTED: string = '#7A8398';
const TEXT_DIM: string = '#AAB1C2';

const ACCENT: string = '#4258C9';
const ACCENT_DEEP: string = '#3142A2';
const ACCENT_SOFT: string = '#EDF1FF';

const SUCCESS: string = '#1FA37A';
const SUCCESS_SOFT: string = '#EAF5F0';
const WARNING: string = '#D88B2B';
const WARNING_SOFT: string = '#FBF1E2';
const DANGER: string = '#D8556A';
const DANGER_SOFT: string = '#FBEAEE';
const VIOLET: string = '#7A60D0';
const VIOLET_SOFT: string = '#F0EDF8';
const TEAL: string = '#3FA8B3';
const TEAL_SOFT: string = '#EAF4F5';

const DEEP: string = '#151D31';
const DEEP_2: string = '#202942';
const DEEP_3: string = '#2B3552';
const DEEP_4: string = '#3D4A6F';
const MUTED_ON_DARK: string = '#B4BCD3';
const FAINT_ON_DARK: string = '#7A8299';

const SURFACE_ALT: string = '#F1F3F7';
const TRACK: string = '#E6E9F0';
const CARD_SHADOW: string = '#0B14260F';
const CARD_SHADOW_STRONG: string = '#0B102620';

const BLUE_TINT: string = '#EEF0FA';
const MINT_TINT: string = '#EAF5F0';
const WARM_TINT: string = '#FBF1E2';
const ROSE_TINT: string = '#FBEAEE';

class ReviewBridge {
  getStats(): string {
    const points: StatPoint[] = focusStore.weekFocusPoints();
    const weekJson: string = points
      .map((point: StatPoint) => `{"label":"${point.label}","value":${point.value}}`)
      .join(',');
    return `{"totalMinutes":${focusStore.totalFocusMinutes()},"completed":${focusStore.completedPomodoros()},"streak":${focusStore.streakDays()},"week":[${weekJson}]}`;
  }

  exportPng(): string {
    return 'exported';
  }

  shareReport(): string {
    return 'shared';
  }
}

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
  @State newTaskTitle: string = '';
  @State searchText: string = '';
  @State filterProjectId: number = 0;
  @State filterPriority: number = -1;
  @State showRecycle: boolean = false;
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
    source: '本地规则',
    headline: 'AI 教练正在读取本地节奏',
    nextAction: '先选择一个任务，知序会给出下一步建议。',
    sessionPlan: '25 分钟专注 + 5 分钟短休',
    risk: '离线建议始终可用，远程模型是可选增强。',
    estimatedMinutes: 25,
    confidence: 70,
    generatedAt: Date.now()
  };
  @State aiSettings: AiCoachSettings = focusAiCoachService.defaultSettings();
  @State aiEndpointInput: string = '';
  @State aiModelInput: string = '';
  @State aiApiKeyInput: string = '';
  @State aiLoading: boolean = false;
  @State aiSettingsMessage: string = 'AI 教练默认使用本地规则';
  @State focusSettingsMessage: string = '时长与白噪音会自动保存到本机';
  @State newResourceTitle: string = '';
  @State newResourceContent: string = '';
  @State resourceType: string = 'note';
  @State resourceProjectId: number = 4;
  @State resourceFilterProjectId: number = 0;
  @State resourceWorkspace: string = 'library';
  @State showArchivedResources: boolean = false;
  @State selectedResourceId: number = 0;
  @State resourceLoading: boolean = false;
  @State pickedFileUri: string = '';
  @State resourceMessage: string = '资料会保存到本地 RDB，可选 AI 提炼';
  @State latestResourceInsight: ResourceInsight = {
    source: '本地规则',
    summary: '选择一份资料后，可以生成摘要、要点和下一步任务。',
    keyPoints: ['本地保存资料', 'AI 或规则提炼', '一键生成专注任务'],
    nextTaskTitle: '整理学习资料',
    estimatedMinutes: 25,
    generatedAt: Date.now()
  };
  private timerId: number = -1;
  private webController: webview.WebviewController = new webview.WebviewController();
  private reviewBridge: ReviewBridge = new ReviewBridge();

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
      await this.loadAiSettings();
      this.refreshLocalCoachSnapshot();
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
    this.currentModeText = profile.guest ? '游客模式 / 仅本地' : '本地账户 / 可选同步';
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
    this.refreshLocalCoachSnapshot();
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
    this.settings.noise = noise;
    this.persistFocusSettings(`白噪音已切换为 ${noise}`).catch(() => {
      this.focusSettingsMessage = '白噪音已在本次会话生效，暂未写入本机';
    });
  }

  private async loadAiSettings(): Promise<void> {
    const settings: AiCoachSettings = await focusAiCoachService.loadSettings();
    this.aiSettings = settings;
    this.aiEndpointInput = settings.endpoint;
    this.aiModelInput = settings.model;
    this.aiApiKeyInput = '';
    this.aiSettingsMessage = settings.enabled && settings.apiKey.length > 0 ? `远程 AI 已配置：${this.maskedAiKey()}` : '当前使用本地 AI 教练';
  }

  private refreshLocalCoachSnapshot(): void {
    this.aiAdvice = focusAiCoachService.generateLocalAdvice(
      this.tasks,
      focusStore.projects,
      this.records,
      this.settings,
      this.selectedTaskId
    );
  }

  private async refreshAiCoach(useRemote: boolean): Promise<void> {
    if (this.aiLoading) {
      return;
    }
    this.aiLoading = true;
    try {
      if (useRemote) {
        if (!this.aiSettings.enabled || this.aiSettings.apiKey.length === 0) {
          this.aiSettingsMessage = '请先启用远程 AI 并保存 API Key，已使用本地建议';
        }
        this.aiAdvice = await focusAiCoachService.requestAdvice(
          this.aiSettings,
          this.tasks,
          focusStore.projects,
          this.records,
          this.settings,
          this.selectedTaskId
        );
      } else {
        this.refreshLocalCoachSnapshot();
        this.aiSettingsMessage = '已基于本地记录重新计算建议';
      }
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
    this.aiSettingsMessage = this.aiSettings.enabled && this.aiSettings.apiKey.length > 0 ? `远程 AI 已保存：${this.maskedAiKey()}` : '已保存，本地建议可继续使用';
  }

  private toggleRemoteAi(): void {
    this.aiSettings = {
      enabled: !this.aiSettings.enabled,
      endpoint: this.aiSettings.endpoint,
      model: this.aiSettings.model,
      apiKey: this.aiSettings.apiKey
    };
    this.aiSettingsMessage = this.aiSettings.enabled ? '远程 AI 开关已打开，保存后生效' : '已切回本地 AI 教练';
  }

  private maskedAiKey(): string {
    const key: string = this.aiSettings.apiKey.trim();
    if (key.length === 0) {
      return '未配置';
    }
    return key.length <= 8 ? '已保存' : `${key.substring(0, 3)}***${key.substring(key.length - 4)}`;
  }

  private isRemoteAdvice(): boolean {
    return this.aiAdvice.source === '远程 AI';
  }

  private adviceSourceLabel(): string {
    if (this.aiAdvice.source === '远程 AI' || this.aiAdvice.source === '本地规则') {
      return this.aiAdvice.source;
    }
    return '本地兜底';
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
        this.activeTab = 3;
      });
    } catch (err) {
      this.activeTab = 3;
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

  private async addQuickTask(): Promise<void> {
    const title: string = this.newTaskTitle.trim();
    if (title.length === 0) {
      return;
    }
    const task: FocusTask = await focusStore.addTask(title, 4, 1, 8);
    this.newTaskTitle = '';
    this.selectedTaskId = task.id;
    this.syncFromStore();
    this.refreshLocalCoachSnapshot();
  }

  private async toggleTask(taskId: number): Promise<void> {
    await focusStore.toggleTask(taskId);
    this.syncFromStore();
    this.refreshLocalCoachSnapshot();
  }

  private async deleteTask(taskId: number): Promise<void> {
    await focusStore.softDeleteTask(taskId);
    this.syncFromStore();
    this.refreshLocalCoachSnapshot();
  }

  private async restoreTask(taskId: number): Promise<void> {
    await focusStore.restoreTask(taskId);
    this.syncFromStore();
    this.refreshLocalCoachSnapshot();
  }

  private filteredTasks(): FocusTask[] {
    const keyword: string = this.searchText.trim();
    return this.tasks.filter((task: FocusTask) => {
      const projectMatched: boolean = this.filterProjectId === 0 || task.projectId === this.filterProjectId;
      const priorityMatched: boolean = this.filterPriority < 0 || task.priority === this.filterPriority;
      const keywordMatched: boolean = keyword.length === 0 ||
        task.title.indexOf(keyword) >= 0 ||
        task.note.indexOf(keyword) >= 0 ||
        task.tags.join(',').indexOf(keyword) >= 0;
      const statusMatched: boolean = this.showRecycle ? task.status === TaskStatus.DELETED : task.status !== TaskStatus.DELETED;
      return projectMatched && priorityMatched && keywordMatched && statusMatched;
    });
  }

  private resourceTypeName(type: string): string {
    if (type === 'link') {
      return '网页链接';
    }
    if (type === 'file') {
      return '本地文件';
    }
    if (type === 'pdf') {
      return '论文/PDF';
    }
    if (type === 'courseware') {
      return '课件';
    }
    return '笔记';
  }

  private resourceWorkspaceName(mode: string): string {
    if (mode === 'memo') {
      return '备忘录';
    }
    if (mode === 'upload') {
      return '文件导入';
    }
    if (mode === 'insight') {
      return 'AI 提炼';
    }
    return '资料库';
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

  private pickedFileName(): string {
    return this.pickedFileUri.length === 0 ? '尚未选择文件' : this.fileNameFromUri(this.pickedFileUri);
  }

  private pickedFilePreview(): string {
    if (this.pickedFileUri.length === 0) {
      return '选择 PDF、课件、Markdown 或文档后，会保存为资料记录。';
    }
    if (this.pickedFileUri.length <= 72) {
      return this.pickedFileUri;
    }
    return `${this.pickedFileUri.substring(0, 72)}...`;
  }

  private resourceInsightForDisplay(resource: StudyResource): ResourceInsight {
    const local: ResourceInsight = focusAiCoachService.generateLocalResourceInsight(resource);
    return {
      source: resource.summary.length > 0 && resource.summary !== '待 AI 或本地规则提炼摘要' ? '已保存提炼' : local.source,
      summary: resource.summary.length > 0 ? resource.summary : local.summary,
      keyPoints: resource.keyPoints.length > 0 ? resource.keyPoints : local.keyPoints,
      nextTaskTitle: local.nextTaskTitle,
      estimatedMinutes: local.estimatedMinutes,
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

  private selectedResource(): StudyResource | undefined {
    return this.resources.find((resource: StudyResource) => resource.id === this.selectedResourceId);
  }

  private selectedResourceTitle(): string {
    const resource: StudyResource | undefined = this.selectedResource();
    return resource === undefined ? '尚未选择资料' : resource.title;
  }

  private selectedResourceSummary(): string {
    const resource: StudyResource | undefined = this.selectedResource();
    if (resource === undefined) {
      return '从左侧资料列表选择一份内容，或先添加课程笔记、论文摘录、网页链接。';
    }
    return resource.summary.length > 0 ? resource.summary : this.latestResourceInsight.summary;
  }

  private selectedResourceKeyPoints(): string[] {
    const resource: StudyResource | undefined = this.selectedResource();
    if (resource === undefined) {
      return this.latestResourceInsight.keyPoints;
    }
    return resource.keyPoints.length > 0 ? resource.keyPoints : this.latestResourceInsight.keyPoints;
  }

  private resourceInsightSourceLabel(): string {
    if (this.latestResourceInsight.source === '远程 AI' || this.latestResourceInsight.source === '本地规则' || this.latestResourceInsight.source === '已保存提炼') {
      return this.latestResourceInsight.source;
    }
    return '本地兜底';
  }

  private activeResourceCount(): number {
    return this.resources.filter((resource: StudyResource) => resource.status === StudyResourceStatus.ACTIVE).length;
  }

  private archivedResourceCount(): number {
    return this.resources.filter((resource: StudyResource) => resource.status === StudyResourceStatus.ARCHIVED).length;
  }

  private resourcePreview(content: string): string {
    if (content.length <= 88) {
      return content;
    }
    return `${content.substring(0, 88)}...`;
  }

  private filteredResources(): StudyResource[] {
    return this.resources.filter((resource: StudyResource) => {
      const statusMatched: boolean = this.showArchivedResources ?
        resource.status === StudyResourceStatus.ARCHIVED :
        resource.status === StudyResourceStatus.ACTIVE;
      const projectMatched: boolean = this.resourceFilterProjectId === 0 || resource.projectId === this.resourceFilterProjectId;
      return statusMatched && projectMatched;
    });
  }

  private async addResource(): Promise<void> {
    const title: string = this.newResourceTitle.trim();
    const content: string = this.newResourceContent.trim();
    if (title.length === 0 || content.length === 0) {
      this.resourceMessage = '请补充资料标题和正文摘录';
      return;
    }
    const saved: StudyResource = await focusStore.addStudyResource(title, this.resourceType, this.resourceProjectId, content);
    this.newResourceTitle = '';
    this.newResourceContent = '';
    this.selectedResourceId = saved.id;
    this.syncFromStore();
    this.latestResourceInsight = focusAiCoachService.generateLocalResourceInsight(saved);
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
    const saved: StudyResource = await focusStore.addStudyResource(title, 'file', this.resourceProjectId, content);
    this.newResourceTitle = '';
    this.newResourceContent = '';
    this.pickedFileUri = '';
    this.selectedResourceId = saved.id;
    this.syncFromStore();
    this.latestResourceInsight = focusAiCoachService.generateLocalResourceInsight(saved);
    this.resourceMessage = '文件资料已保存到本地资料库';
  }

  private async extractResource(resourceId: number, useRemote: boolean): Promise<void> {
    if (this.resourceLoading) {
      return;
    }
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      this.resourceMessage = '请先选择一份资料';
      return;
    }
    this.resourceLoading = true;
    try {
      const insight: ResourceInsight = useRemote ?
        await focusAiCoachService.requestResourceInsight(this.aiSettings, resource) :
        focusAiCoachService.generateLocalResourceInsight(resource);
      await focusStore.updateResourceInsight(resource.id, insight);
      this.syncFromStore();
      this.latestResourceInsight = insight;
      this.resourceMessage = useRemote ? insight.source : '已使用本地规则提炼资料';
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
      focusAiCoachService.generateLocalResourceInsight(resource);
    const saved: FocusTask | undefined = await focusStore.createTaskFromResource(resource.id, insight.nextTaskTitle, insight.estimatedMinutes);
    this.syncFromStore();
    if (saved !== undefined) {
      this.selectedTaskId = saved.id;
      this.resourceMessage = '已从资料生成专注任务';
      this.refreshLocalCoachSnapshot();
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
    this.refreshLocalCoachSnapshot();
    this.remainingSeconds = this.settings.shortBreakMinutes * 60;
    this.elapsedSeconds = 0;
    this.serviceMessage = FocusBackgroundService.stopPomodoroGuard();
    FocusNotificationService.publishBasic('番茄完成', `${task.title} 已收获 1 个番茄`);
  }

  private async interruptPomodoro(): Promise<void> {
    const task: FocusTask = this.getSelectedTask();
    const reason: string = this.interruptionReason.trim().length === 0 ? '未填写原因' : this.interruptionReason.trim();
    this.stopTicker();
    this.timerStatus = PomodoroStatus.IDLE;
    await focusStore.recordPomodoro(task.id, Math.max(this.elapsedSeconds, 60), false, reason);
    this.syncFromStore();
    this.refreshLocalCoachSnapshot();
    this.remainingSeconds = this.settings.focusMinutes * 60;
    this.elapsedSeconds = 0;
    this.interruptionReason = '';
    this.showInterruptDialog = false;
    this.serviceMessage = FocusBackgroundService.stopPomodoroGuard();
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

  private todayDoneCount(): number {
    return this.tasks.filter((task: FocusTask) => task.status === TaskStatus.DONE).length;
  }

  private todayTotalCount(): number {
    return this.tasks.filter((task: FocusTask) => task.status !== TaskStatus.DELETED).length;
  }

  private activeTodoCount(): number {
    return this.tasks.filter((task: FocusTask) => task.status === TaskStatus.TODO).length;
  }

  private completedPercent(): number {
    return Math.round(this.todayDoneCount() * 100 / Math.max(1, this.todayTotalCount()));
  }

  private taskTitle(taskId: number): string {
    const task: FocusTask | undefined = this.tasks.find((item: FocusTask) => item.id === taskId);
    return task === undefined ? '未绑定任务' : task.title;
  }

  private focusStateText(): string {
    return formatFocusStateText(this.timerStatus);
  }

  build() {
    if (!this.isAuthed) {
      this.LoginScreen()
    } else {
      Stack() {
        Column() {
          Tabs({ index: this.activeTab, barPosition: BarPosition.End }) {
            TabContent() {
              this.TodayTab()
            }
            .tabBar('今日')

            TabContent() {
              this.TasksTab()
            }
            .tabBar('任务')

            TabContent() {
              this.ResourcesTab()
            }
            .tabBar('资料')

            TabContent() {
              this.FocusTab()
            }
            .tabBar('专注')

            TabContent() {
              this.ReviewTab()
            }
            .tabBar('复盘')
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
        .backgroundColor(PAGE_BG)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          if (typeof newArea.width === 'number') {
            this.viewportWidth = newArea.width;
          }
        })

        if (this.showInterruptDialog) {
          this.InterruptDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  LoginScreen() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 160,
          colors: [[DEEP, 0.0], [DEEP_3, 1.0]]
        })

      Column() {
        Column() {
          Text('知序')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#80FFFFFF')
            .letterSpacing(3)
          Text('让学习资料变成行动')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 12 })
          Text('AI Study Flow · 本地优先 · 离线可用')
            .fontSize(12)
            .fontColor('#B0FFFFFF')
            .margin({ top: 6 })
          Row() {
            Text('RDB 持久化')
              .fontSize(11)
              .fontColor('#D6FFFFFF')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#14FFFFFF')
              .borderRadius(10)
            Text('番茄闭环')
              .fontSize(11)
              .fontColor('#D6FFFFFF')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#14FFFFFF')
              .borderRadius(10)
              .margin({ left: 8 })
            Text('资料提炼')
              .fontSize(11)
              .fontColor('#D6FFFFFF')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#14FFFFFF')
              .borderRadius(10)
              .margin({ left: 8 })
          }
          .margin({ top: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 28 })

        Column() {
          Column() {
          Text('欢迎回来')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('选择本地账户或游客模式，数据都会先保存在端侧。')
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .lineHeight(18)
            .margin({ top: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
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
            .shadow({ radius: 18, color: '#253A7A24', offsetX: 0, offsetY: 8 })
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

          Text('核心数据保存在端侧 RDB / Preferences，后端同步是可选扩展。')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .lineHeight(16)
            .margin({ top: 14 })
        }
        .width('100%')
        .constraintSize({ maxWidth: 440 })
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .border({ width: 1, color: '#26FFFFFF' })
        .shadow({ radius: 34, color: CARD_SHADOW_STRONG, offsetX: 0, offsetY: 16 })
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
      colors: [[DEEP, 0.0], [DEEP_3, 1.0]]
    })
  }

  @Builder
  TodayTab() {
    Scroll() {
      Column() {
        this.TodayHeroCard()
        GridRow({
          columns: { xs: 4, sm: 4, md: 8, lg: 12 },
          gutter: { x: 12, y: 12 }
        }) {
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 5 } }) {
            this.ProgressCard()
          }
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 7 } }) {
            this.QuickAddCard()
          }
        }

        this.NextFocusCard()
        this.AiCoachCard(false)
        this.TodayTaskList()
        this.QuoteCard()
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TodayHeroCard() {
    Column() {
      Row() {
        Column() {
          Text('知序')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.currentNickname.length === 0 ? '本地学习者' : this.currentNickname)
            .fontSize(11)
            .fontColor('#B0FFFFFF')
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          Text('🔥')
            .fontSize(11)
            .margin({ right: 4 })
          Text(`${focusStore.streakDays()}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(' 天')
            .fontSize(10)
            .fontColor('#B0FFFFFF')
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor('#1AFFFFFF')
        .borderRadius(12)
        Button('退出')
          .height(26)
          .fontSize(11)
          .backgroundColor('#1AFFFFFF')
          .fontColor('#CCFFFFFF')
          .borderRadius(12)
          .padding({ left: 10, right: 10 })
          .margin({ left: 6 })
          .onClick(() => {
            this.logout();
          })
      }
      .width('100%')

      Row() {
        Column()
          .width(7)
          .height(7)
          .borderRadius(3.5)
          .backgroundColor(SUCCESS)
          .margin({ right: 7 })
        Text(`${this.currentModeText} · 已保存到本地`)
          .fontSize(11)
          .fontColor('#CCFFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 7, bottom: 7 })
      .backgroundColor('#10FFFFFF')
      .borderRadius(10)
      .margin({ top: 16 })

      Text('今日聚焦')
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#99FFFFFF')
        .letterSpacing(2)
        .margin({ top: 20 })
      Text('拿下最重要的一件事')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 8 })
      Text(this.getSelectedTask().title)
        .fontSize(12)
        .fontColor('#B0FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })

      Image($r('app.media.focus_ai_hero'))
        .width('100%')
        .height(this.viewportWidth > 700 ? 150 : 104)
        .objectFit(ImageFit.Cover)
        .borderRadius(16)
        .margin({ top: 14 })

      Row() {
        Row() {
          Image($r('app.media.focus_ui_local_cube'))
            .microAssetStyle(30)
          Text('本地数据')
            .fontSize(11)
            .fontColor('#E8FFFFFF')
            .margin({ left: 6 })
        }
        .layoutWeight(1)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#14FFFFFF')
        .borderRadius(12)

        Row() {
          Image($r('app.media.focus_ui_ai_orb'))
            .microAssetStyle(30)
          Text('AI 建议')
            .fontSize(11)
            .fontColor('#E8FFFFFF')
            .margin({ left: 6 })
        }
        .layoutWeight(1)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#14FFFFFF')
        .borderRadius(12)
        .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 10 })

      Row() {
        this.DarkHeroStat('完成率', `${this.completedPercent()}%`)
        Column()
          .width(1)
          .height(28)
          .backgroundColor('#1AFFFFFF')
        this.DarkHeroStat('专注 (分)', `${focusStore.totalFocusMinutes()}`)
        Column()
          .width(1)
          .height(28)
          .backgroundColor('#1AFFFFFF')
        this.DarkHeroStat('连续 (天)', `${focusStore.streakDays()}`)
      }
      .width('100%')
      .margin({ top: 18 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .linearGradient({
      angle: 160,
      colors: [[DEEP, 0.0], [DEEP_3, 1.0]]
    })
    .shadow({ radius: 30, color: CARD_SHADOW_STRONG, offsetX: 0, offsetY: 14 })
    .margin({ bottom: 12 })
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
  ProgressCard() {
    Column() {
      Row() {
        Column() {
          Text('今日进度')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('已完成 / 全部')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text(`${this.completedPercent()}%`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(ACCENT)
      }
      .width('100%')
      Stack() {
        Progress({
          value: this.todayDoneCount(),
          total: Math.max(1, this.todayTotalCount()),
          type: ProgressType.Ring
        })
          .width(132)
          .height(132)
          .color(ACCENT)
          .backgroundColor(TRACK)
          .style({ strokeWidth: 10 })
        Column() {
          Text(`${this.todayDoneCount()}/${this.todayTotalCount()}`)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text(`${focusStore.totalFocusMinutes()} 分钟`)
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
      }
      .width('100%')
      .height(150)
      .margin({ top: 8 })

      Row() {
        this.MiniStat('待办', `${this.activeTodoCount()}`, '项')
        Column()
          .width(1)
          .height(28)
          .backgroundColor(BORDER)
        this.MiniStat('完成', `${this.todayDoneCount()}`, '项')
        Column()
          .width(1)
          .height(28)
          .backgroundColor(BORDER)
        this.MiniStat('番茄', `${focusStore.completedPomodoros()}`, '个')
      }
      .width('100%')
      .margin({ top: 4 })
      .alignItems(VerticalAlign.Center)
    }
    .cardStyle()
  }

  @Builder
  MiniStat(label: string, value: string, unit: string) {
    Column() {
      Row() {
        Text(value)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Text(unit)
          .fontSize(10)
          .fontColor(TEXT_MUTED)
          .margin({ left: 2, bottom: 2 })
      }
      .alignItems(VerticalAlign.Bottom)
      Text(label)
        .fontSize(10)
        .fontColor(TEXT_MUTED)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(46)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QuickAddCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_quick_add'))
          .microAssetStyle(44)
          .margin({ right: 10 })
        Column() {
          Text('快速添加任务')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('默认归入「移动开发 / 紧急重要」')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text('本地写入')
          .fontSize(11)
          .fontColor(ACCENT)
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .backgroundColor(ACCENT_SOFT)
          .borderRadius(9)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      TextInput({ placeholder: '例如：整理期末答辩 PPT', text: this.newTaskTitle })
        .height(46)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(14)
        .margin({ top: 14 })
        .onChange((value: string) => {
          this.newTaskTitle = value;
        })
        .onSubmit(() => {
          this.addQuickTask();
        })

      Row() {
        Button('添加任务')
          .height(42)
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ACCENT)
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 14, color: '#253A7A1C', offsetX: 0, offsetY: 6 })
          .onClick(() => {
            this.addQuickTask();
          })
        Button(this.notificationReady ? '通知已开启' : '开启通知')
          .height(42)
          .layoutWeight(1)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(this.notificationReady ? SUCCESS : TEXT_SUB)
          .borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => {
            this.requestNotification();
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Text(this.notificationReady ? '通知已启用，到期与番茄结束会提醒你' : '建议开启通知，避免错过到期时间')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .margin({ top: 10 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
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
  AiCoachCard(compact: boolean) {
    Column() {
      Row() {
        Stack() {
          if (this.isRemoteAdvice()) {
            Image($r('app.media.focus_ui_remote_cloud'))
              .width(compact ? 56 : 72)
              .height(compact ? 56 : 72)
              .objectFit(ImageFit.Cover)
              .borderRadius(compact ? 16 : 20)
          } else {
            Image($r('app.media.focus_ui_ai_orb'))
              .width(compact ? 56 : 72)
              .height(compact ? 56 : 72)
              .objectFit(ImageFit.Cover)
              .borderRadius(compact ? 16 : 20)
          }
          Text('AI')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .backgroundColor('#660E1626')
            .borderRadius(8)
        }
        .margin({ right: 14 })

        Column() {
          Row() {
            Text('AI Study Coach')
              .fontSize(compact ? 14 : 16)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
            Blank()
            Text(this.adviceSourceLabel())
              .fontSize(10)
              .fontColor(this.isRemoteAdvice() ? VIOLET : TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.isRemoteAdvice() ? VIOLET_SOFT : SURFACE_ALT)
              .borderRadius(8)
          }
          .width('100%')
          Text(this.aiAdvice.headline)
            .fontSize(compact ? 13 : 15)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MAIN)
            .lineHeight(compact ? 19 : 22)
            .maxLines(compact ? 2 : 3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
          Text(this.aiAdvice.nextAction)
            .fontSize(12)
            .fontColor(TEXT_SUB)
            .lineHeight(18)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row() {
        this.AiCoachMetric('安排', this.aiAdvice.sessionPlan, 'timer')
        Column()
          .width(1)
          .height(38)
          .backgroundColor(BORDER_SOFT)
          .margin({ left: 10, right: 10 })
        this.AiCoachMetric('置信', `${this.aiAdvice.confidence}%`, 'shield')
      }
      .width('100%')
      .margin({ top: 14 })

      Text(this.aiAdvice.risk)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .maxLines(compact ? 2 : 3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding(12)
        .backgroundColor(SURFACE_ALT)
        .borderRadius(12)
        .width('100%')
        .margin({ top: 12 })

      Row() {
        Button(this.aiLoading ? '生成中' : '本地重算')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .onClick(() => {
            this.refreshAiCoach(false);
          })
        Button(this.aiLoading ? '请求中' : '远程 AI')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.aiSettings.enabled && this.aiSettings.apiKey.length > 0 ? ACCENT : ACCENT_SOFT)
          .fontColor(this.aiSettings.enabled && this.aiSettings.apiKey.length > 0 ? '#FFFFFF' : ACCENT)
          .borderRadius(10)
          .margin({ left: 10 })
          .onClick(() => {
            this.refreshAiCoach(true);
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  AiCoachMetric(label: string, value: string, icon: string) {
    Row() {
      this.SmallUiAsset(icon, 28)
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
  TodayTaskList() {
    Column() {
      Row() {
        Column() {
          Text('今日待办')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('按优先级与截止时间排序')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text(`${focusStore.getTodayTasks().length} 项`)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (focusStore.getTodayTasks().length === 0) {
        this.EmptyState('今天没有待办', '可以先添加一个 25 分钟内能完成的小任务。', 'inbox')
      } else {
        ForEach(focusStore.getTodayTasks(), (task: FocusTask) => {
          this.TaskRow(task, true)
        }, (task: FocusTask) => task.id.toString())
      }
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  EmptyState(title: string, caption: string, variant: string) {
    Column() {
      this.SmallUiAsset(variant, 76)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .margin({ top: 8 })
      Text(caption)
        .fontSize(12)
        .fontColor(TEXT_MUTED)
        .margin({ top: 6 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 26, bottom: 26, left: 18, right: 18 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(SURFACE_ALT)
    .borderRadius(12)
  }

  @Builder
  SmallUiAsset(variant: string, size: number) {
    if (variant === 'inbox') {
      Image($r('app.media.focus_ui_empty_inbox'))
        .microAssetStyle(size)
    } else if (variant === 'quick') {
      Image($r('app.media.focus_ui_quick_add'))
        .microAssetStyle(size)
    } else if (variant === 'marker') {
      Image($r('app.media.focus_ui_next_marker'))
        .microAssetStyle(size)
    } else if (variant === 'priority') {
      Image($r('app.media.focus_ui_priority_flag'))
        .microAssetStyle(size)
    } else if (variant === 'ai') {
      Image($r('app.media.focus_ui_ai_orb'))
        .microAssetStyle(size)
    } else if (variant === 'local') {
      Image($r('app.media.focus_ui_local_cube'))
        .microAssetStyle(size)
    } else if (variant === 'remote') {
      Image($r('app.media.focus_ui_remote_cloud'))
        .microAssetStyle(size)
    } else if (variant === 'timer') {
      Image($r('app.media.focus_ui_timer_token'))
        .microAssetStyle(size)
    } else if (variant === 'pause') {
      Image($r('app.media.focus_ui_pause_resume'))
        .microAssetStyle(size)
    } else if (variant === 'bell') {
      Image($r('app.media.focus_ui_notification_bell'))
        .microAssetStyle(size)
    } else if (variant === 'medal') {
      Image($r('app.media.focus_ui_completion_medal'))
        .microAssetStyle(size)
    } else if (variant === 'shield') {
      Image($r('app.media.focus_ui_risk_shield'))
        .microAssetStyle(size)
    } else if (variant === 'bars') {
      Image($r('app.media.focus_ui_review_bars'))
        .microAssetStyle(size)
    } else if (variant === 'heatmap') {
      Image($r('app.media.focus_ui_heatmap_grid'))
        .microAssetStyle(size)
    } else if (variant === 'settings') {
      Image($r('app.media.focus_ui_settings_sliders'))
        .microAssetStyle(size)
    } else if (variant === 'sync') {
      Image($r('app.media.focus_ui_sync_bridge'))
        .microAssetStyle(size)
    } else {
      Image($r('app.media.focus_ui_empty_inbox'))
        .microAssetStyle(size)
    }
  }

  @Builder
  QuoteCard() {
    Column() {
      Text('今日金句')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .letterSpacing(1)
      Text('把注意力还给最重要的一件事。')
        .fontSize(14)
        .fontColor(TEXT_SUB)
        .lineHeight(22)
        .margin({ top: 6 })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(CARD_BG)
    .borderRadius(16)
    .border({ width: { left: 3 }, color: { left: ACCENT_SOFT } })
    .margin({ top: 12 })
    .shadow({ radius: 22, color: '#0D0F1A34', offsetX: 0, offsetY: 10 })
  }

  @Builder
  TasksTab() {
    Scroll() {
      Column() {
        this.FilterBar()
        Column() {
          Row() {
            Column() {
              Text(this.showRecycle ? '回收站' : '任务管理')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(TEXT_MAIN)
              Text(this.showRecycle ? '已删除的任务在这里' : '管理所有项目下的任务')
                .fontSize(11)
                .fontColor(TEXT_MUTED)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(`${this.filteredTasks().length} 项`)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
              .margin({ right: 10 })
            Button(this.showRecycle ? '返回' : '回收站')
              .height(32)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(SURFACE_ALT)
              .fontColor(TEXT_SUB)
              .borderRadius(10)
              .padding({ left: 14, right: 14 })
              .onClick(() => {
                this.showRecycle = !this.showRecycle;
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.filteredTasks().length === 0) {
            this.EmptyState(this.showRecycle ? '回收站是空的' : '没有匹配的任务', '换一个筛选条件，或回到今日页快速添加。', this.showRecycle ? 'medal' : 'inbox')
          } else {
            ForEach(this.filteredTasks(), (task: FocusTask) => {
              this.TaskRow(task, false)
            }, (task: FocusTask) => task.id.toString())
          }
        }
        .cardStyle()
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 12 })
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FilterBar() {
    Column() {
      TextInput({ placeholder: '搜索任务、备注或标签', text: this.searchText })
        .height(44)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .fontSize(14)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.searchText = value;
        })

      Text('项目')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 14, bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        Text('全部')
          .height(30)
          .fontSize(12)
          .fontWeight(this.filterProjectId === 0 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.filterProjectId === 0 ? '#FFFFFF' : TEXT_SUB)
          .backgroundColor(this.filterProjectId === 0 ? ACCENT : SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .margin({ right: 6, bottom: 6 })
          .onClick(() => {
            this.filterProjectId = 0;
          })
        ForEach(focusStore.projects, (project: FocusProject) => {
          Text(project.name)
            .height(30)
            .fontSize(12)
            .fontWeight(this.filterProjectId === project.id ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.filterProjectId === project.id ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.filterProjectId === project.id ? project.color : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.filterProjectId = this.filterProjectId === project.id ? 0 : project.id;
            })
        }, (project: FocusProject) => project.id.toString())
      }
      .width('100%')

      Text('象限')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12, bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        Text('全部')
          .height(30)
          .fontSize(12)
          .fontWeight(this.filterPriority < 0 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.filterPriority < 0 ? '#FFFFFF' : TEXT_SUB)
          .backgroundColor(this.filterPriority < 0 ? TEXT_MAIN : SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .margin({ right: 6, bottom: 6 })
          .onClick(() => {
            this.filterPriority = -1;
          })
        ForEach([0, 1, 2, 3], (priority: number) => {
          Text(this.priorityName(priority))
            .height(30)
            .fontSize(12)
            .fontWeight(this.filterPriority === priority ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.filterPriority === priority ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.filterPriority === priority ? this.priorityColor(priority) : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.filterPriority = this.filterPriority === priority ? -1 : priority;
            })
        }, (priority: number) => priority.toString())
      }
      .width('100%')
    }
    .cardStyle()
  }

  @Builder
  TaskRow(task: FocusTask, allowFocusJump: boolean) {
    Column() {
      Row() {
        Stack() {
          Column()
            .width(20)
            .height(20)
            .borderRadius(10)
            .backgroundColor(task.status === TaskStatus.DONE ? SUCCESS : Color.Transparent)
            .border({ width: task.status === TaskStatus.DONE ? 0 : 1.5, color: BORDER })
          if (task.status === TaskStatus.DONE) {
            Text('✓')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
        }
        .margin({ right: 10 })
        .onClick(() => {
          this.toggleTask(task.id);
        })

        Column() {
          this.SmallUiAsset(task.status === TaskStatus.DONE ? 'medal' : 'priority', 38)
        }
        .width(38)
        .height(38)
        .margin({ right: 10 })

        Column() {
          Row() {
            Text(task.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(task.status === TaskStatus.DONE ? TEXT_MUTED : TEXT_MAIN)
              .decoration({ type: task.status === TaskStatus.DONE ? TextDecorationType.LineThrough : TextDecorationType.None })
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.dueText(task.dueAt))
              .fontSize(11)
              .fontColor(this.dueText(task.dueAt) === '已到期' ? DANGER : TEXT_MUTED)
              .backgroundColor(this.dueText(task.dueAt) === '已到期' ? DANGER_SOFT : SURFACE_ALT)
              .borderRadius(8)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .margin({ left: 8 })
          }
          .width('100%')

          Row() {
            this.ProjectPill(task.projectId)
            Text('·')
              .fontSize(10)
              .fontColor(TEXT_DIM)
              .margin({ left: 8, right: 8 })
            Text(this.priorityName(task.priority))
              .fontSize(11)
              .fontColor(this.priorityColor(task.priority))
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor(task.status === TaskStatus.DONE ? SURFACE_ALT : this.priorityTint(task.priority))
              .borderRadius(7)
            Text('·')
              .fontSize(10)
              .fontColor(TEXT_DIM)
              .margin({ left: 8, right: 8 })
            Text(`${task.pomodoroCount} 番茄`)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
          }
          .width('100%')
          .margin({ top: 4 })

          if (!allowFocusJump && task.note.length > 0) {
            Text(task.note)
              .fontSize(12)
              .fontColor(TEXT_SUB)
              .lineHeight(18)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 6 })
          }
          if (!allowFocusJump && task.subtasks.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(task.subtasks, (item: string) => {
                Text(item)
                  .fontSize(11)
                  .fontColor(TEXT_SUB)
                  .backgroundColor(SURFACE_ALT)
                  .borderRadius(8)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .margin({ right: 6, top: 4 })
              }, (item: string) => item)
            }
            .margin({ top: 2 })
          }

          Row() {
            if (task.status === TaskStatus.DELETED) {
              Button('恢复任务')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(SUCCESS_SOFT)
                .fontColor(SUCCESS)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onClick(() => {
                  this.restoreTask(task.id);
                })
            } else {
              Button(allowFocusJump ? '进入专注' : '开始番茄')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(ACCENT)
                .fontColor('#FFFFFF')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .shadow({ radius: 10, color: '#253A7A18', offsetX: 0, offsetY: 4 })
                .onClick(() => {
                  this.selectTask(task.id);
                })
              Button('删除')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(Color.Transparent)
                .fontColor(TEXT_MUTED)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 4 })
                .onClick(() => {
                  this.deleteTask(task.id);
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding({ left: 13, right: 10, top: 12, bottom: 12 })
    .backgroundColor(task.status === TaskStatus.DONE ? CARD_SOFT : '#FFFFFF')
    .borderRadius(14)
    .border({
      width: { left: 3 },
      color: { left: task.status === TaskStatus.DONE ? TEXT_DIM : this.priorityColor(task.priority) }
    })
    .margin({ bottom: 8 })
    .animation({ duration: 180, curve: Curve.EaseOut })
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
  ResourcesTab() {
    Scroll() {
      Column() {
        this.ResourceHeroCard()
        this.ResourceWorkspaceTabs()
        if (this.resourceWorkspace === 'memo') {
          this.ResourceQuickAddCard()
        } else if (this.resourceWorkspace === 'upload') {
          this.ResourceImportCard()
        } else if (this.resourceWorkspace === 'insight') {
          GridRow({
            columns: { xs: 4, sm: 4, md: 8, lg: 12 },
            gutter: { x: 12, y: 12 }
          }) {
            GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 7 } }) {
              this.ResourceAiCard()
            }
            GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 5 } }) {
              this.ResourceList()
            }
          }
        } else {
          this.ResourceFilterBar()
          this.ResourceList()
        }
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ResourceHeroCard() {
    Column() {
      Row() {
        Column() {
          Text('学习资料库')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(`${this.resourceWorkspaceName(this.resourceWorkspace)} · 自定义学习素材`)
            .fontSize(11)
            .fontColor('#B0FFFFFF')
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.focus_ui_sync_bridge'))
          .width(70)
          .height(70)
          .objectFit(ImageFit.Cover)
          .borderRadius(18)
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('把备忘录、链接、课件和本地文件拆成几个可进入的工作区')
        .fontSize(13)
        .fontColor('#D8FFFFFF')
        .lineHeight(20)
        .margin({ top: 12 })

      Row() {
        this.DarkHeroStat('活跃资料', `${this.activeResourceCount()}`)
        Column()
          .width(1)
          .height(28)
          .backgroundColor('#1AFFFFFF')
        this.DarkHeroStat('已提炼', `${focusStore.extractedResourceCount()}`)
        Column()
          .width(1)
          .height(28)
          .backgroundColor('#1AFFFFFF')
        this.DarkHeroStat('已归档', `${this.archivedResourceCount()}`)
      }
      .width('100%')
      .margin({ top: 18 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .linearGradient({
      angle: 160,
      colors: [[DEEP_2, 0.0], [DEEP_4, 1.0]]
    })
    .shadow({ radius: 30, color: CARD_SHADOW_STRONG, offsetX: 0, offsetY: 14 })
    .margin({ bottom: 12 })
  }

  @Builder
  ResourceWorkspaceTabs() {
    Row() {
      this.ResourceWorkspaceTab('library', '资料库', '查看')
      this.ResourceWorkspaceTab('memo', '备忘录', '写入')
      this.ResourceWorkspaceTab('upload', '文件', '导入')
      this.ResourceWorkspaceTab('insight', '提炼', 'AI')
    }
    .width('100%')
    .padding(5)
    .backgroundColor('#CCFFFFFF')
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
    .border({ width: 1, color: '#80FFFFFF' })
    .borderRadius(16)
    .shadow({ radius: 18, color: CARD_SHADOW, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 12 })
  }

  @Builder
  ResourceWorkspaceTab(mode: string, title: string, caption: string) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontWeight(this.resourceWorkspace === mode ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.resourceWorkspace === mode ? '#FFFFFF' : TEXT_SUB)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(caption)
        .fontSize(9)
        .fontColor(this.resourceWorkspace === mode ? '#CCFFFFFF' : TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.resourceWorkspace === mode ? ACCENT : Color.Transparent)
    .borderRadius(12)
    .onClick(() => {
      this.switchResourceWorkspace(mode);
    })
  }

  @Builder
  ResourceQuickAddCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_quick_add'))
          .microAssetStyle(44)
          .margin({ right: 10 })
        Column() {
          Text(this.resourceWorkspace === 'memo' ? '写一条备忘录' : '新增资料')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text(this.resourceWorkspace === 'memo' ? '把资料库当作课程备忘录使用' : '粘贴课堂笔记、论文摘录或链接说明')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      TextInput({ placeholder: '资料标题，例如：操作系统进程调度笔记', text: this.newResourceTitle })
        .height(42)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 14 })
        .onChange((value: string) => {
          this.newResourceTitle = value;
        })

      TextInput({ placeholder: this.resourceWorkspace === 'memo' ? '今天想到的知识点、待查问题、复习提醒...' : '正文摘录 / 链接说明 / 复习材料要点', text: this.newResourceContent })
        .height(this.resourceWorkspace === 'memo' ? 112 : 76)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.newResourceContent = value;
        })

      Text('类型')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12, bottom: 8 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(['note', 'link', 'courseware', 'pdf'], (type: string) => {
          Text(this.resourceTypeName(type))
            .height(30)
            .fontSize(12)
            .fontWeight(this.resourceType === type ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.resourceType === type ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.resourceType === type ? ACCENT : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.resourceType = type;
            })
        }, (type: string) => type)
      }
      .width('100%')

      Text('项目')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 8, bottom: 8 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(focusStore.projects, (project: FocusProject) => {
          Text(project.name)
            .height(30)
            .fontSize(12)
            .fontWeight(this.resourceProjectId === project.id ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.resourceProjectId === project.id ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.resourceProjectId === project.id ? project.color : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.resourceProjectId = project.id;
            })
        }, (project: FocusProject) => project.id.toString())
      }
      .width('100%')

      Button(this.resourceWorkspace === 'memo' ? '保存备忘录' : '保存到资料库')
        .height(40)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(ACCENT)
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 14, color: '#253A7A1C', offsetX: 0, offsetY: 6 })
        .margin({ top: 8 })
        .onClick(() => {
          this.addResource();
        })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ResourceImportCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_sync_bridge'))
          .microAssetStyle(44)
          .margin({ right: 10 })
        Column() {
          Text('导入本地文件')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('选择文档后保存文件引用和自己的备注')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Column() {
        Text(this.pickedFileName())
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.pickedFileUri.length > 0 ? TEXT_MAIN : TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.pickedFilePreview())
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
      }
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_SOFT)
      .border({ width: 1, color: BORDER_SOFT })
      .borderRadius(14)
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 14 })

      Row() {
        Button('选择文件')
          .height(38)
          .layoutWeight(1)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ACCENT)
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => {
            this.pickResourceFile();
          })
        Button('清空')
          .height(38)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(12)
          .padding({ left: 14, right: 14 })
          .margin({ left: 8 })
          .onClick(() => {
            this.pickedFileUri = '';
            this.resourceMessage = '已清空待导入文件';
          })
      }
      .width('100%')
      .margin({ top: 12 })

      TextInput({ placeholder: '资料标题，可用文件名或课程主题', text: this.newResourceTitle })
        .height(42)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.newResourceTitle = value;
        })

      TextInput({ placeholder: '补充备注：文件用途、章节、要复习的问题', text: this.newResourceContent })
        .height(84)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.newResourceContent = value;
        })

      Text('归属项目')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12, bottom: 8 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(focusStore.projects, (project: FocusProject) => {
          Text(project.name)
            .height(30)
            .fontSize(12)
            .fontWeight(this.resourceProjectId === project.id ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.resourceProjectId === project.id ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.resourceProjectId === project.id ? project.color : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.resourceProjectId = project.id;
            })
        }, (project: FocusProject) => project.id.toString())
      }
      .width('100%')

      Button('保存文件资料')
        .height(40)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.pickedFileUri.length > 0 ? SUCCESS : SURFACE_ALT)
        .fontColor(this.pickedFileUri.length > 0 ? '#FFFFFF' : TEXT_MUTED)
        .borderRadius(12)
        .margin({ top: 8 })
        .onClick(() => {
          this.savePickedFileResource();
        })

      Text(this.resourceMessage)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 10 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ResourceAiCard() {
    Column() {
      Row() {
        Stack() {
          Image($r('app.media.focus_ui_ai_orb'))
            .width(66)
            .height(66)
            .objectFit(ImageFit.Cover)
            .borderRadius(18)
          Text('AI')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .backgroundColor('#660E1626')
            .borderRadius(8)
        }
        .margin({ right: 12 })
        Column() {
          Row() {
            Text('资料提炼')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
            Blank()
            Text(this.resourceInsightSourceLabel())
              .fontSize(10)
              .fontColor(this.latestResourceInsight.source === '远程 AI' ? VIOLET : TEXT_MUTED)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.latestResourceInsight.source === '远程 AI' ? VIOLET_SOFT : SURFACE_ALT)
              .borderRadius(8)
          }
          .width('100%')
          Text(this.selectedResourceTitle())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MAIN)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.selectedResourceSummary())
        .fontSize(12)
        .fontColor(TEXT_SUB)
        .lineHeight(18)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding(12)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .width('100%')
        .margin({ top: 14 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.selectedResourceKeyPoints(), (point: string) => {
          Text(point)
            .fontSize(11)
            .fontColor(TEXT_SUB)
            .backgroundColor(SURFACE_ALT)
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .margin({ right: 6, top: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }, (point: string) => point)
      }
      .width('100%')
      .margin({ top: 6 })

      Row() {
        this.AiCoachMetric('建议任务', this.latestResourceInsight.nextTaskTitle, 'marker')
        Column()
          .width(1)
          .height(38)
          .backgroundColor(BORDER_SOFT)
          .margin({ left: 10, right: 10 })
        this.AiCoachMetric('预计', `${this.latestResourceInsight.estimatedMinutes} 分钟`, 'timer')
      }
      .width('100%')
      .margin({ top: 14 })

      Row() {
        Button(this.resourceLoading ? '提炼中' : '本地提炼')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .onClick(() => {
            this.extractResource(this.selectedResourceId, false);
          })
        Button(this.resourceLoading ? '请求中' : '远程 AI')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.aiSettings.enabled && this.aiSettings.apiKey.length > 0 ? ACCENT : ACCENT_SOFT)
          .fontColor(this.aiSettings.enabled && this.aiSettings.apiKey.length > 0 ? '#FFFFFF' : ACCENT)
          .borderRadius(10)
          .margin({ left: 8 })
          .onClick(() => {
            this.extractResource(this.selectedResourceId, true);
          })
        Button('生成任务')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(SUCCESS_SOFT)
          .fontColor(SUCCESS)
          .borderRadius(10)
          .margin({ left: 8 })
          .onClick(() => {
            this.createTaskFromResource(this.selectedResourceId);
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Text(this.resourceMessage)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 10 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ResourceFilterBar() {
    Column() {
      Row() {
        Text(this.showArchivedResources ? '归档资料' : '活跃资料')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Button(this.showArchivedResources ? '看活跃' : '看归档')
          .height(30)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.showArchivedResources = !this.showArchivedResources;
          })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        Text('全部项目')
          .height(30)
          .fontSize(12)
          .fontWeight(this.resourceFilterProjectId === 0 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.resourceFilterProjectId === 0 ? '#FFFFFF' : TEXT_SUB)
          .backgroundColor(this.resourceFilterProjectId === 0 ? TEXT_MAIN : SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .margin({ right: 6, top: 10 })
          .onClick(() => {
            this.resourceFilterProjectId = 0;
          })
        ForEach(focusStore.projects, (project: FocusProject) => {
          Text(project.name)
            .height(30)
            .fontSize(12)
            .fontWeight(this.resourceFilterProjectId === project.id ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.resourceFilterProjectId === project.id ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.resourceFilterProjectId === project.id ? project.color : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, top: 10 })
            .onClick(() => {
              this.resourceFilterProjectId = this.resourceFilterProjectId === project.id ? 0 : project.id;
            })
        }, (project: FocusProject) => project.id.toString())
      }
      .width('100%')
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  ResourceList() {
    Column() {
      Row() {
        Text('资料清单')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text(`${this.filteredResources().length} 项`)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.filteredResources().length === 0) {
        this.EmptyState(this.showArchivedResources ? '暂无归档资料' : '暂无匹配资料', '添加一段课堂笔记或切换筛选条件。', 'inbox')
      } else {
        ForEach(this.filteredResources(), (resource: StudyResource) => {
          this.ResourceCard(resource)
        }, (resource: StudyResource) => resource.id.toString())
      }
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  ResourceCard(resource: StudyResource) {
    Column() {
      Row() {
        Column() {
          this.SmallUiAsset(resource.sourceType === 'pdf' || resource.sourceType === 'file' ? 'bars' : resource.sourceType === 'link' ? 'sync' : 'local', 42)
        }
        .width(42)
        .height(42)
        .margin({ right: 10 })

        Column() {
          Row() {
            Text(resource.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(resource.status === StudyResourceStatus.ARCHIVED ? TEXT_MUTED : TEXT_MAIN)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.resourceTypeName(resource.sourceType))
              .fontSize(10)
              .fontColor(TEXT_MUTED)
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor(SURFACE_ALT)
              .borderRadius(7)
              .margin({ left: 8 })
          }
          .width('100%')

          Row() {
            this.ProjectPill(resource.projectId)
            Text('·')
              .fontSize(10)
              .fontColor(TEXT_DIM)
              .margin({ left: 8, right: 8 })
            Text(resource.linkedTaskId > 0 ? `已生成：${this.taskTitle(resource.linkedTaskId)}` : '未生成任务')
              .fontSize(11)
              .fontColor(resource.linkedTaskId > 0 ? SUCCESS : TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .margin({ top: 5 })

          Text(resource.summary.length > 0 ? resource.summary : this.resourcePreview(resource.content))
            .fontSize(12)
            .fontColor(TEXT_SUB)
            .lineHeight(18)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 7 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(resource.keyPoints.slice(0, 3), (point: string) => {
              Text(point)
                .fontSize(10)
                .fontColor(TEXT_MUTED)
                .backgroundColor(CARD_SOFT)
                .borderRadius(7)
                .padding({ left: 7, right: 7, top: 3, bottom: 3 })
                .margin({ right: 5, top: 5 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }, (point: string) => point)
          }
          .width('100%')

          Row() {
            Button(this.selectedResourceId === resource.id ? '已选择' : '选择')
              .height(28)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.selectedResourceId === resource.id ? ACCENT : SURFACE_ALT)
              .fontColor(this.selectedResourceId === resource.id ? '#FFFFFF' : TEXT_SUB)
              .borderRadius(8)
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                this.selectResource(resource.id);
              })
            if (resource.status === StudyResourceStatus.ARCHIVED) {
              Button('恢复')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(SUCCESS_SOFT)
                .fontColor(SUCCESS)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 5 })
                .onClick(() => {
                  this.restoreResource(resource.id);
                })
            } else {
              Button('提炼')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(ACCENT_SOFT)
                .fontColor(ACCENT)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 5 })
                .onClick(() => {
                  this.selectResource(resource.id);
                  this.extractResource(resource.id, false);
                })
              Button('归档')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(Color.Transparent)
                .fontColor(TEXT_MUTED)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 5 })
                .onClick(() => {
                  this.archiveResource(resource.id);
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding({ left: 13, right: 10, top: 12, bottom: 12 })
    .backgroundColor(this.selectedResourceId === resource.id ? ACCENT_SOFT : '#FFFFFF')
    .borderRadius(14)
    .border({
      width: { left: 3 },
      color: { left: resource.status === StudyResourceStatus.ARCHIVED ? TEXT_DIM : focusStore.getProject(resource.projectId).color }
    })
    .margin({ bottom: 8 })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  FocusTab() {
    Scroll() {
      Column() {
        GridRow({
          columns: { xs: 4, sm: 4, md: 8, lg: 12 },
          gutter: { x: 12, y: 12 }
        }) {
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 5 } }) {
            this.TimerCard()
          }
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 7 } }) {
            this.FocusSidePanel()
          }
        }
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TimerCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_timer_token'))
          .width(44)
          .height(44)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ right: 10 })
        Column() {
          Text('专注模式')
            .fontSize(11)
            .fontColor('#99FFFFFF')
            .letterSpacing(2)
          Text(this.getSelectedTask().title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.focusStateText())
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#1AFFFFFF')
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack() {
        Progress({ value: this.timerProgress(), total: 100, type: ProgressType.Ring })
          .width(218)
          .height(218)
          .color(ACCENT)
          .backgroundColor('#22FFFFFF')
          .style({ strokeWidth: 9 })
        Column() {
          Text(this.timeText(this.remainingSeconds))
            .fontSize(52)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(`${this.settings.focusMinutes} / ${this.settings.shortBreakMinutes} 分钟节奏`)
            .fontSize(11)
            .fontColor('#B0FFFFFF')
            .margin({ top: 6 })
        }
      }
      .height(230)
      .width('100%')
      .margin({ top: 16 })

      Text('完成和中断都会写入本地记录，用于复盘统计。')
        .fontSize(11)
        .fontColor('#CCFFFFFF')
        .lineHeight(16)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#10FFFFFF')
        .borderRadius(10)
        .width('100%')
        .margin({ top: 4 })

      Row() {
        Row() {
          Image($r('app.media.focus_ui_pause_resume'))
            .width(26)
            .height(26)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ right: 6 })
          Text(this.timerStatus === PomodoroStatus.RUNNING ? '运行中' : '待开始')
            .fontSize(11)
            .fontColor('#E6FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('#14FFFFFF')
        .borderRadius(12)

        Row() {
          Image($r('app.media.focus_ui_risk_shield'))
            .width(26)
            .height(26)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ right: 6 })
          Text(`${focusStore.interruptedPomodoros()} 次中断`)
            .fontSize(11)
            .fontColor('#E6FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('#14FFFFFF')
        .borderRadius(12)
        .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Button(this.timerStatus === PomodoroStatus.RUNNING ? '暂停' : '开始')
          .height(46)
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.timerStatus === PomodoroStatus.RUNNING ? '#26FFFFFF' : ACCENT)
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => {
            if (this.timerStatus === PomodoroStatus.RUNNING) {
              this.pausePomodoro();
            } else {
              this.startPomodoro();
            }
          })
        Button('完成')
          .height(46)
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#22FFFFFF')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => {
            this.completePomodoro();
          })
      }
      .width('100%')
      .margin({ top: 16 })

      Row() {
        Button('中断')
          .height(38)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#14FFFFFF')
          .fontColor('#CCFFFFFF')
          .borderRadius(10)
          .onClick(() => {
            this.showInterruptDialog = true;
          })
        Button('重置')
          .height(38)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#14FFFFFF')
          .fontColor('#CCFFFFFF')
          .borderRadius(10)
          .margin({ left: 10 })
          .onClick(() => {
            this.resetPomodoro();
          })
      }
      .width('100%')
      .margin({ top: 10 })

      Text(this.serviceMessage)
        .fontSize(11)
        .fontColor(FAINT_ON_DARK)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 14 })
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .linearGradient({
      angle: 160,
      colors: [[DEEP, 0.0], [DEEP_3, 1.0]]
    })
    .shadow({ radius: 30, color: CARD_SHADOW_STRONG, offsetX: 0, offsetY: 14 })
  }

  @Builder
  FocusSidePanel() {
    Column() {
      this.AiCoachCard(true)
      this.AiSettingsCard()
      this.SettingsCard()
      this.WhiteNoiseCard()
      this.HistoryCard()
    }
    .width('100%')
  }

  @Builder
  AiSettingsCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_settings_sliders'))
          .microAssetStyle(42)
          .margin({ right: 10 })
        Column() {
          Text('AI 接入')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('本地建议始终可用，远程模型按需启用')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.aiSettings.enabled ? '远程开' : '本地')
          .fontSize(11)
          .fontColor(this.aiSettings.enabled ? VIOLET : TEXT_MUTED)
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .backgroundColor(this.aiSettings.enabled ? VIOLET_SOFT : SURFACE_ALT)
          .borderRadius(9)
          .onClick(() => {
            this.toggleRemoteAi();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      TextInput({ placeholder: 'https://api.openai.com/v1', text: this.aiEndpointInput })
        .height(40)
        .backgroundColor(CARD_SOFT)
        .borderRadius(10)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 12, right: 12 })
        .fontSize(12)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.aiEndpointInput = value;
        })

      TextInput({ placeholder: 'gpt-4o-mini', text: this.aiModelInput })
        .height(40)
        .backgroundColor(CARD_SOFT)
        .borderRadius(10)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 12, right: 12 })
        .fontSize(12)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.aiModelInput = value;
        })

      TextInput({ placeholder: `API Key：${this.maskedAiKey()}，留空保留`, text: this.aiApiKeyInput })
        .height(40)
        .backgroundColor(CARD_SOFT)
        .borderRadius(10)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 12, right: 12 })
        .fontSize(12)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.aiApiKeyInput = value;
        })

      Row() {
        Button('保存配置')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ACCENT)
          .fontColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => {
            this.saveAiSettings();
          })
        Button('切换模式')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .margin({ left: 10 })
          .onClick(() => {
            this.toggleRemoteAi();
          })
      }
      .width('100%')
      .margin({ top: 10 })

      Text(this.aiSettingsMessage)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 10 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  SettingsCard() {
    Column() {
      Text('时长设置')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .alignSelf(ItemAlign.Start)
      Text('拖动调整每段时长')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 2 })

      this.SettingSlider('专注', this.settings.focusMinutes, 10, 60)
      this.SettingSlider('短休', this.settings.shortBreakMinutes, 3, 15)
      this.SettingSlider('长休', this.settings.longBreakMinutes, 10, 30)
      Text(this.focusSettingsMessage)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 12 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  SettingSlider(label: string, value: number, min: number, max: number) {
    Column() {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor(TEXT_SUB)
        Blank()
        Text(`${value} 分钟`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_MAIN)
      }
      .width('100%')
      Slider({ value: value, min: min, max: max, step: 1 })
        .blockColor(ACCENT)
        .selectedColor(ACCENT)
        .trackColor(TRACK)
        .onChange((changedValue: number) => {
          this.updateDurationSetting(label, Math.round(changedValue));
        })
    }
    .width('100%')
    .margin({ top: 14 })
  }

  @Builder
  WhiteNoiseCard() {
    Column() {
      Text('白噪音')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .alignSelf(ItemAlign.Start)
      Text('点击切换背景音环境')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 2 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(['雨声', '咖啡馆', '键盘', '白噪声'], (noise: string) => {
          Text(noise)
            .height(32)
            .fontSize(12)
            .fontWeight(this.settings.noise === noise ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.settings.noise === noise ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.settings.noise === noise ? ACCENT : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 14, right: 14 })
            .margin({ right: 8, top: 12 })
            .onClick(() => {
              this.updateNoiseSetting(noise);
            })
        }, (noise: string) => noise)
      }
      .width('100%')
      Text('AVPlayer 集成入口已预留，演示时可解释为本地 rawfile 音频播放。')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 12 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  HistoryCard() {
    Column() {
      Text('番茄历史')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .alignSelf(ItemAlign.Start)
      Text('最近 5 次专注记录')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 2, bottom: 6 })

      ForEach(this.records.slice(0, 5), (record: PomodoroRecord) => {
        Row() {
          Column()
            .width(3)
            .height(20)
            .borderRadius(2)
            .backgroundColor(record.completed === 1 ? SUCCESS : DANGER)
            .margin({ right: 12 })
          Column() {
            Text(this.taskTitle(record.taskId))
              .fontSize(13)
              .fontColor(TEXT_MAIN)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(record.completed === 1 ? '已完成' : '中断')
              .fontSize(10)
              .fontColor(record.completed === 1 ? SUCCESS : DANGER)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`${Math.round(record.duration / 60)} 分`)
            .fontSize(12)
            .fontColor(TEXT_SUB)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .border({ width: { bottom: 1 }, color: BORDER_SOFT })
      }, (record: PomodoroRecord) => record.id.toString())
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  ReviewTab() {
    Scroll() {
      Column() {
        GridRow({
          columns: { xs: 4, sm: 4, md: 8, lg: 12 },
          gutter: { x: 10, y: 10 }
        }) {
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
            this.KpiCard('总专注', `${focusStore.totalFocusMinutes()}`, '分钟', 'timer')
          }
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
            this.KpiCard('完成率', `${Math.round(focusStore.completedPomodoros() * 100 / Math.max(1, this.records.length))}`, '%', 'medal')
          }
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
            this.KpiCard('最长 streak', `${focusStore.bestStreakDays()}`, '天', 'heatmap')
          }
        }

        this.WebReviewCard()
        this.BarChartCard('本周学习时长', focusStore.weekFocusPoints(), 'bars')
        this.BarChartCard('项目时间占比', focusStore.projectFocusPoints(), 'sync')
        this.CompletionCard()
        this.HeatMapCard()
        this.ForestCard()
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WebReviewCard() {
    Column() {
      Row() {
        Column() {
          Text('ArkWeb 混合复盘')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('H5 图表 × ArkTS 数据桥接')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Button('刷新')
          .height(30)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.webController.runJavaScript('render();');
          })
      }
      .width('100%')
      Web({ src: $rawfile('charts/index.html'), controller: this.webController })
        .height(this.viewportWidth > 700 ? 360 : 320)
        .width('100%')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy({
          object: this.reviewBridge,
          name: 'nativeBridge',
          methodList: ['getStats', 'exportPng', 'shareReport'],
          controller: this.webController
        })
        .borderRadius(12)
        .backgroundColor(SURFACE_ALT)
        .margin({ top: 14 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  KpiCard(title: string, value: string, unit: string, icon: string) {
    Column() {
      Row() {
        this.SmallUiAsset(icon, 46)
        Column() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ACCENT)
              .margin({ right: 7 })
            Text(title)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
          }
          .alignItems(VerticalAlign.Center)
          Row() {
            Text(value)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
            Text(unit)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
              .margin({ left: 4, bottom: 3 })
          }
          .alignItems(VerticalAlign.Bottom)
          .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .cardStyleTight()
    .border({ width: { top: 3 }, color: { top: ACCENT_SOFT } })
  }

  @Builder
  BarChartCard(title: string, points: StatPoint[], icon: string) {
    Column() {
      Row() {
        this.SmallUiAsset(icon, 42)
        Column() {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('数据来自本地番茄记录')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      Row() {
        ForEach(points, (point: StatPoint) => {
          Column() {
            Text(`${point.value}`)
              .fontSize(10)
              .fontColor(TEXT_MUTED)
              .margin({ bottom: 6 })
            Stack() {
              Column()
                .width(18)
                .height(114)
                .borderRadius(9)
                .backgroundColor(CARD_SOFT)
              Column()
                .width(18)
                .height(Math.max(6, Math.min(108, point.value * 2 + 6)))
                .borderRadius(9)
                .backgroundColor(ACCENT)
            }
            .alignContent(Alignment.Bottom)
            .height(114)
            .animation({ duration: 240, curve: Curve.EaseOut })
            Text(point.label)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.End)
        }, (point: StatPoint) => point.label)
      }
      .width('100%')
      .height(160)
      .margin({ top: 14 })
      .alignItems(VerticalAlign.Bottom)
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  CompletionCard() {
    Column() {
      Row() {
        this.SmallUiAsset('shield', 42)
        Column() {
          Text('完成 vs 中断')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('中断不会被隐藏，它会成为复盘线索')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      Row() {
        Column() {
          Text(`${focusStore.completedPomodoros()}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Row() {
            Text('●')
              .fontSize(8)
              .fontColor(SUCCESS)
              .margin({ right: 5 })
            Text('完成番茄')
              .fontSize(11)
              .fontColor(TEXT_MUTED)
          }
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor(SUCCESS_SOFT)
        .borderRadius(12)
        Column()
          .width(1)
          .height(48)
          .backgroundColor(BORDER)
          .margin({ left: 10, right: 10 })
        Column() {
          Text(`${focusStore.interruptedPomodoros()}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Row() {
            Text('●')
              .fontSize(8)
              .fontColor(DANGER)
              .margin({ right: 5 })
            Text('中断记录')
              .fontSize(11)
              .fontColor(TEXT_MUTED)
          }
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor(DANGER_SOFT)
        .borderRadius(12)
      }
      .width('100%')
      .margin({ top: 14 })
      .alignItems(VerticalAlign.Center)
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  HeatMapCard() {
    Column() {
      Row() {
        this.SmallUiAsset('heatmap', 42)
        Text('每日热力图')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .margin({ left: 10 })
        Blank()
        Row() {
          Text('少')
            .fontSize(10)
            .fontColor(TEXT_MUTED)
            .margin({ right: 6 })
          Column()
            .width(10)
            .height(10)
            .borderRadius(3)
            .backgroundColor(TRACK)
            .margin({ right: 3 })
          Column()
            .width(10)
            .height(10)
            .borderRadius(3)
            .backgroundColor('#CFD5EA')
            .margin({ right: 3 })
          Column()
            .width(10)
            .height(10)
            .borderRadius(3)
            .backgroundColor('#A6AFD8')
            .margin({ right: 3 })
          Column()
            .width(10)
            .height(10)
            .borderRadius(3)
            .backgroundColor(ACCENT)
            .margin({ right: 6 })
          Text('多')
            .fontSize(10)
            .fontColor(TEXT_MUTED)
        }
      }
      .width('100%')
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(Array.from(Array(35).keys()), (index: number) => {
          Column()
            .width(18)
            .height(18)
            .borderRadius(5)
            .backgroundColor(index % 7 === 0 ? ACCENT : index % 5 === 0 ? '#A6AFD8' : index % 3 === 0 ? '#CFD5EA' : TRACK)
            .margin({ top: 6 })
        }, (index: number) => index.toString())
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  ForestCard() {
    Column() {
      Row() {
        Column() {
          Text('我的学习森林')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('靠番茄和 streak 解锁植物')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text(`${focusStore.unlockedPlants().length} / ${focusStore.plants.length}`)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')

      Row() {
        Image($r('app.media.focus_plant_forest'))
          .width(96)
          .height(96)
          .objectFit(ImageFit.Contain)
          .borderRadius(18)
          .margin({ right: 14 })

        Column() {
          Text(`${focusStore.completedPomodoros()} 个番茄已种下`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`连续 ${focusStore.streakDays()} 天 · 解锁 ${focusStore.unlockedPlants().length} 株植物`)
            .fontSize(12)
            .fontColor(TEXT_SUB)
            .lineHeight(18)
            .margin({ top: 6 })
          Text('AI 教练会把完成和中断都纳入下一次建议')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .lineHeight(16)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(CARD_SOFT)
      .borderRadius(18)
      .margin({ top: 14 })
      .alignItems(VerticalAlign.Center)

      this.ForestRewardStrip()

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(focusStore.plants, (plant: ForestPlant) => {
          this.PlantTile(plant)
        }, (plant: ForestPlant) => plant.id.toString())
      }
      .width('100%')
      .margin({ top: 14 })

      if (focusStore.interruptedPomodoros() > 0) {
        Row() {
          Image($r('app.media.focus_reward_compost'))
            .width(42)
            .height(42)
            .objectFit(ImageFit.Contain)
            .margin({ right: 10 })
          Text(`复盘角落 · 记录 ${focusStore.interruptedPomodoros()} 次中断，用来校准下一次专注风险`)
            .fontSize(11)
            .fontColor(TEXT_SUB)
            .lineHeight(16)
            .layoutWeight(1)
        }
        .padding(12)
        .backgroundColor(SURFACE_ALT)
        .borderRadius(12)
        .margin({ top: 8 })
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  ForestRewardStrip() {
    Row() {
      Column() {
        Image($r('app.media.focus_reward_timer_token'))
          .rewardAssetStyle()
        Text(`${focusStore.completedPomodoros()}`)
          .forestRewardValueStyle()
        Text('番茄')
          .forestRewardLabelStyle()
      }
      .forestRewardTileStyle()

      Column() {
        Image($r('app.media.focus_reward_water'))
          .rewardAssetStyle()
        Text(`${focusStore.streakDays()}`)
          .forestRewardValueStyle()
        Text('连续天')
          .forestRewardLabelStyle()
      }
      .forestRewardTileStyle()
      .margin({ left: 8 })

      Column() {
        Image($r('app.media.focus_reward_stone_path'))
          .rewardAssetStyle()
        Text(`${focusStore.unlockedPlants().length}`)
          .forestRewardValueStyle()
        Text('解锁')
          .forestRewardLabelStyle()
      }
      .forestRewardTileStyle()
      .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  PlantTile(plant: ForestPlant) {
    Column() {
      Stack() {
        Column()
          .width(62)
          .height(62)
          .borderRadius(16)
          .backgroundColor(this.isPlantUnlocked(plant) ? ACCENT_SOFT : SURFACE_ALT)
        this.PlantAsset(plant)
      }
      Text(plant.name)
        .fontSize(12)
        .fontColor(this.isPlantUnlocked(plant) ? TEXT_MAIN : TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
      Text(`${plant.unlockPomodoros} 番茄 · ${plant.unlockStreak} 天`)
        .fontSize(10)
        .fontColor(TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2 })
    }
    .width('31%')
    .height(126)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .border({ width: 1, color: BORDER_SOFT })
    .margin({ right: '2%', bottom: 8 })
    .animation({ duration: 200, curve: Curve.EaseOut })
  }

  private isPlantUnlocked(plant: ForestPlant): boolean {
    return focusStore.completedPomodoros() >= plant.unlockPomodoros && focusStore.streakDays() >= plant.unlockStreak;
  }

  @Builder
  PlantAsset(plant: ForestPlant) {
    if (plant.id === 1) {
      Image($r('app.media.focus_plant_seed'))
        .plantAssetStyle(this.isPlantUnlocked(plant))
    } else if (plant.id === 2) {
      Image($r('app.media.focus_plant_ginkgo'))
        .plantAssetStyle(this.isPlantUnlocked(plant))
    } else if (plant.id === 3) {
      Image($r('app.media.focus_plant_pine'))
        .plantAssetStyle(this.isPlantUnlocked(plant))
    } else if (plant.id === 4) {
      Image($r('app.media.focus_plant_bloom'))
        .plantAssetStyle(this.isPlantUnlocked(plant))
    } else if (plant.id === 5) {
      Image($r('app.media.focus_plant_maple'))
        .plantAssetStyle(this.isPlantUnlocked(plant))
    } else if (plant.id === 6) {
      Image($r('app.media.focus_plant_forest'))
        .plantAssetStyle(this.isPlantUnlocked(plant))
    } else {
      Image($r('app.media.focus_reward_locked_seed'))
        .plantAssetStyle(false)
    }
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
}

@Extend(Column)
function cardStyle() {
  .width('100%')
  .padding(18)
  .backgroundColor(CARD_BG)
  .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
  .borderRadius(20)
  .border({ width: 1, color: '#CCFFFFFF' })
  .shadow({ radius: 22, color: CARD_SHADOW, offsetX: 0, offsetY: 8 })
}

@Extend(Column)
function cardStyleTight() {
  .width('100%')
  .padding(14)
  .backgroundColor(CARD_BG)
  .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
  .borderRadius(16)
  .border({ width: 1, color: '#CCFFFFFF' })
  .shadow({ radius: 16, color: CARD_SHADOW, offsetX: 0, offsetY: 6 })
}

@Extend(Image)
function plantAssetStyle(isUnlocked: boolean) {
  .width(58)
  .height(58)
  .objectFit(ImageFit.Contain)
  .opacity(isUnlocked ? 1 : 0.34)
}

@Extend(Image)
function rewardAssetStyle() {
  .width(38)
  .height(38)
  .objectFit(ImageFit.Contain)
}

@Extend(Image)
function microAssetStyle(size: number) {
  .width(size)
  .height(size)
  .objectFit(ImageFit.Cover)
  .borderRadius(Math.round(size / 4))
}

@Extend(Column)
function forestRewardTileStyle() {
  .layoutWeight(1)
  .height(92)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .backgroundColor(CARD_SOFT)
  .border({ width: 1, color: BORDER_SOFT })
  .borderRadius(14)
}

@Extend(Text)
function forestRewardValueStyle() {
  .fontSize(15)
  .fontWeight(FontWeight.Bold)
  .fontColor(TEXT_MAIN)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .margin({ top: 4 })
}

@Extend(Text)
function forestRewardLabelStyle() {
  .fontSize(10)
  .fontColor(TEXT_MUTED)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .margin({ top: 2 })
}
