import {
  ACCENT,
  ACCENT_SOFT,
  BORDER_SOFT,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  CARD_SOFT,
  GRADIENT_ACCENT_END,
  GRADIENT_ACCENT_START,
  SHADOW_CARD_COLOR,
  SHADOW_CARD_OFFSET_X,
  SHADOW_CARD_OFFSET_Y,
  SHADOW_CARD_RADIUS,
  SHADOW_FLOAT_COLOR,
  SHADOW_FLOAT_OFFSET_X,
  SHADOW_FLOAT_OFFSET_Y,
  SHADOW_FLOAT_RADIUS,
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  TRACK
} from '../utils/FocusDesignTokens';
import { FocusTask, TaskStatus } from '../models/FocusModels';
import { EmptyState, SoftIconBadge } from './FocusVisuals';
import { TaskRowView } from './TasksView';

const EMPTY_TASK: FocusTask = {
  id: 0,
  title: '添加一个任务后开始专注',
  note: '',
  projectId: 0,
  priority: 1,
  dueAt: 0,
  status: TaskStatus.TODO,
  pomodoroCount: 0,
  createdAt: 0,
  completedAt: 0,
  tags: [],
  subtasks: []
};

@Component
export struct QuickAddTaskCard {
  @Prop notificationReady: boolean = false;
  @State draftTitle: string = '';

  onAddTask: (title: string) => void = () => {};
  onRequestNotification: () => void = () => {};

  private submitTask(): void {
    const title: string = this.draftTitle.trim();
    if (title.length === 0) {
      return;
    }
    this.onAddTask(title);
    this.draftTitle = '';
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_quick_add'))
          .width(44)
          .height(44)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ right: 10 })
        Column() {
          Text('快速添加任务')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('自动归入默认项目 / 紧急重要')
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

      TextInput({ placeholder: '例如：整理期末答辩 PPT', text: this.draftTitle })
        .height(46)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(14)
        .margin({ top: 14 })
        .onChange((value: string) => {
          this.draftTitle = value;
        })
        .onSubmit(() => {
          this.submitTask();
        })

      Row() {
        Button('添加任务')
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
          .shadow({ radius: 14, color: '#253A7A1C', offsetX: 0, offsetY: 6 })
          .onClick(() => {
            this.submitTask();
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
            this.onRequestNotification();
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Text(this.notificationReady ? '通知已启用，到期与番茄结束会提醒你' : '建议开启通知，避免错过到期时间')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(CARD_GLASS)
    .borderRadius(18)
    .border({ width: 1, color: BORDER_SOFT })
    .shadow({ radius: SHADOW_CARD_RADIUS, color: SHADOW_CARD_COLOR, offsetX: SHADOW_CARD_OFFSET_X, offsetY: SHADOW_CARD_OFFSET_Y })
  }
}

@Component
export struct TodayView {
  @Prop tasks: FocusTask[] = [];
  @Prop selectedTask: FocusTask = EMPTY_TASK;
  @Prop totalFocusMinutes: number = 0;
  @Prop notificationReady: boolean = false;

  onStartFocus: (taskId: number) => void = () => {};
  onToggleTask: (taskId: number) => void = () => {};
  onDeleteTask: (taskId: number) => void = () => {};
  onRestoreTask: (taskId: number) => void = () => {};
  onAddTask: (title: string) => void = () => {};
  onRequestNotification: () => void = () => {};

  private todayTasks(): FocusTask[] {
    return this.tasks
      .filter((task: FocusTask) => task.status === TaskStatus.TODO && task.isDeleted !== 1)
      .sort((left: FocusTask, right: FocusTask) => {
        if (left.priority !== right.priority) {
          return left.priority - right.priority;
        }
        return left.dueAt - right.dueAt;
      });
  }

  private doneCount(): number {
    return this.tasks.filter((task: FocusTask) => task.status === TaskStatus.DONE && task.isDeleted !== 1).length;
  }

  private totalCount(): number {
    return this.tasks.filter((task: FocusTask) => task.status !== TaskStatus.DELETED && task.isDeleted !== 1).length;
  }

  private startSelectedTask(): void {
    if (this.selectedTask.id <= 0) {
      return;
    }
    this.onStartFocus(this.selectedTask.id);
  }

  build() {
    Scroll() {
      Column() {
        this.TodayHeroCard()
        this.TodayTaskList()
        QuickAddTaskCard({
          notificationReady: this.notificationReady,
          onAddTask: this.onAddTask,
          onRequestNotification: this.onRequestNotification
        })
      }
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private TodayHeroCard() {
    Column() {
      Row() {
        Column() {
          Text('今日')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MUTED)
          Text('先做这一件')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SoftIconBadge({ variant: 'marker', badgeSize: 42, fill: SUCCESS_SOFT })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.selectedTask.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .lineHeight(22)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 18 })

      Progress({
        value: this.doneCount(),
        total: Math.max(1, this.totalCount()),
        type: ProgressType.Linear
      })
        .width('100%')
        .height(6)
        .color(ACCENT)
        .backgroundColor(TRACK)
        .borderRadius(3)
        .margin({ top: 22 })

      Row() {
        Text(`${this.doneCount()}/${this.totalCount()} 完成`)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
        Blank()
        Text(`${this.totalFocusMinutes} 分钟`)
          .fontSize(12)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 10 })

      Button('开始专注')
        .height(42)
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(TEXT_MAIN)
        .fontColor('#FFFFFF')
        .borderRadius(14)
        .margin({ top: 20 })
        .onClick(() => {
          this.startSelectedTask();
        })
    }
    .width('100%')
    .padding(22)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(22)
    .backgroundColor(CARD_GLASS)
    .backdropBlur(CARD_GLASS_BLUR)
    .border({ width: 1, color: BORDER_SOFT })
    .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
    .margin({ bottom: 14 })
  }

  @Builder
  private TodayTaskList() {
    Column() {
      Row() {
        Text('今日待办')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text(`${this.todayTasks().length} 项`)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.todayTasks().length === 0) {
        EmptyState({ title: '今天没有待办', caption: '可以先添加一个 25 分钟内能完成的小任务。', variant: 'inbox' })
      } else {
        ForEach(this.todayTasks(), (task: FocusTask) => {
          TaskRowView({
            task: task,
            allowFocusJump: true,
            onToggleTask: this.onToggleTask,
            onStartFocus: this.onStartFocus,
            onDeleteTask: this.onDeleteTask,
            onRestoreTask: this.onRestoreTask
          })
        }, (task: FocusTask) => task.id.toString())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor(CARD_GLASS)
    .borderRadius(20)
    .border({ width: 1, color: BORDER_SOFT })
    .shadow({ radius: SHADOW_CARD_RADIUS, color: SHADOW_CARD_COLOR, offsetX: SHADOW_CARD_OFFSET_X, offsetY: SHADOW_CARD_OFFSET_Y })
    .alignItems(HorizontalAlign.Start)
  }
}
