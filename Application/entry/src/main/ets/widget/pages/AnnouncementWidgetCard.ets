const announcementWidgetStorage = new LocalStorage();
const ANNOUNCEMENT_CARD_RADIUS: number = 20;
const ANNOUNCEMENT_TITLE_COLOR: string = '#1F2937';
const ANNOUNCEMENT_DESC_COLOR: string = '#6B7280';
const ANNOUNCEMENT_ACCENT_COLOR: string = '#E07B39';

@Entry(announcementWidgetStorage)
@Component
struct AnnouncementWidgetCard {
  @LocalStorageProp('announcementTitle') announcementTitle: string = '';
  @LocalStorageProp('announcementId') announcementId: string = '';

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Image($r('app.media.startIcon'))
          .width(30)
          .height(30)
        Text('校园公告')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(ANNOUNCEMENT_TITLE_COLOR)
        Blank()
      }
      .width('100%')

      Text(this.announcementTitle || '暂无最新公告')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ANNOUNCEMENT_TITLE_COLOR)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(24)
        .width('100%')

      Text('重要通知同步展示')
        .fontSize(12)
        .fontColor(ANNOUNCEMENT_DESC_COLOR)
        .lineHeight(18)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Blank()

      Row() {
        Text('点击查看')
          .fontSize(12)
          .fontColor(ANNOUNCEMENT_ACCENT_COLOR)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#FFF8ED')
    .borderRadius(ANNOUNCEMENT_CARD_RADIUS)
    .border({ width: 1, color: '#F7DDBA' })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetPage: 'announcement', announcementId: this.announcementId }
      });
    })
  }
}
