const messageWidgetStorage = new LocalStorage();
const MESSAGE_CARD_BG: string = '#FFFFFF';
const MESSAGE_CARD_RADIUS: number = 20;
const MESSAGE_TITLE_COLOR: string = '#1F2937';
const MESSAGE_DESC_COLOR: string = '#6B7280';
const MESSAGE_PRIMARY_COLOR: string = '#4E8FDF';
const MESSAGE_BADGE_COLOR: string = '#FF3B30';

@Entry(messageWidgetStorage)
@Component
struct MessageWidgetCard {
  @LocalStorageProp('unreadCount') unreadCount: number = 0;
  @LocalStorageProp('latestMessage') latestMessage: string = '';

  build() {
    Column({ space: 12 }) {
      Row() {
        Row({ space: 8 }) {
          Image($r('app.media.message'))
            .width(20)
            .height(20)
          Text('消息提醒')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(MESSAGE_TITLE_COLOR)
        }
        Blank()
        if (this.unreadCount > 0) {
          Text(this.unreadCount > 99 ? '99+' : this.unreadCount.toString())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(MESSAGE_BADGE_COLOR)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
      }
      .width('100%')

      Text(this.unreadCount > 0 ? `${this.unreadCount} 条未读消息` : '暂无未读消息')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.unreadCount > 0 ? MESSAGE_PRIMARY_COLOR : '#9CA3AF')
        .width('100%')

      Text(this.latestMessage || '有新消息时会在这里提醒你')
        .fontSize(12)
        .fontColor(MESSAGE_DESC_COLOR)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(18)
        .width('100%')

      Blank()

      Row() {
        Text('点击查看消息')
          .fontSize(12)
          .fontColor(MESSAGE_PRIMARY_COLOR)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(MESSAGE_CARD_BG)
    .borderRadius(MESSAGE_CARD_RADIUS)
    .border({ width: 1, color: '#E2E8F0' })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetPage: 'message' }
      });
    })
  }
}
