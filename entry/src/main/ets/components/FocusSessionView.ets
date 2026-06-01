import {
  AMBIENT_OPTIONS,
  AmbientOption,
  ambientDisplayName,
  normalizeAmbientType
} from '../services/FocusAmbientService';
import { createDefaultSettings } from '../data/SeedData';
import {
  ACCENT,
  BORDER_SOFT,
  CARD_BG,
  CARD_GLASS,
  CARD_SHADOW_STRONG,
  CARD_SOFT,
  DANGER,
  FAINT_ON_DARK,
  GLOW_BLUE,
  GRADIENT_ACCENT_END,
  GRADIENT_ACCENT_START,
  GRADIENT_HERO_1,
  GRADIENT_HERO_2,
  GRADIENT_HERO_3,
  SHADOW_CARD_COLOR,
  SHADOW_CARD_OFFSET_X,
  SHADOW_CARD_OFFSET_Y,
  SHADOW_CARD_RADIUS,
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  TRACK,
  VIOLET,
  VIOLET_SOFT
} from '../utils/FocusDesignTokens';
import {
  AiCoachAdvice,
  AiCoachSettings,
  FocusSettings,
  FocusTask,
  PomodoroRecord,
  PomodoroStatus,
  TaskStatus
} from '../models/FocusModels';

const EMPTY_TASK: FocusTask = {
  id: 0,
  title: '专注任务',
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

const DEFAULT_SETTINGS: FocusSettings = createDefaultSettings();

const DEFAULT_ADVICE: AiCoachAdvice = {
  headline: '根据当前任务安排下一段专注。',
  nextAction: '选择一个任务开始。',
  sessionPlan: '先完成当前任务，再进入短休息。',
  risk: '避免频繁切换上下文。',
  source: '本地规则',
  estimatedMinutes: 25,
  confidence: 0,
  generatedAt: 0
};

const DEFAULT_AI_SETTINGS: AiCoachSettings = {
  enabled: false,
  endpoint: '',
  model: '',
  apiKey: ''
};

@Component
export struct FocusSessionContent {
  @Prop selectedTask: FocusTask = EMPTY_TASK;
  @Prop settings: FocusSettings = DEFAULT_SETTINGS;
  @Prop timerStatus: PomodoroStatus = PomodoroStatus.IDLE;
  @Prop remainingSeconds: number = 25 * 60;
  @Prop timerProgressValue: number = 0;
  @Prop focusStateText: string = '待开始';
  @Prop serviceMessage: string = '';
  @Prop interruptedCount: number = 0;
  @Prop aiAdvice: AiCoachAdvice = DEFAULT_ADVICE;
  @Prop aiSettings: AiCoachSettings = DEFAULT_AI_SETTINGS;
  @Prop aiEndpointInput: string = '';
  @Prop aiModelInput: string = '';
  @Prop aiApiKeyInput: string = '';
  @Prop aiLoading: boolean = false;
  @Prop aiSettingsMessage: string = '';
  @Prop focusSettingsMessage: string = '';
  @Prop maskedAiKey: string = '';
  @Prop records: PomodoroRecord[] = [];

  onStartPomodoro: () => void = () => {};
  onPausePomodoro: () => void = () => {};
  onCompletePomodoro: () => void = () => {};
  onInterruptPomodoro: () => void = () => {};
  onResetPomodoro: () => void = () => {};
  onRefreshAi: () => void = () => {};
  onOpenAiSettings: () => void = () => {};
  onToggleRemoteAi: () => void = () => {};
  onAiEndpointChange: (value: string) => void = () => {};
  onAiModelChange: (value: string) => void = () => {};
  onAiApiKeyChange: (value: string) => void = () => {};
  onSaveAiSettings: () => void = () => {};
  onDurationChange: (label: string, value: number) => void = () => {};
  onNoiseChange: (noise: string) => void = () => {};
  taskTitleForRecord: (taskId: number) => string = () => '专注任务';

  build() {
    GridRow({
      columns: { xs: 4, sm: 4, md: 8, lg: 12 },
      gutter: { x: 12, y: 12 }
    }) {
      GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 5 } }) {
        this.TimerCard()
      }
      GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 7 } }) {
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
          maskedAiKey: this.maskedAiKey,
          records: this.records,
          compactAiCard: true,
          showHistory: true,
          onRefreshAi: this.onRefreshAi,
          onOpenAiSettings: this.onOpenAiSettings,
          onToggleRemoteAi: this.onToggleRemoteAi,
          onAiEndpointChange: this.onAiEndpointChange,
          onAiModelChange: this.onAiModelChange,
          onAiApiKeyChange: this.onAiApiKeyChange,
          onSaveAiSettings: this.onSaveAiSettings,
          onDurationChange: this.onDurationChange,
          onNoiseChange: this.onNoiseChange,
          taskTitleForRecord: this.taskTitleForRecord
        })
      }
    }
  }

  private timeText(seconds: number): string {
    const minute: number = Math.floor(seconds / 60);
    const second: number = seconds % 60;
    return `${minute.toString().padStart(2, '0')}:${second.toString().padStart(2, '0')}`;
  }

  @Builder
  private TimerCard() {
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
          Text(this.selectedTask.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.focusStateText)
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
        Progress({ value: this.timerProgressValue, total: 100, type: ProgressType.Ring })
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
          Text(`${this.interruptedCount} 次中断`)
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
              this.onPausePomodoro();
            } else {
              this.onStartPomodoro();
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
            this.onCompletePomodoro();
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
            this.onInterruptPomodoro();
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
            this.onResetPomodoro();
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
      colors: [[GRADIENT_HERO_1, 0.0], [GRADIENT_HERO_2, 0.5], [GRADIENT_HERO_3, 1.0]]
    })
    .shadow({ radius: 30, color: CARD_SHADOW_STRONG, offsetX: 0, offsetY: 14 })
  }
}

@Component
export struct FocusSettingsPanel {
  @Prop settings: FocusSettings = DEFAULT_SETTINGS;
  @Prop aiAdvice: AiCoachAdvice = DEFAULT_ADVICE;
  @Prop aiSettings: AiCoachSettings = DEFAULT_AI_SETTINGS;
  @Prop aiEndpointInput: string = '';
  @Prop aiModelInput: string = '';
  @Prop aiApiKeyInput: string = '';
  @Prop aiLoading: boolean = false;
  @Prop aiSettingsMessage: string = '';
  @Prop focusSettingsMessage: string = '';
  @Prop maskedAiKey: string = '';
  @Prop records: PomodoroRecord[] = [];
  @Prop compactAiCard: boolean = true;
  @Prop showHistory: boolean = true;

  onRefreshAi: () => void = () => {};
  onOpenAiSettings: () => void = () => {};
  onToggleRemoteAi: () => void = () => {};
  onAiEndpointChange: (value: string) => void = () => {};
  onAiModelChange: (value: string) => void = () => {};
  onAiApiKeyChange: (value: string) => void = () => {};
  onSaveAiSettings: () => void = () => {};
  onDurationChange: (label: string, value: number) => void = () => {};
  onNoiseChange: (noise: string) => void = () => {};
  taskTitleForRecord: (taskId: number) => string = () => '专注任务';

  build() {
    Column() {
      this.AiCoachCard(this.compactAiCard)
      this.AiSettingsCard()
      this.SettingsCard()
      this.WhiteNoiseCard()
      if (this.showHistory) {
        this.HistoryCard()
      }
    }
    .width('100%')
  }

  @Builder
  private AiCoachCard(compact: boolean) {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_ai_orb'))
          .width(compact ? 40 : 48)
          .height(compact ? 40 : 48)
          .objectFit(ImageFit.Cover)
          .borderRadius(compact ? 12 : 14)
          .margin({ right: 12 })

        Column() {
          Row() {
            Text('AI 学习助手')
              .fontSize(compact ? 14 : 15)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
            Blank()
            if (this.aiSettings.apiKey.length > 0) {
              Text('已连接')
                .fontSize(10)
                .fontColor(SUCCESS)
                .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                .backgroundColor(SUCCESS_SOFT)
                .borderRadius(6)
            } else {
              Text('未配置')
                .fontSize(10)
                .fontColor(TEXT_MUTED)
                .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                .backgroundColor(SURFACE_ALT)
                .borderRadius(6)
            }
          }
          .width('100%')

          Text(this.aiAdvice.headline)
            .fontSize(compact ? 13 : 14)
            .fontColor(TEXT_SUB)
            .lineHeight(compact ? 18 : 20)
            .maxLines(compact ? 2 : 3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Button(this.aiLoading ? '刷新中...' : '刷新建议')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(ACCENT)
          .linearGradient({
            angle: 90,
            colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
          })
          .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.onRefreshAi();
          })
        Blank()
        Button('AI 设置')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(8)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.onOpenAiSettings();
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .panelCard()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private AiSettingsCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_settings_sliders'))
          .width(42)
          .height(42)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ right: 10 })
        Column() {
          Text('AI 接入')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('默认联网模型生成学习建议')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.aiSettings.enabled ? '远程开' : '待开启')
          .fontSize(11)
          .fontColor(this.aiSettings.enabled ? VIOLET : TEXT_MUTED)
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .backgroundColor(this.aiSettings.enabled ? VIOLET_SOFT : SURFACE_ALT)
          .borderRadius(9)
          .onClick(() => {
            this.onToggleRemoteAi();
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
          this.onAiEndpointChange(value);
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
          this.onAiModelChange(value);
        })

      TextInput({ placeholder: `API Key：${this.maskedAiKey}，留空保留`, text: this.aiApiKeyInput })
        .height(40)
        .backgroundColor(CARD_SOFT)
        .borderRadius(10)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 12, right: 12 })
        .fontSize(12)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.onAiApiKeyChange(value);
        })

      Row() {
        Button('保存配置')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ACCENT)
          .linearGradient({
            angle: 90,
            colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
          })
          .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
          .fontColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => {
            this.onSaveAiSettings();
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
            this.onToggleRemoteAi();
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
    .panelCard()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private SettingsCard() {
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
    .panelCard()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private SettingSlider(label: string, value: number, min: number, max: number) {
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
          this.onDurationChange(label, Math.round(changedValue));
        })
    }
    .width('100%')
    .margin({ top: 14 })
  }

  @Builder
  private WhiteNoiseCard() {
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
        ForEach(AMBIENT_OPTIONS, (option: AmbientOption) => {
          Column() {
            Text(option.label)
              .fontSize(12)
              .fontWeight(normalizeAmbientType(this.settings.noise) === option.id ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(normalizeAmbientType(this.settings.noise) === option.id ? '#FFFFFF' : TEXT_MAIN)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(option.description)
              .fontSize(10)
              .fontColor(normalizeAmbientType(this.settings.noise) === option.id ? '#E6FFFFFF' : TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
          .height(48)
          .width(112)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(normalizeAmbientType(this.settings.noise) === option.id ? ACCENT : SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 8, right: 8 })
          .margin({ right: 8, top: 12 })
          .onClick(() => {
            this.onNoiseChange(option.id);
          })
        }, (option: AmbientOption) => option.id)
      }
      .width('100%')
      Text(`当前音景：${ambientDisplayName(this.settings.noise)}。开始专注后使用 AVPlayer 循环播放 rawfile 本地音频。`)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 12 })
    }
    .panelCard()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private HistoryCard() {
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
            Text(this.taskTitleForRecord(record.taskId))
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
    .panelCard()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }
}

@Extend(Column)
function panelCard() {
  .width('100%')
  .padding(16)
  .backgroundColor(CARD_GLASS)
  .borderRadius(18)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_CARD_RADIUS, color: SHADOW_CARD_COLOR, offsetX: SHADOW_CARD_OFFSET_X, offsetY: SHADOW_CARD_OFFSET_Y })
}
