@Entry
@Component
struct FocusCard {
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
            colors: [['#151D31', 0.0], ['#2B3552', 1.0]]
          })

        Column() {
          Row() {
            Column() {
              Text('知序')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('本地优先')
                .fontSize(9)
                .fontColor('#99FFFFFF')
                .margin({ top: 1 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('4 / 6')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#22FFFFFF')
              .borderRadius(8)
          }
          .width('100%')

          Text('今日 Top 3')
            .fontSize(10)
            .fontColor('#99FFFFFF')
            .margin({ top: 11, bottom: 6 })

          this.taskLine('HW4 报告复盘')
          this.taskLine('数据库索引总结')
          this.taskLine('协程 Demo 排练')

          Row() {
            Text('番茄进度')
              .fontSize(10)
              .fontColor('#99FFFFFF')
            Blank()
            Text('67%')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .margin({ top: 8 })

          Progress({ value: 67, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(5)
            .color('#4258C9')
            .backgroundColor('#22FFFFFF')
            .margin({ top: 4 })
        }
        .width('100%')
        .height('100%')
        .padding(15)
        .alignItems(HorizontalAlign.Start)
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
