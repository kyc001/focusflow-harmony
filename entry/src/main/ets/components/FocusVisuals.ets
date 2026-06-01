import {
  ACCENT,
  BORDER_SOFT,
  CARD_GLASS,
  SUCCESS,
  SURFACE_ALT,
  TEXT_DIM,
  TEXT_MUTED,
  TEXT_SUB
} from '../utils/FocusDesignTokens';

@Component
export struct TabMinimalIcon {
  @Prop index: number = 0;
  @Prop active: boolean = false;

  build() {
    if (this.index === 0) {
      Column({ space: 3 }) {
        Row({ space: 3 }) {
          Column()
            .width(7)
            .height(7)
            .borderRadius(3.5)
            .backgroundColor(this.active ? ACCENT : TEXT_DIM)
          Column()
            .width(7)
            .height(7)
            .borderRadius(3.5)
            .backgroundColor(this.active ? ACCENT : TEXT_DIM)
            .opacity(this.active ? 0.68 : 0.46)
        }
        Row({ space: 3 }) {
          Column()
            .width(7)
            .height(7)
            .borderRadius(3.5)
            .backgroundColor(this.active ? ACCENT : TEXT_DIM)
            .opacity(this.active ? 0.68 : 0.46)
          Column()
            .width(7)
            .height(7)
            .borderRadius(3.5)
            .backgroundColor(this.active ? SUCCESS : TEXT_DIM)
        }
      }
      .width(26)
      .height(23)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.index === 1) {
      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor(this.active ? SUCCESS : TEXT_DIM)
          Column()
            .width(15)
            .height(3)
            .borderRadius(2)
            .backgroundColor(this.active ? ACCENT : TEXT_DIM)
        }
        Row({ space: 4 }) {
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor(this.active ? SUCCESS : TEXT_DIM)
            .opacity(this.active ? 0.7 : 0.48)
          Column()
            .width(19)
            .height(3)
            .borderRadius(2)
            .backgroundColor(this.active ? ACCENT : TEXT_DIM)
            .opacity(this.active ? 0.72 : 0.48)
        }
        Row({ space: 4 }) {
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor(this.active ? SUCCESS : TEXT_DIM)
            .opacity(this.active ? 0.45 : 0.34)
          Column()
            .width(11)
            .height(3)
            .borderRadius(2)
            .backgroundColor(this.active ? ACCENT : TEXT_DIM)
            .opacity(this.active ? 0.5 : 0.34)
        }
      }
      .width(26)
      .height(23)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
    } else {
      Column() {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.active ? SUCCESS : TEXT_DIM)
        Column()
          .width(18)
          .height(8)
          .borderRadius(6)
          .backgroundColor(this.active ? ACCENT : TEXT_DIM)
          .opacity(this.active ? 0.76 : 0.5)
          .margin({ top: 3 })
      }
      .width(26)
      .height(23)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}

@Component
export struct FocusSmallUiAsset {
  @Prop variant: string = 'inbox';
  @Prop assetSize: number = 32;

  build() {
    if (this.variant === 'inbox') {
      Image($r('app.media.focus_ui_empty_inbox'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'quick') {
      Image($r('app.media.focus_ui_quick_add'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'marker') {
      Image($r('app.media.focus_ui_next_marker'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'priority') {
      Image($r('app.media.focus_ui_priority_flag'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'ai') {
      Image($r('app.media.focus_ui_ai_orb'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'local') {
      Image($r('app.media.focus_ui_local_cube'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'remote') {
      Image($r('app.media.focus_ui_remote_cloud'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'timer') {
      Image($r('app.media.focus_ui_timer_token'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'pause') {
      Image($r('app.media.focus_ui_pause_resume'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'bell') {
      Image($r('app.media.focus_ui_notification_bell'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'medal') {
      Image($r('app.media.focus_ui_completion_medal'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'shield') {
      Image($r('app.media.focus_ui_risk_shield'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'bars') {
      Image($r('app.media.focus_ui_review_bars'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'heatmap') {
      Image($r('app.media.focus_ui_heatmap_grid'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'settings') {
      Image($r('app.media.focus_ui_settings_sliders'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'sync') {
      Image($r('app.media.focus_ui_sync_bridge'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else if (this.variant === 'cloud') {
      Image($r('app.media.focus_ui_remote_cloud'))
        .focusVisualMicroAssetStyle(this.assetSize)
    } else {
      Image($r('app.media.focus_ui_empty_inbox'))
        .focusVisualMicroAssetStyle(this.assetSize)
    }
  }
}

@Component
export struct SoftIconBadge {
  @Prop variant: string = 'inbox';
  @Prop badgeSize: number = 36;
  @Prop fill: string = SURFACE_ALT;

  build() {
    Stack() {
      Column()
        .width(this.badgeSize)
        .height(this.badgeSize)
        .borderRadius(Math.round(this.badgeSize / 3))
        .backgroundColor(this.fill)
        .border({ width: 1, color: BORDER_SOFT })
      FocusSmallUiAsset({ variant: this.variant, assetSize: Math.max(18, Math.round(this.badgeSize * 0.64)) })
    }
    .width(this.badgeSize)
    .height(this.badgeSize)
  }
}

@Component
export struct EmptyState {
  @Prop title: string = '';
  @Prop caption: string = '';
  @Prop variant: string = 'inbox';

  build() {
    Column() {
      FocusSmallUiAsset({ variant: this.variant, assetSize: 76 })
      Text(this.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .margin({ top: 8 })
      Text(this.caption)
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
}

@Component
export struct LoginFeaturePill {
  @Prop variant: string = 'local';
  @Prop title: string = '';

  build() {
    Row() {
      SoftIconBadge({ variant: this.variant, badgeSize: 28, fill: '#FFFFFF' })
      Text(this.title)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .margin({ left: 6 })
    }
    .layoutWeight(1)
    .height(42)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(CARD_GLASS)
    .border({ width: 1, color: BORDER_SOFT })
    .borderRadius(14)
  }
}

@Component
export struct PlantAsset {
  @Prop plantId: number = 0;
  @Prop unlocked: boolean = false;

  build() {
    if (this.plantId === 1) {
      Image($r('app.media.focus_plant_seed'))
        .focusVisualPlantAssetStyle(this.unlocked)
    } else if (this.plantId === 2) {
      Image($r('app.media.focus_plant_ginkgo'))
        .focusVisualPlantAssetStyle(this.unlocked)
    } else if (this.plantId === 3) {
      Image($r('app.media.focus_plant_pine'))
        .focusVisualPlantAssetStyle(this.unlocked)
    } else if (this.plantId === 4) {
      Image($r('app.media.focus_plant_bloom'))
        .focusVisualPlantAssetStyle(this.unlocked)
    } else if (this.plantId === 5) {
      Image($r('app.media.focus_plant_maple'))
        .focusVisualPlantAssetStyle(this.unlocked)
    } else if (this.plantId === 6) {
      Image($r('app.media.focus_plant_forest'))
        .focusVisualPlantAssetStyle(this.unlocked)
    } else {
      Image($r('app.media.focus_reward_locked_seed'))
        .focusVisualPlantAssetStyle(false)
    }
  }
}

@Extend(Image)
function focusVisualMicroAssetStyle(size: number) {
  .width(size)
  .height(size)
  .objectFit(ImageFit.Cover)
  .borderRadius(Math.round(size / 4))
}

@Extend(Image)
function focusVisualPlantAssetStyle(isUnlocked: boolean) {
  .width(58)
  .height(58)
  .objectFit(ImageFit.Contain)
  .opacity(isUnlocked ? 1 : 0.34)
}
