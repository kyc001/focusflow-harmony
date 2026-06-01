import { focusStore } from '../services/FocusStore';
import {
  ACCENT,
  BORDER,
  BORDER_SOFT,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  CARD_SOFT,
  DANGER,
  DANGER_SOFT,
  GLOW_BLUE,
  GRADIENT_ACCENT_END,
  GRADIENT_ACCENT_START,
  RADIUS_XL,
  SHADOW_FLOAT_COLOR,
  SHADOW_FLOAT_OFFSET_X,
  SHADOW_FLOAT_OFFSET_Y,
  SHADOW_FLOAT_RADIUS,
  SPACING_XL,
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_DIM,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB
} from '../utils/FocusDesignTokens';
import {
  formatDueText,
  priorityColor,
  priorityName,
  priorityTint
} from '../utils/FocusFormatters';
import { FocusProject, FocusTask, TaskStatus } from '../models/FocusModels';
import { EmptyState, FocusSmallUiAsset } from './FocusVisuals';

const EMPTY_TASK: FocusTask = {
  id: 0,
  title: '',
  note: '',
  projectId: 0,
  priority: 0,
  dueAt: 0,
  status: TaskStatus.TODO,
  pomodoroCount: 0,
  createdAt: 0,
  completedAt: 0,
  tags: [],
  subtasks: []
};

@Component
export struct TasksView {
  @Prop tasks: FocusTask[] = [];
  @State searchText: string = '';
  @State filterProjectId: number = 0;
  @State filterPriority: number = -1;
  @State showRecycle: boolean = false;

  onToggleTask: (taskId: number) => void = () => {};
  onStartFocus: (taskId: number) => void = () => {};
  onDeleteTask: (taskId: number) => void = () => {};
  onRestoreTask: (taskId: number) => void = () => {};

  private filteredTasks(): FocusTask[] {
    const keyword: string = this.searchText.trim();
    return this.tasks.filter((task: FocusTask) => {
      const deleted: boolean = task.status === TaskStatus.DELETED || task.isDeleted === 1;
      const projectMatched: boolean = this.filterProjectId === 0 || task.projectId === this.filterProjectId;
      const priorityMatched: boolean = this.filterPriority < 0 || task.priority === this.filterPriority;
      const keywordMatched: boolean = keyword.length === 0 ||
        task.title.indexOf(keyword) >= 0 ||
        task.note.indexOf(keyword) >= 0 ||
        task.tags.join(',').indexOf(keyword) >= 0;
      const statusMatched: boolean = this.showRecycle ? deleted : !deleted;
      return projectMatched && priorityMatched && keywordMatched && statusMatched;
    });
  }

  build() {
    Column() {
      this.FilterBar()
      this.TaskListCard()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private FilterBar() {
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
          Text(priorityName(priority))
            .height(30)
            .fontSize(12)
            .fontWeight(this.filterPriority === priority ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.filterPriority === priority ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.filterPriority === priority ? priorityColor(priority) : SURFACE_ALT)
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
    .tasksCardStyle()
  }

  @Builder
  private TaskListCard() {
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
        EmptyState({
          title: this.showRecycle ? '回收站是空的' : '没有匹配的任务',
          caption: '换一个筛选条件，或回到今日页快速添加。',
          variant: this.showRecycle ? 'medal' : 'inbox'
        })
      } else {
        ForEach(this.filteredTasks(), (task: FocusTask) => {
          TaskRowView({
            task: task,
            allowFocusJump: false,
            onToggleTask: this.onToggleTask,
            onStartFocus: this.onStartFocus,
            onDeleteTask: this.onDeleteTask,
            onRestoreTask: this.onRestoreTask
          })
        }, (task: FocusTask) => task.id.toString())
      }
    }
    .tasksCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }
}

@Extend(Column)
function tasksCardStyle() {
  .width('100%')
  .padding(SPACING_XL)
  .backgroundColor(CARD_GLASS)
  .backdropBlur(CARD_GLASS_BLUR)
  .borderRadius(RADIUS_XL)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
}

@Component
export struct TaskRowView {
  @Prop task: FocusTask = EMPTY_TASK;
  @Prop allowFocusJump: boolean = false;

  onToggleTask: (taskId: number) => void = () => {};
  onStartFocus: (taskId: number) => void = () => {};
  onDeleteTask: (taskId: number) => void = () => {};
  onRestoreTask: (taskId: number) => void = () => {};

  build() {
    Column() {
      Row() {
        Stack() {
          Column()
            .width(20)
            .height(20)
            .borderRadius(10)
            .backgroundColor(this.task.status === TaskStatus.DONE ? SUCCESS : Color.Transparent)
            .border({ width: this.task.status === TaskStatus.DONE ? 0 : 1.5, color: BORDER })
          if (this.task.status === TaskStatus.DONE) {
            Text('✓')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
        }
        .margin({ right: 10 })
        .onClick(() => {
          this.onToggleTask(this.task.id);
        })

        Column() {
          FocusSmallUiAsset({ variant: this.task.status === TaskStatus.DONE ? 'medal' : 'priority', assetSize: 38 })
        }
        .width(38)
        .height(38)
        .margin({ right: 10 })

        Column() {
          Row() {
            Text(this.task.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.task.status === TaskStatus.DONE ? TEXT_MUTED : TEXT_MAIN)
              .decoration({ type: this.task.status === TaskStatus.DONE ? TextDecorationType.LineThrough : TextDecorationType.None })
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(formatDueText(this.task.dueAt))
              .fontSize(11)
              .fontColor(formatDueText(this.task.dueAt) === '已到期' ? DANGER : TEXT_MUTED)
              .backgroundColor(formatDueText(this.task.dueAt) === '已到期' ? DANGER_SOFT : SURFACE_ALT)
              .borderRadius(8)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .margin({ left: 8 })
          }
          .width('100%')

          Row() {
            this.ProjectPill(this.task.projectId)
            Text('·')
              .fontSize(10)
              .fontColor(TEXT_DIM)
              .margin({ left: 8, right: 8 })
            Text(priorityName(this.task.priority))
              .fontSize(11)
              .fontColor(priorityColor(this.task.priority))
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor(this.task.status === TaskStatus.DONE ? SURFACE_ALT : priorityTint(this.task.priority))
              .borderRadius(7)
            Text('·')
              .fontSize(10)
              .fontColor(TEXT_DIM)
              .margin({ left: 8, right: 8 })
            Text(`${this.task.pomodoroCount} 番茄`)
              .fontSize(11)
              .fontColor(TEXT_MUTED)
          }
          .width('100%')
          .margin({ top: 4 })

          if (!this.allowFocusJump && this.task.note.length > 0) {
            Text(this.task.note)
              .fontSize(12)
              .fontColor(TEXT_SUB)
              .lineHeight(18)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 6 })
          }
          if (!this.allowFocusJump && this.task.subtasks.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.task.subtasks, (item: string) => {
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
            if (this.task.status === TaskStatus.DELETED || this.task.isDeleted === 1) {
              Button('恢复任务')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(SUCCESS_SOFT)
                .fontColor(SUCCESS)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onClick(() => {
                  this.onRestoreTask(this.task.id);
                })
            } else {
              Button(this.allowFocusJump ? '进入专注' : '开始番茄')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(ACCENT)
                .linearGradient({
                  angle: 90,
                  colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
                })
                .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
                .fontColor('#FFFFFF')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .shadow({ radius: 10, color: '#253A7A18', offsetX: 0, offsetY: 4 })
                .onClick(() => {
                  this.onStartFocus(this.task.id);
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
                  this.onDeleteTask(this.task.id);
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
    .backgroundColor(this.task.status === TaskStatus.DONE ? CARD_SOFT : '#FFFFFF')
    .borderRadius(14)
    .border({
      width: { left: 3 },
      color: { left: this.task.status === TaskStatus.DONE ? TEXT_DIM : priorityColor(this.task.priority) }
    })
    .margin({ bottom: 8 })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  private ProjectPill(projectId: number) {
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
}
