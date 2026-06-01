import webview from '@ohos.web.webview';
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
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  TRACK
} from '../utils/FocusDesignTokens';
import { ForestPlant, StatPoint } from '../models/FocusModels';
import { FocusSmallUiAsset, PlantAsset } from './FocusVisuals';

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

@Component
export struct ReviewView {
  @Prop recordCount: number = 0;
  @Prop viewportWidth: number = 390;
  @Prop includeWeb: boolean = true;
  private webController: webview.WebviewController = new webview.WebviewController();
  private reviewBridge: ReviewBridge = new ReviewBridge();

  build() {
    Column() {
      GridRow({
        columns: { xs: 4, sm: 4, md: 8, lg: 12 },
        gutter: { x: 10, y: 10 }
      }) {
        GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
          this.KpiCard('总专注', `${focusStore.totalFocusMinutes()}`, '分钟', 'timer')
        }
        GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
          this.KpiCard('完成率', `${Math.round(focusStore.completedPomodoros() * 100 / Math.max(1, this.recordCount))}`, '%', 'medal')
        }
        GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
          this.KpiCard('最长 streak', `${focusStore.bestStreakDays()}`, '天', 'heatmap')
        }
      }

      if (this.includeWeb) {
        this.WebReviewCard()
      }

      this.BarChartCard('本周学习时长', focusStore.weekFocusPoints(), 'bars')
      this.BarChartCard('项目时间占比', focusStore.projectFocusPoints(), 'sync')
      this.CompletionCard()
      this.HeatMapCard()
      this.ForestCard()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private WebReviewCard() {
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
      this.WebFallbackChart()
    }
    .reviewCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private WebFallbackChart() {
    Column() {
      Text('ArkTS 兜底视图')
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .margin({ bottom: 8 })
      Row() {
        ForEach(focusStore.weekFocusPoints(), (point: StatPoint) => {
          Column() {
            Text(`${point.value}`)
              .fontSize(10)
              .fontColor(TEXT_MUTED)
              .margin({ bottom: 5 })
            Column()
              .width(16)
              .height(Math.max(8, Math.min(78, point.value * 2 + 8)))
              .borderRadius(8)
              .backgroundColor(ACCENT)
              .linearGradient({
                angle: 90,
                colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
              })
              .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
            Text(point.label)
              .fontSize(10)
              .fontColor(TEXT_MUTED)
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .height(112)
          .justifyContent(FlexAlign.End)
          .alignItems(HorizontalAlign.Center)
        }, (point: StatPoint) => point.label)
      }
      .height(124)
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F7FAFF')
    .border({ width: 1, color: BORDER_SOFT })
    .borderRadius(12)
    .margin({ top: 10 })
  }

  @Builder
  private KpiCard(title: string, value: string, unit: string, icon: string) {
    Column() {
      Row() {
        FocusSmallUiAsset({ variant: icon, assetSize: 46 })
        Column() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ACCENT)
              .linearGradient({
                angle: 90,
                colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
              })
              .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
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
    .reviewCardStyleTight()
    .border({ width: { top: 3 }, color: { top: ACCENT_SOFT } })
  }

  @Builder
  private BarChartCard(title: string, points: StatPoint[], icon: string) {
    Column() {
      Row() {
        FocusSmallUiAsset({ variant: icon, assetSize: 42 })
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
                .linearGradient({
                  angle: 90,
                  colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
                })
                .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
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
    .reviewCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private CompletionCard() {
    Column() {
      Row() {
        FocusSmallUiAsset({ variant: 'shield', assetSize: 42 })
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
    .reviewCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private HeatMapCard() {
    Column() {
      Row() {
        FocusSmallUiAsset({ variant: 'heatmap', assetSize: 42 })
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
            .linearGradient({
              angle: 90,
              colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
            })
            .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
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
    .reviewCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private ForestCard() {
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
    .reviewCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private ForestRewardStrip() {
    Row() {
      Column() {
        Image($r('app.media.focus_reward_timer_token'))
          .reviewRewardAssetStyle()
        Text(`${focusStore.completedPomodoros()}`)
          .reviewRewardValueStyle()
        Text('番茄')
          .reviewRewardLabelStyle()
      }
      .reviewRewardTileStyle()

      Column() {
        Image($r('app.media.focus_reward_water'))
          .reviewRewardAssetStyle()
        Text(`${focusStore.streakDays()}`)
          .reviewRewardValueStyle()
        Text('连续天')
          .reviewRewardLabelStyle()
      }
      .reviewRewardTileStyle()
      .margin({ left: 8 })

      Column() {
        Image($r('app.media.focus_reward_stone_path'))
          .reviewRewardAssetStyle()
        Text(`${focusStore.unlockedPlants().length}`)
          .reviewRewardValueStyle()
        Text('解锁')
          .reviewRewardLabelStyle()
      }
      .reviewRewardTileStyle()
      .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  private PlantTile(plant: ForestPlant) {
    Column() {
      Stack() {
        Column()
          .width(62)
          .height(62)
          .borderRadius(16)
          .backgroundColor(this.isPlantUnlocked(plant) ? ACCENT_SOFT : SURFACE_ALT)
        PlantAsset({ plantId: plant.id, unlocked: this.isPlantUnlocked(plant) })
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
}

@Extend(Column)
function reviewCardStyle() {
  .width('100%')
  .padding(20)
  .backgroundColor(CARD_GLASS)
  .backdropBlur(CARD_GLASS_BLUR)
  .borderRadius(RADIUS_XL)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
}

@Extend(Column)
function reviewCardStyleTight() {
  .width('100%')
  .padding(16)
  .backgroundColor(CARD_GLASS)
  .backdropBlur(CARD_GLASS_BLUR)
  .borderRadius(RADIUS_LG)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_CARD_RADIUS, color: SHADOW_CARD_COLOR, offsetX: SHADOW_CARD_OFFSET_X, offsetY: SHADOW_CARD_OFFSET_Y })
}

@Extend(Image)
function reviewRewardAssetStyle() {
  .width(38)
  .height(38)
  .objectFit(ImageFit.Contain)
}

@Extend(Column)
function reviewRewardTileStyle() {
  .layoutWeight(1)
  .height(92)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .backgroundColor(CARD_SOFT)
  .border({ width: 1, color: BORDER_SOFT })
  .borderRadius(14)
}

@Extend(Text)
function reviewRewardValueStyle() {
  .fontSize(15)
  .fontWeight(FontWeight.Bold)
  .fontColor(TEXT_MAIN)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .margin({ top: 4 })
}

@Extend(Text)
function reviewRewardLabelStyle() {
  .fontSize(10)
  .fontColor(TEXT_MUTED)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .margin({ top: 2 })
}
