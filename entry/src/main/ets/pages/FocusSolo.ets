import { common } from '@kit.AbilityKit';
import { FocusSettings } from '../models/FocusModels';
import { focusDatabase } from '../services/FocusDatabase';
import { FocusBackgroundService, FocusNotificationService } from '../services/FocusNativeServices';
import { focusSettingsService } from '../services/FocusSettingsService';
import { focusStore } from '../services/FocusStore';
import {
  ACCENT,
  BORDER_SOFT,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  SHADOW_FLOAT_COLOR,
  SUCCESS,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  WARNING
} from '../utils/FocusDesignTokens';
import { formatTimerText } from '../utils/FocusFormatters';

const DEFAULT_FOCUS_SECONDS: number = 25 * 60;
const FOCUS_BG_START: string = '#F7F5EC';
const FOCUS_BG_MID: string = '#EAF5F2';
const FOCUS_BG_END: string = '#EEF2FF';
const CORAL: string = '#F2766B';
const GLASS_BORDER: string = '#BFFFFFFF';

@Entry
@Component
struct FocusSolo {
  @StorageProp('focus.taskId') taskId: number = 1;
  @StorageProp('focus.taskTitle') taskTitle: string = '专注任务';
  @State focusSeconds: number = DEFAULT_FOCUS_SECONDS;
  @State remainingSeconds: number = DEFAULT_FOCUS_SECONDS;
  @State running: boolean = false;
  @State message: string = '独立 FocusAbility 已就绪';
  private timerId: number = -1;

  aboutToAppear() {
    this.initLocalStore();
  }

  aboutToDisappear() {
    this.stop();
  }

  private async initLocalStore(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    try {
      await focusDatabase.init(context);
      await focusStore.refresh();
    } catch (err) {
      this.message = '本地记录暂未连接，完成后保留通知提醒';
    }

    try {
      await focusSettingsService.init(context);
      const settings: FocusSettings = await focusSettingsService.loadSettings();
      this.applyFocusSettings(settings);
    } catch (err) {
      this.focusSeconds = DEFAULT_FOCUS_SECONDS;
      if (!this.running) {
        this.remainingSeconds = DEFAULT_FOCUS_SECONDS;
      }
    }
  }

  private start(): void {
    if (this.running) {
      return;
    }
    if (this.remainingSeconds <= 0) {
      this.remainingSeconds = this.focusSeconds;
    }
    this.running = true;
    this.message = FocusBackgroundService.startPomodoroGuard();
    this.timerId = setInterval(() => {
      if (this.remainingSeconds <= 1) {
        this.finish();
        return;
      }
      this.remainingSeconds--;
    }, 1000);
  }

  private pause(): void {
    this.running = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private stop(): void {
    this.pause();
    FocusBackgroundService.stopPomodoroGuard();
  }

  private finish(): void {
    this.stop();
    this.remainingSeconds = this.focusSeconds;
    this.message = '番茄完成，正在写入本地记录';
    this.persistCompletion();
    FocusNotificationService.publishBasic('番茄完成', this.taskTitle);
  }

  private async persistCompletion(): Promise<void> {
    try {
      if (!focusDatabase.isReady()) {
        const context = getContext(this) as common.UIAbilityContext;
        await focusDatabase.init(context);
      }
      await focusStore.refresh();
      await focusStore.recordPomodoro(this.taskId, this.focusSeconds, true, '');
      this.message = '番茄完成，已写入本地记录';
    } catch (err) {
      this.message = '番茄完成，本地记录稍后可在主页补同步';
    }
  }

  private reset(): void {
    this.stop();
    this.remainingSeconds = this.focusSeconds;
    this.message = '已重置，准备开始下一段专注';
  }

  private applyFocusSettings(settings: FocusSettings): void {
    const focusMinutes: number = Math.max(10, Math.min(60, settings.focusMinutes));
    this.focusSeconds = focusMinutes * 60;
    if (!this.running) {
      this.remainingSeconds = this.focusSeconds;
    }
  }

  private progressValue(): number {
    return Math.max(0, this.focusSeconds - this.remainingSeconds);
  }

  private statusText(): string {
    return this.running ? '沉浸中' : '待开始';
  }

  private statusColor(): string {
    return this.running ? SUCCESS : ACCENT;
  }

  private elapsedText(): string {
    const elapsedSeconds: number = Math.max(0, this.focusSeconds - this.remainingSeconds);
    const elapsedMinutes: number = Math.floor(elapsedSeconds / 60);
    return `${elapsedMinutes} 分钟`;
  }

  @Builder
  HeaderHero() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_timer_token'))
          .width(52)
          .height(52)
          .objectFit(ImageFit.Cover)
          .borderRadius(16)
          .shadow({ radius: 18, color: '#2431A69A', offsetX: 0, offsetY: 8 })
          .margin({ right: 12 })
        Column() {
          Text('知序沉浸模式')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MUTED)
          Text('只做这一件事')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
            .margin({ top: 5 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.statusText())
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.statusColor())
          .padding({ left: 11, right: 11, top: 6, bottom: 6 })
          .backgroundColor('#F2FFFFFF')
          .border({ width: 1, color: GLASS_BORDER })
          .borderRadius(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column() {
        Text('当前任务')
          .fontSize(11)
          .fontColor(TEXT_MUTED)
        Text(this.taskTitle)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
          .lineHeight(27)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
        Row() {
          this.InfoChip('本地番茄记录')
          this.InfoChip(`${Math.round(this.focusSeconds / 60)} 分钟节奏`)
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .width('100%')
      .padding(18)
      .backgroundColor('#D9FFFFFF')
      .backdropBlur(CARD_GLASS_BLUR)
      .border({ width: 1, color: GLASS_BORDER })
      .borderRadius(22)
      .shadow({ radius: 20, color: '#1A253D18', offsetX: 0, offsetY: 10 })
      .margin({ top: 24 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InfoChip(text: string) {
    Text(text)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(TEXT_SUB)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#F2F7F4')
      .borderRadius(11)
      .margin({ right: 8 })
  }

  @Builder
  TimerPanel() {
    Column() {
      Stack() {
        Progress({ value: this.progressValue(), total: this.focusSeconds, type: ProgressType.Ring })
          .width(258)
          .height(258)
          .color(this.statusColor())
          .backgroundColor('#1F4258C9')
          .style({ strokeWidth: 13 })
        Column() {
          Image($r('app.media.focus_plant_seedling'))
            .width(54)
            .height(54)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 4 })
          Text(formatTimerText(this.remainingSeconds))
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text(this.running ? '把这一段留给当前任务' : '准备好后开始')
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .margin({ top: 7 })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .height(276)
      .width('100%')
      .margin({ top: 2 })

      Row() {
        this.TimerMetric('已过', this.elapsedText(), ACCENT)
        this.TimerMetric('剩余', formatTimerText(this.remainingSeconds), CORAL)
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Image($r('app.media.focus_ui_local_cube'))
          .width(30)
          .height(30)
          .objectFit(ImageFit.Cover)
          .borderRadius(9)
          .margin({ right: 9 })
        Text(this.message)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .lineHeight(17)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor('#F4F7FB')
      .borderRadius(14)
      .margin({ top: 14 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .backgroundColor(CARD_GLASS)
    .backdropBlur(CARD_GLASS_BLUR)
    .border({ width: 1, color: BORDER_SOFT })
    .borderRadius(28)
    .shadow({ radius: 28, color: SHADOW_FLOAT_COLOR, offsetX: 0, offsetY: 14 })
    .margin({ top: 18 })
  }

  @Builder
  TimerMetric(label: string, value: string, tint: string) {
    Column() {
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_MAIN)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(10)
        .fontColor(TEXT_MUTED)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F8FAFC')
    .border({ width: 1, color: tint })
    .borderRadius(16)
    .margin({ right: 8 })
  }

  @Builder
  ActionPanel() {
    Column() {
      Row() {
        Button(this.running ? '暂停' : '开始')
          .height(48)
          .layoutWeight(1)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.running ? WARNING : SUCCESS)
          .fontColor('#FFFFFF')
          .borderRadius(15)
          .shadow({ radius: 14, color: this.running ? '#30F2766B' : '#3020A879', offsetX: 0, offsetY: 8 })
          .onClick(() => {
            if (this.running) {
              this.pause();
            } else {
              this.start();
            }
          })
        Button('完成')
          .height(48)
          .layoutWeight(1)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(TEXT_MAIN)
          .fontColor('#FFFFFF')
          .borderRadius(15)
          .margin({ left: 10 })
          .onClick(() => {
            this.finish();
          })
      }
      .width('100%')

      Button('重置这一段')
        .height(42)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#E9EEF6')
        .fontColor(TEXT_SUB)
        .borderRadius(14)
        .margin({ top: 10 })
        .onClick(() => {
          this.reset();
        })
    }
    .width('100%')
    .margin({ top: 16 })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [[FOCUS_BG_START, 0.0], [FOCUS_BG_MID, 0.48], [FOCUS_BG_END, 1.0]]
        })

      Column() {
        Image($r('app.media.focus_ai_hero'))
          .width('100%')
          .height(310)
          .objectFit(ImageFit.Cover)
          .opacity(0.16)
        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      Scroll() {
        Row() {
          Column() {
            this.HeaderHero()
            this.TimerPanel()
            this.ActionPanel()

            Text('完成后会写入本地番茄记录，回到主页即可用于复盘。')
              .fontSize(11)
              .fontColor(TEXT_MUTED)
              .lineHeight(17)
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ top: 18 })
          }
          .width('100%')
          .constraintSize({ maxWidth: 440 })
          .padding({ left: 22, right: 22, top: 52, bottom: 30 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}
