import { common } from '@kit.AbilityKit';
import webview from '@ohos.web.webview';
import { authRepository, LoginProfile } from '../repository/AuthRepository';
import { focusDatabase } from '../services/FocusDatabase';
import { focusStore } from '../services/FocusStore';
import { FocusBackgroundService, FocusNotificationService } from '../services/FocusNativeServices';
import { FocusProject, FocusSettings, FocusTask, ForestPlant, PomodoroRecord, PomodoroStatus, StatPoint, TaskStatus } from '../models/FocusModels';

const PAGE_BG: string = '#EEF2F7';
const CARD_BG: string = '#FFFFFF';
const CARD_SOFT: string = '#F8FAFC';
const BORDER: string = '#E4E9F2';
const BORDER_SOFT: string = '#EEF1F6';

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
const CARD_SHADOW: string = '#0B142614';
const CARD_SHADOW_STRONG: string = '#0B102628';

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
      await focusStore.refresh();
      this.syncFromStore();
      await authRepository.init(context);
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
    this.settings = focusStore.settings;
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
        this.activeTab = 2;
      });
    } catch (err) {
      this.activeTab = 2;
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
  }

  private timeText(seconds: number): string {
    const minute: number = Math.floor(seconds / 60);
    const second: number = seconds % 60;
    const minuteText: string = minute < 10 ? `0${minute}` : `${minute}`;
    const secondText: string = second < 10 ? `0${second}` : `${second}`;
    return `${minuteText}:${secondText}`;
  }

  private dueText(timestamp: number): string {
    const diff: number = timestamp - Date.now();
    if (diff <= 0) {
      return '已到期';
    }
    const hours: number = Math.ceil(diff / (60 * 60 * 1000));
    if (hours < 24) {
      return `${hours} 小时内`;
    }
    return `${Math.ceil(hours / 24)} 天内`;
  }

  private priorityName(priority: number): string {
    if (priority === 0) {
      return '紧急重要';
    }
    if (priority === 1) {
      return '紧急不重要';
    }
    if (priority === 2) {
      return '重要不紧急';
    }
    return '不紧急不重要';
  }

  private priorityColor(priority: number): string {
    if (priority === 0) {
      return '#E4566E';
    }
    if (priority === 1) {
      return '#F59E0B';
    }
    if (priority === 2) {
      return '#2F6BFF';
    }
    return '#8B95A7';
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
    if (this.timerStatus === PomodoroStatus.RUNNING) {
      return '沉浸中';
    }
    if (this.timerStatus === PomodoroStatus.PAUSED) {
      return '已暂停';
    }
    if (this.timerStatus === PomodoroStatus.FINISHED) {
      return '休息一下';
    }
    return '准备开始';
  }

  private focusStateColor(): string {
    if (this.timerStatus === PomodoroStatus.RUNNING) {
      return ACCENT;
    }
    if (this.timerStatus === PomodoroStatus.PAUSED) {
      return WARNING;
    }
    if (this.timerStatus === PomodoroStatus.FINISHED) {
      return SUCCESS;
    }
    return '#8B95A7';
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
              this.FocusTab()
            }
            .tabBar('专注')

            TabContent() {
              this.ReviewTab()
            }
            .tabBar('复盘')
          }
          .barMode(BarMode.Fixed)
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
          Text('FOCUS')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#80FFFFFF')
            .letterSpacing(3)
          Text('把今天最重要的事完成')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 12 })
          Text('本地优先 · 离线可用 · 可选同步')
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
          Text('Focus')
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
          Text('Focus')
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
        this.EmptyState('今天没有待办', '可以先添加一个 25 分钟内能完成的小任务。')
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
  EmptyState(title: string, caption: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
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
            this.EmptyState(this.showRecycle ? '回收站是空的' : '没有匹配的任务', '换一个筛选条件，或回到今日页快速添加。')
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
      this.SettingsCard()
      this.WhiteNoiseCard()
      this.HistoryCard()
    }
    .width('100%')
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
          if (label === '专注') {
            this.settings.focusMinutes = Math.round(changedValue);
            if (this.timerStatus === PomodoroStatus.IDLE) {
              this.remainingSeconds = this.settings.focusMinutes * 60;
            }
          } else if (label === '短休') {
            this.settings.shortBreakMinutes = Math.round(changedValue);
          } else {
            this.settings.longBreakMinutes = Math.round(changedValue);
          }
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
              this.settings.noise = noise;
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
            this.KpiCard('总专注', `${focusStore.totalFocusMinutes()}`, '分钟')
          }
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
            this.KpiCard('完成率', `${Math.round(focusStore.completedPomodoros() * 100 / Math.max(1, this.records.length))}`, '%')
          }
          GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
            this.KpiCard('最长 streak', `${focusStore.bestStreakDays()}`, '天')
          }
        }

        this.WebReviewCard()
        this.BarChartCard('本周学习时长', focusStore.weekFocusPoints())
        this.BarChartCard('项目时间占比', focusStore.projectFocusPoints())
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
  KpiCard(title: string, value: string, unit: string) {
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
    .cardStyleTight()
    .border({ width: { top: 3 }, color: { top: ACCENT_SOFT } })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BarChartCard(title: string, points: StatPoint[]) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
      Text('数据来自本地番茄记录')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .margin({ top: 2 })
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
      Text('完成 vs 中断')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
      Text('中断不会被隐藏，它会成为复盘线索')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .margin({ top: 2 })
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
        Text('每日热力图')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
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

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(focusStore.plants, (plant: ForestPlant) => {
          this.PlantTile(plant)
        }, (plant: ForestPlant) => plant.id.toString())
      }
      .width('100%')
      .margin({ top: 14 })

      if (focusStore.interruptedPomodoros() > 0) {
        Text(`枯萎角落 · 记录 ${focusStore.interruptedPomodoros()} 次中断，用来复盘注意力风险`)
          .fontSize(11)
          .fontColor(TEXT_SUB)
          .lineHeight(16)
          .padding(12)
          .backgroundColor(SURFACE_ALT)
          .borderRadius(10)
          .margin({ top: 8 })
          .width('100%')
      }
    }
    .cardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  PlantTile(plant: ForestPlant) {
    Column() {
      Stack() {
        Column()
          .width(50)
          .height(50)
          .borderRadius(16)
          .backgroundColor(this.isPlantUnlocked(plant) ? ACCENT_SOFT : SURFACE_ALT)
        Text(plant.icon)
          .fontSize(22)
          .opacity(this.isPlantUnlocked(plant) ? 1 : 0.3)
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
    .height(112)
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
  .borderRadius(20)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: 24, color: CARD_SHADOW, offsetX: 0, offsetY: 10 })
}

@Extend(Column)
function cardStyleTight() {
  .width('100%')
  .padding(14)
  .backgroundColor(CARD_BG)
  .borderRadius(16)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: 18, color: CARD_SHADOW, offsetX: 0, offsetY: 8 })
}
