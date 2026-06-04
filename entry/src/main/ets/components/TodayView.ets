import {
  ACCENT,
  BORDER_SOFT,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  SHADOW_CARD_COLOR,
  SHADOW_CARD_OFFSET_X,
  SHADOW_CARD_OFFSET_Y,
  SHADOW_CARD_RADIUS,
  SHADOW_FLOAT_COLOR,
  SHADOW_FLOAT_OFFSET_X,
  SHADOW_FLOAT_OFFSET_Y,
  SHADOW_FLOAT_RADIUS,
  SUCCESS_SOFT,
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
export struct TodayView {
  @Prop tasks: FocusTask[] = [];
  @Prop selectedTask: FocusTask = EMPTY_TASK;
  @Prop totalFocusMinutes: number = 0;

  onStartFocus: (taskId: number) => void = () => {};
  onToggleTask: (taskId: number) => void = () => {};
  onDeleteTask: (taskId: number) => void = () => {};
  onRestoreTask: (taskId: number) => void = () => {};

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
