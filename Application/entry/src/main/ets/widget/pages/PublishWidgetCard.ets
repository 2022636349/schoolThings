const publishWidgetStorage = new LocalStorage();
const PUBLISH_CARD_RADIUS: number = 20;
const PUBLISH_TITLE_COLOR: string = '#1F2937';
const PUBLISH_DESC_COLOR: string = '#6B7280';
const PUBLISH_PRIMARY_COLOR: string = '#4E8FDF';

@Entry(publishWidgetStorage)
@Component
struct PublishWidgetCard {
  build() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('快速发布')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(PUBLISH_TITLE_COLOR)
          .width('100%')
        Text('失物 / 招领')
          .fontSize(12)
          .fontColor(PUBLISH_PRIMARY_COLOR)
          .width('100%')
      }
      .width('100%')

      Text('一键发布新的失物或招领信息')
        .fontSize(12)
        .fontColor(PUBLISH_DESC_COLOR)
        .lineHeight(18)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Blank()

      Row() {
        Text('立即发布')
          .fontSize(12)
          .fontColor(PUBLISH_PRIMARY_COLOR)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F0F7FF')
    .borderRadius(PUBLISH_CARD_RADIUS)
    .border({ width: 1, color: '#D9E8FB' })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetPage: 'post' }
      });
    })
  }
}
