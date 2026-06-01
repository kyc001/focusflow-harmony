@Entry
@Component
struct Splash {
  @State showContent: boolean = false;

  aboutToAppear() {
    setTimeout(() => {
      this.showContent = true;
    }, 100);

    setTimeout(() => {
      this.getUIContext().getRouter()
        .replaceUrl({ url: 'pages/Index' })
        .catch((err: Error) => {
          console.error(`Splash route failed: ${err.message}`);
        });
    }, 2500);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 160,
          colors: [['#4338CA', 0.0], ['#6D28D9', 0.5], ['#7C3AED', 1.0]]
        })

      Column() {
        Column() {
          Image($r('app.media.app_icon'))
            .width(80)
            .height(80)
            .borderRadius(20)
            .shadow({ radius: 20, color: '#40000000', offsetX: 0, offsetY: 8 })

          Text('知序')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 20 })

          Text('专注 · 整理 · 成长')
            .fontSize(14)
            .fontColor('#B0FFFFFF')
            .margin({ top: 8 })
            .letterSpacing(2)
        }
        .opacity(this.showContent ? 1 : 0)
        .scale({ x: this.showContent ? 1 : 0.8, y: this.showContent ? 1 : 0.8 })
        .animation({ duration: 600, curve: Curve.EaseOut })

        Column() {
          LoadingProgress()
            .width(28)
            .height(28)
            .color('#80FFFFFF')
            .margin({ top: 60 })

          Text('加载中...')
            .fontSize(12)
            .fontColor('#80FFFFFF')
            .margin({ top: 8 })
        }
        .opacity(this.showContent ? 1 : 0)
        .animation({ duration: 600, curve: Curve.EaseOut, delay: 300 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('本地优先 · 数据安全')
          .fontSize(11)
          .fontColor('#60FFFFFF')
          .letterSpacing(1)
      }
      .width('100%')
      .position({ x: 0, y: '90%' })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
