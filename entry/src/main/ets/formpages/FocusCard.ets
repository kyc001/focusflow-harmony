@Entry
@Component
struct FocusCard {
  @State title: string = '知序 今日';
  @State subtitle: string = '本地学习闭环';
  @State progress: string = '4/6 番茄';
  @State task1: string = 'HW4 报告复盘';
  @State task2: string = '数据库索引总结';
  @State task3: string = '协程 Demo 排练';
  @State isCompact: boolean = false;

  build() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        target: 'focus'
      }
    }) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 160,
            colors: [['#4338CA', 0.0], ['#6D28D9', 0.5], ['#7C3AED', 1.0]]
          })

        Column() {
          Row() {
            Column() {
              Text(this.title)
                .fontSize(this.isCompact ? 14 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text(this.subtitle)
                .fontSize(this.isCompact ? 8 : 9)
                .fontColor('#99FFFFFF')
                .margin({ top: 1 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(this.progress)
              .fontSize(this.isCompact ? 11 : 12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#22FFFFFF')
              .borderRadius(8)
          }
          .width('100%')

          if (!this.isCompact) {
            Text('今日 Top 3')
              .fontSize(10)
              .fontColor('#99FFFFFF')
              .margin({ top: 11, bottom: 6 })

            this.taskLine(this.task1)
            this.taskLine(this.task2)
            this.taskLine(this.task3)
          }

          Row() {
            Text('番茄进度')
              .fontSize(this.isCompact ? 9 : 10)
              .fontColor('#99FFFFFF')
            Blank()
            Text(this.progress.split('/')[0] + '%')
              .fontSize(this.isCompact ? 10 : 11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .margin({ top: this.isCompact ? 6 : 8 })

          Progress({ value: 67, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(this.isCompact ? 4 : 5)
            .color('#818CF8')
            .backgroundColor('#22FFFFFF')
            .margin({ top: 4 })
        }
        .width('100%')
        .height('100%')
        .padding(this.isCompact ? 12 : 15)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(this.isCompact ? FlexAlign.SpaceBetween : FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  taskLine(title: string) {
    Row() {
      Column()
        .width(3)
        .height(10)
        .borderRadius(2)
        .backgroundColor('#80FFFFFF')
      Text(title)
        .fontSize(11)
        .fontColor('#D6FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 2, bottom: 2 })
    .margin({ bottom: 3 })
  }
}
