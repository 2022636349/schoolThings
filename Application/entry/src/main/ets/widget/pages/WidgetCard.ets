const widgetStorage = new LocalStorage();

@Entry(widgetStorage)
@Component
struct WidgetCard {
  @LocalStorageProp('unreadCount') unreadCount: number = 0;
  @LocalStorageProp('latestMessage') latestMessage: string = '';

  build() {
    Column() {
      // ── 顶部：标题栏 ──
      Row() {
        Image($r('app.media.startIcon'))
          .width(22)
          .height(22)
          .borderRadius(4)
        Text('校园失物招领')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
        Blank()
        if (this.unreadCount > 0) {
          Text(this.unreadCount.toString())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF3B30')
            .borderRadius(9)
            .width(18)
            .height(18)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 6 })

      // ── 中部：消息预览区 ──
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Image($r('app.media.message'))
            .width(16)
            .height(16)
          Text(this.unreadCount > 0 ? `${this.unreadCount} 条新消息` : '暂无新消息')
            .fontSize(13)
            .fontColor(this.unreadCount > 0 ? '#4E8FDF' : '#999999')
        }
        .width('100%')

        if (this.latestMessage) {
          Text(this.latestMessage)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#F5F8FC')
      .borderRadius(10)
      .margin({ left: 14, right: 14, top: 4 })
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetPage: 'message' }
        });
      })

      Blank()

      // ── 底部：快速发布按钮 ──
      Row() {
        Text('+')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text(' 快速发布寻物')
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .width('85%')
      .height(34)
      .backgroundColor('#4E8FDF')
      .borderRadius(17)
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 12 })
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetPage: 'post' }
        });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
