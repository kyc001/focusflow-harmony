import { focusStore } from '../services/FocusStore';
import {
  ACCENT,
  ACCENT_SOFT,
  BORDER_SOFT,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  GLOW_BLUE,
  GRADIENT_HERO_1,
  GRADIENT_HERO_2,
  GRADIENT_HERO_3,
  RADIUS_XL,
  SHADOW_FLOAT_COLOR,
  SHADOW_FLOAT_OFFSET_X,
  SHADOW_FLOAT_OFFSET_Y,
  SHADOW_FLOAT_RADIUS,
  SPACING_LG,
  SPACING_XXL,
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  VIOLET_SOFT
} from '../utils/FocusDesignTokens';
import {
  ROUTE_RESOURCE_DETAIL,
  ROUTE_REVIEW_DETAIL,
  ROUTE_SETTINGS_DETAIL,
  ROUTE_SYNC_DETAIL
} from '../utils/FocusRoutes';
import { SoftIconBadge } from './FocusVisuals';

@Component
export struct ProfileView {
  @Consume('pathStack') navStack: NavPathStack;
  @Prop currentNickname: string = '';
  @Prop currentModeText: string = '';
  @Prop activeResourceCount: number = 0;
  @Prop recordCount: number = 0;
  onLogout: () => void = () => {};

  private openRoute(routeName: string): void {
    this.navStack.pushPathByName(routeName, null);
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: SPACING_LG }) {
          this.ProfileHeaderCard()
          this.ProfileMenuCard('复盘统计', '查看学习数据、完成率、项目占比', 'bars')
          this.ProfileMenuCard('学习资源库', `${this.activeResourceCount} 份活跃资料`, 'sync')
          this.ProfileMenuCard('云同步', '登录后端服务器，同步任务与番茄记录', 'cloud')
          this.ProfileMenuCard('设置', '专注时长、白噪音、AI 配置', 'settings')
        }
        .padding({ left: SPACING_LG, right: SPACING_LG, top: SPACING_XXL, bottom: SPACING_XXL })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private ProfileHeaderCard() {
    Column() {
      Row() {
        SoftIconBadge({ variant: 'local', badgeSize: 54, fill: SUCCESS_SOFT })
        Column() {
          Text(this.currentNickname.length === 0 ? '本地学习者' : this.currentNickname)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text(this.currentModeText)
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
        Column() {
          SoftIconBadge({ variant: 'heatmap', badgeSize: 34, fill: '#FFFFFF' })
          Text(`${focusStore.streakDays()} 天`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        this.ProfileSoftStat('总专注', `${focusStore.totalFocusMinutes()} 分`, 'timer')
        this.ProfileSoftStat('番茄', `${focusStore.completedPomodoros()} 个`, 'medal')
        this.ProfileSoftStat('完成率', `${Math.round(focusStore.completedPomodoros() * 100 / Math.max(1, this.recordCount))}%`, 'bars')
      }
      .width('100%')
      .margin({ top: 18 })

      Button('退出登录')
        .width('100%')
        .height(40)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#1AFFFFFF')
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 14 })
        .onClick(() => {
          this.onLogout();
        })
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 135,
      colors: [[GRADIENT_HERO_1, 0.0], [GRADIENT_HERO_2, 0.52], [GRADIENT_HERO_3, 1.0]]
    })
    .borderRadius(RADIUS_XL)
    .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
  }

  @Builder
  private ProfileSoftStat(label: string, value: string, icon: string) {
    Column() {
      SoftIconBadge({ variant: icon, badgeSize: 30, fill: '#FFFFFF' })
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 6 })
      Text(label)
        .fontSize(10)
        .fontColor('#DDE4FF')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(88)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#1AFFFFFF')
    .borderRadius(14)
  }

  @Builder
  private ProfileMenuCard(title: string, subtitle: string, icon: string) {
    Row() {
      SoftIconBadge({ variant: icon, badgeSize: 46, fill: title === '学习资源库' ? SUCCESS_SOFT : title === '云同步' ? '#E0F2FE' : title === '设置' ? ACCENT_SOFT : VIOLET_SOFT })
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Text(subtitle)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      Image($r('app.media.focus_ui_next_marker'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
        .opacity(0.4)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_GLASS)
    .backdropBlur(CARD_GLASS_BLUR)
    .borderRadius(16)
    .border({ width: 1, color: BORDER_SOFT })
    .shadow({ radius: 12, color: '#0B14260F', offsetX: 0, offsetY: 4 })
    .onClick(() => {
      if (title === '复盘统计') {
        this.openRoute(ROUTE_REVIEW_DETAIL);
      } else if (title === '学习资源库') {
        this.openRoute(ROUTE_RESOURCE_DETAIL);
      } else if (title === '云同步') {
        this.openRoute(ROUTE_SYNC_DETAIL);
      } else if (title === '设置') {
        this.openRoute(ROUTE_SETTINGS_DETAIL);
      }
    })
  }
}
