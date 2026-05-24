import { common } from '@kit.AbilityKit';
import { focusDatabase } from '../services/FocusDatabase';
import { FocusBackgroundService, FocusNotificationService } from '../services/FocusNativeServices';
import { focusStore } from '../services/FocusStore';

const TEXT_MUTED: string = '#7A8398';
const ACCENT: string = '#4258C9';
const DEEP: string = '#151D31';
const DEEP_3: string = '#2B3552';
const FAINT_ON_DARK: string = '#7A8299';

@Entry
@Component
struct FocusSolo {
  @StorageProp('focus.taskId') taskId: number = 1;
  @StorageProp('focus.taskTitle') taskTitle: string = '专注任务';
  @State remainingSeconds: number = 25 * 60;
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
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await focusDatabase.init(context);
      await focusStore.refresh();
    } catch (err) {
      this.message = '本地记录暂未连接，完成后保留通知提醒';
    }
  }

  private start(): void {
    if (this.running) {
      return;
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
    this.remainingSeconds = 25 * 60;
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
      await focusStore.recordPomodoro(this.taskId, 25 * 60, true, '');
      this.message = '番茄完成，已写入本地记录';
    } catch (err) {
      this.message = '番茄完成，本地记录稍后可在主页补同步';
    }
  }

  private reset(): void {
    this.stop();
    this.remainingSeconds = 25 * 60;
    this.message = '已重置，准备开始下一段专注';
  }

  private timeText(seconds: number): string {
    const minute: number = Math.floor(seconds / 60);
    const second: number = seconds % 60;
    return `${minute < 10 ? '0' : ''}${minute}:${second < 10 ? '0' : ''}${second}`;
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 160,
          colors: [[DEEP, 0.0], [DEEP_3, 1.0]]
        })

      Column() {
        Row() {
          Column() {
            Text('Focus 沉浸模式')
              .fontSize(11)
              .fontColor('#99FFFFFF')
              .letterSpacing(2)
            Text('只做这一件事')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Text(this.running ? '运行中' : '待开始')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#1AFFFFFF')
            .borderRadius(10)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#10FFFFFF')
        .borderRadius(14)

        Column() {
          Text('当前任务')
            .fontSize(11)
            .fontColor('#99FFFFFF')
          Text(this.taskTitle)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(18)
        .backgroundColor('#14FFFFFF')
        .borderRadius(16)
        .margin({ top: 20 })

        Stack() {
          Progress({ value: 25 * 60 - this.remainingSeconds, total: 25 * 60, type: ProgressType.Ring })
            .width(236)
            .height(236)
            .color(ACCENT)
            .backgroundColor('#22FFFFFF')
            .style({ strokeWidth: 10 })
          Column() {
            Text(this.timeText(this.remainingSeconds))
              .fontSize(54)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text(this.running ? '沉浸中' : '准备开始')
              .fontSize(12)
              .fontColor('#B0FFFFFF')
              .margin({ top: 6 })
          }
        }
        .height(244)
        .margin({ top: 28 })

        Text('完成后会写入本地番茄记录，回到主页即可用于复盘。')
          .fontSize(11)
          .fontColor('#CCFFFFFF')
          .lineHeight(16)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#10FFFFFF')
          .borderRadius(10)
          .width('100%')
          .margin({ top: 2 })

        Row() {
          Button(this.running ? '暂停' : '开始')
            .height(46)
            .layoutWeight(1)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(this.running ? '#26FFFFFF' : ACCENT)
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .onClick(() => {
              if (this.running) {
                this.pause();
              } else {
                this.start();
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
              this.finish();
            })
        }
        .width('100%')
        .margin({ top: 24 })

        Button('重置这一段')
          .height(40)
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#14FFFFFF')
          .fontColor('#CCFFFFFF')
          .borderRadius(12)
          .margin({ top: 10 })
          .onClick(() => {
            this.reset();
          })

        Text(this.message)
          .fontSize(11)
          .fontColor(FAINT_ON_DARK)
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 18 })
      }
      .width('100%')
      .constraintSize({ maxWidth: 440 })
      .padding(24)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }
}
