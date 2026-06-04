import { focusStore } from '../services/FocusStore';
import {
  ACCENT,
  ACCENT_SOFT,
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
import { FocusProject, FocusTask, QuickTaskDraft, TaskStatus } from '../models/FocusModels';
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

const EMPTY_QUICK_TASK_DRAFT: QuickTaskDraft = {
  title: '',
  note: '',
  priority: 1,
  dueOffsetHours: 8,
  source: 'image',
  tags: ['图片提取'],
  subtasks: []
};

@Component
export struct QuickAddTaskCard {
  @Prop notificationReady: boolean = false;
  @Prop remoteAiReady: boolean = false;
  @Prop imageLoading: boolean = false;
  @Prop imageMessage: string = '';
  @Prop imageDrafts: QuickTaskDraft[] = [];
  @Prop imageDraftIndex: number = 0;
  @Prop imageRawPreview: string = '';
  @State draftText: string = '';
  @State draftNote: string = '';
  @State dueText: string = '今天18:00';
  @State projectId: number = 0;
  @State priority: number = 1;

  onAddTask: (draft: QuickTaskDraft) => void = () => {};
  onRequestNotification: () => void = () => {};
  onPickTaskImage: () => void = () => {};
  onCaptureTaskImage: () => void = () => {};
  onSelectImageDraft: (index: number) => void = () => {};
  onUpdateImageDraft: (index: number, draft: QuickTaskDraft) => void = () => {};
  onConfirmImageDraft: (index: number) => void = () => {};
  onConfirmAllImageDrafts: () => void = () => {};
  onCancelImageDrafts: () => void = () => {};

  private submitTask(): void {
    const lines: string[] = this.draftText
      .split('\n')
      .map((line: string) => line.trim())
      .filter((line: string) => line.length > 0);
    if (lines.length === 0) {
      return;
    }
    const extraNote: string = lines.length > 1 ? lines.slice(1).join('\n') : '';
    const note: string = this.draftNote.trim().length > 0 ? this.draftNote.trim() : extraNote;
    this.onAddTask({
      title: lines[0],
      note: note,
      projectId: this.projectId,
      priority: this.priority,
      dueAt: this.parseDueAt(this.dueText),
      source: 'manual',
      tags: ['快速添加'],
      subtasks: lines.length > 1 ? lines.slice(1, 4) : []
    });
    this.draftText = '';
    this.draftNote = '';
    this.dueText = '今天18:00';
  }

  private parseDueAt(value: string): number {
    const text: string = value.trim().replace(/：/g, ':').toLowerCase();
    const now: Date = new Date();
    if (text.length === 0) {
      return now.getTime() + 8 * 60 * 60 * 1000;
    }
    const relativeHour: number = this.firstNumberBefore(text, ['小时', 'h']);
    if (relativeHour > 0) {
      return now.getTime() + relativeHour * 60 * 60 * 1000;
    }
    const relativeDay: number = this.firstNumberBefore(text, ['天', 'd']);
    if (relativeDay > 0) {
      return now.getTime() + relativeDay * 24 * 60 * 60 * 1000;
    }
    const absolute: number = Date.parse(text.replace(' ', 'T'));
    if (!Number.isNaN(absolute)) {
      return absolute;
    }
    const target: Date = new Date(now.getTime());
    let dayOffset: number = 0;
    if (text.indexOf('明天') >= 0) {
      dayOffset = 1;
    } else if (text.indexOf('后天') >= 0) {
      dayOffset = 2;
    }
    const clock: number[] = this.parseClock(text);
    const defaultHour: number = text.indexOf('上午') >= 0 || text.indexOf('早') >= 0 ? 9 : 18;
    target.setDate(target.getDate() + dayOffset);
    target.setHours(clock[0] >= 0 ? clock[0] : defaultHour, clock[1], 0, 0);
    if (dayOffset === 0 && target.getTime() <= now.getTime()) {
      target.setDate(target.getDate() + 1);
    }
    return target.getTime();
  }

  private firstNumberBefore(text: string, units: string[]): number {
    for (let index: number = 0; index < units.length; index++) {
      const unit: string = units[index];
      const unitIndex: number = text.indexOf(unit);
      if (unitIndex > 0) {
        const prefix: string = text.substring(0, unitIndex);
        const numberText: string = prefix.replace(/[^0-9.]/g, '');
        const parsed: number = Number(numberText);
        if (!Number.isNaN(parsed)) {
          return Math.round(parsed);
        }
      }
    }
    return 0;
  }

  private parseClock(text: string): number[] {
    const separatorIndex: number = text.indexOf(':');
    if (separatorIndex > 0) {
      const leftDigits: string = text.substring(0, separatorIndex).replace(/[^0-9]/g, '');
      const rightDigits: string = text.substring(separatorIndex + 1).replace(/[^0-9]/g, '');
      const hour: number = Number(leftDigits.length > 0 ? leftDigits.substring(Math.max(0, leftDigits.length - 2)) : '-1');
      const minute: number = Number(rightDigits.length > 0 ? rightDigits.substring(0, 2) : '0');
      return [Number.isNaN(hour) ? -1 : hour, Number.isNaN(minute) ? 0 : minute];
    }
    const hourIndex: number = text.indexOf('点');
    if (hourIndex > 0) {
      const hourText: string = text.substring(0, hourIndex).replace(/[^0-9]/g, '');
      const minuteText: string = text.substring(hourIndex + 1).replace(/[^0-9]/g, '');
      const hour: number = Number(hourText.length > 0 ? hourText.substring(Math.max(0, hourText.length - 2)) : '-1');
      const minute: number = Number(minuteText.length > 0 ? minuteText.substring(0, 2) : '0');
      return [Number.isNaN(hour) ? -1 : hour, Number.isNaN(minute) ? 0 : minute];
    }
    return [-1, 0];
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
          Text('多行说明、截止时间和图片提取都在这里')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.remoteAiReady ? 'AI 可用' : '本地写入')
          .fontSize(11)
          .fontColor(this.remoteAiReady ? SUCCESS : ACCENT)
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .backgroundColor(this.remoteAiReady ? SUCCESS_SOFT : ACCENT_SOFT)
          .borderRadius(9)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      TextArea({ placeholder: '第一行写任务标题，换行可补充拆解步骤', text: this.draftText })
        .height(76)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .fontSize(14)
        .margin({ top: 14 })
        .onChange((value: string) => {
          this.draftText = value;
        })

      TextArea({ placeholder: '备注，可写资料来源、要求或注意事项', text: this.draftNote })
        .height(58)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14, top: 9, bottom: 9 })
        .fontSize(13)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.draftNote = value;
        })

      Text('截止时间')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12, bottom: 6 })

      TextInput({ placeholder: '今天18:00 / 明天09:00 / 6小时后', text: this.dueText })
        .height(40)
        .backgroundColor(CARD_SOFT)
        .borderRadius(11)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 12, right: 12 })
        .fontSize(13)
        .onChange((value: string) => {
          this.dueText = value;
        })

      Row() {
        this.TimePresetChip('今天18:00')
        this.TimePresetChip('明天09:00')
        this.TimePresetChip('3天后')
      }
      .width('100%')
      .margin({ top: 8 })

      Text('项目')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12, bottom: 6 })

      Flex({ wrap: FlexWrap.Wrap }) {
        this.ProjectChip(0, '默认')
        ForEach(focusStore.projects, (project: FocusProject) => {
          this.ProjectChip(project.id, project.name)
        }, (project: FocusProject) => project.id.toString())
      }
      .width('100%')

      Text('象限')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 8, bottom: 6 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach([0, 1, 2, 3], (priority: number) => {
          this.PriorityChip(priority)
        }, (priority: number) => priority.toString())
      }
      .width('100%')

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

      Row() {
        Button(this.imageLoading ? '识别中' : '拍照提取')
          .height(38)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.imageLoading ? SURFACE_ALT : SUCCESS_SOFT)
          .fontColor(this.imageLoading ? TEXT_MUTED : SUCCESS)
          .borderRadius(11)
          .onClick(() => {
            this.onCaptureTaskImage();
          })
        Button(this.imageLoading ? '识别中' : '上传图片')
          .height(38)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.imageLoading ? SURFACE_ALT : ACCENT_SOFT)
          .fontColor(this.imageLoading ? TEXT_MUTED : ACCENT)
          .borderRadius(11)
          .margin({ left: 10 })
          .onClick(() => {
            this.onPickTaskImage();
          })
      }
      .width('100%')
      .margin({ top: 10 })

      Text(this.imageMessage.length > 0 ? this.imageMessage : (this.notificationReady ? '通知已启用，到期与番茄结束会提醒你' : '建议开启通知，避免错过到期时间'))
        .fontSize(11)
        .fontColor(this.imageMessage.indexOf('失败') >= 0 || this.imageMessage.indexOf('过大') >= 0 ? DANGER : TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 10 })

      if (this.imageDrafts.length > 0) {
        this.ImageDraftConfirm()
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(CARD_GLASS)
    .borderRadius(18)
    .border({ width: 1, color: BORDER_SOFT })
    .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
  }

  private safeImageDraftIndex(): number {
    if (this.imageDrafts.length === 0) {
      return 0;
    }
    return Math.max(0, Math.min(this.imageDraftIndex, this.imageDrafts.length - 1));
  }

  private currentImageDraft(): QuickTaskDraft {
    if (this.imageDrafts.length === 0) {
      return EMPTY_QUICK_TASK_DRAFT;
    }
    return this.imageDrafts[this.safeImageDraftIndex()];
  }

  private emitImageDraft(title: string, note: string, priority: number): void {
    const draft: QuickTaskDraft = this.currentImageDraft();
    this.onUpdateImageDraft(this.safeImageDraftIndex(), {
      title: title,
      note: note,
      projectId: draft.projectId,
      priority: priority,
      dueAt: draft.dueAt,
      dueOffsetHours: draft.dueOffsetHours,
      source: draft.source,
      tags: draft.tags,
      subtasks: draft.subtasks
    });
  }

  @Builder
  private ImageDraftConfirm() {
    Column() {
      Divider()
        .color(BORDER_SOFT)
        .margin({ top: 14, bottom: 12 })

      Row() {
        Column() {
          Text('识别结果确认')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text(`${this.safeImageDraftIndex() + 1}/${this.imageDrafts.length} 条候选，确认后再写入任务库`)
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Button('取消')
          .height(30)
          .fontSize(11)
          .fontColor(TEXT_SUB)
          .backgroundColor(SURFACE_ALT)
          .borderRadius(9)
          .onClick(() => {
            this.onCancelImageDrafts();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.imageDrafts.length > 1) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.imageDrafts, (draft: QuickTaskDraft, index: number) => {
            Text(`${index + 1}. ${draft.title}`)
              .height(28)
              .fontSize(11)
              .fontWeight(this.safeImageDraftIndex() === index ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.safeImageDraftIndex() === index ? '#FFFFFF' : TEXT_SUB)
              .backgroundColor(this.safeImageDraftIndex() === index ? ACCENT : SURFACE_ALT)
              .borderRadius(9)
              .padding({ left: 10, right: 10 })
              .margin({ right: 6, bottom: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.onSelectImageDraft(index);
              })
          }, (draft: QuickTaskDraft, index: number) => `${index}-${draft.title}`)
        }
        .width('100%')
        .margin({ top: 10 })
      }

      TextInput({ placeholder: '确认任务标题', text: this.currentImageDraft().title })
        .height(40)
        .backgroundColor(CARD_SOFT)
        .borderRadius(11)
        .border({ width: 1, color: BORDER_SOFT })
        .fontSize(13)
        .padding({ left: 12, right: 12 })
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.emitImageDraft(value, this.currentImageDraft().note, this.currentImageDraft().priority);
        })

      TextArea({ placeholder: '确认备注或来源', text: this.currentImageDraft().note })
        .height(58)
        .backgroundColor(CARD_SOFT)
        .borderRadius(11)
        .border({ width: 1, color: BORDER_SOFT })
        .fontSize(12)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.emitImageDraft(this.currentImageDraft().title, value, this.currentImageDraft().priority);
        })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach([0, 1, 2, 3], (priority: number) => {
          Text(priorityName(priority))
            .height(28)
            .fontSize(11)
            .fontWeight(this.currentImageDraft().priority === priority ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentImageDraft().priority === priority ? '#FFFFFF' : priorityColor(priority))
            .backgroundColor(this.currentImageDraft().priority === priority ? priorityColor(priority) : priorityTint(priority))
            .borderRadius(9)
            .padding({ left: 10, right: 10 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.emitImageDraft(this.currentImageDraft().title, this.currentImageDraft().note, priority);
            })
        }, (priority: number) => priority.toString())
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Button('保存这一条')
          .height(38)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(ACCENT)
          .borderRadius(11)
          .onClick(() => {
            this.onConfirmImageDraft(this.safeImageDraftIndex());
          })
        Button('全部保存')
          .height(38)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(SUCCESS)
          .backgroundColor(SUCCESS_SOFT)
          .borderRadius(11)
          .margin({ left: 10 })
          .onClick(() => {
            this.onConfirmAllImageDrafts();
          })
      }
      .width('100%')
      .margin({ top: 8 })

      if (this.imageRawPreview.length > 0) {
        Text(`AI 原文：${this.imageRawPreview}`)
          .fontSize(10)
          .fontColor(TEXT_DIM)
          .lineHeight(15)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private TimePresetChip(value: string) {
    Text(value)
      .height(28)
      .fontSize(11)
      .fontWeight(this.dueText === value ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.dueText === value ? '#FFFFFF' : TEXT_SUB)
      .backgroundColor(this.dueText === value ? ACCENT : SURFACE_ALT)
      .borderRadius(9)
      .padding({ left: 10, right: 10 })
      .margin({ right: 6 })
      .onClick(() => {
        this.dueText = value;
      })
  }

  @Builder
  private ProjectChip(id: number, name: string) {
    Text(name)
      .height(28)
      .fontSize(11)
      .fontWeight(this.projectId === id ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.projectId === id ? '#FFFFFF' : TEXT_SUB)
      .backgroundColor(this.projectId === id ? (id === 0 ? ACCENT : focusStore.getProject(id).color) : SURFACE_ALT)
      .borderRadius(9)
      .padding({ left: 10, right: 10 })
      .margin({ right: 6, bottom: 6 })
      .onClick(() => {
        this.projectId = id;
      })
  }

  @Builder
  private PriorityChip(priority: number) {
    Text(priorityName(priority))
      .height(28)
      .fontSize(11)
      .fontWeight(this.priority === priority ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.priority === priority ? '#FFFFFF' : priorityColor(priority))
      .backgroundColor(this.priority === priority ? priorityColor(priority) : priorityTint(priority))
      .borderRadius(9)
      .padding({ left: 10, right: 10 })
      .margin({ right: 6, bottom: 6 })
      .onClick(() => {
        this.priority = priority;
      })
  }
}

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
          caption: '换一个筛选条件，或使用上方快速添加。',
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
