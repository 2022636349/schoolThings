const hotItemWidgetStorage = new LocalStorage();
const HOT_CARD_RADIUS: number = 20;
const HOT_TITLE_COLOR: string = '#1F2937';
const HOT_DESC_COLOR: string = '#6B7280';
const HOT_PRIMARY_COLOR: string = '#4E8FDF';

@Entry(hotItemWidgetStorage)
@Component
struct HotItemWidgetCard {
  @LocalStorageProp('hotTitle') hotTitle: string = '';
  @LocalStorageProp('hotItemId') hotItemId: string = '';

  build() {
    Column({ space: 12 }) {
      Row() {
        Row({ space: 6 }) {
          // Text('🔥')
          //   .fontSize(18)
          Text('热门推荐')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(HOT_TITLE_COLOR)
        }
        Blank()
      }
      .width('100%')

      Text(this.hotTitle || '暂无热门物品')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(HOT_TITLE_COLOR)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(22)
        .width('100%')

      Text('查看当前最受关注的失物招领')
        .fontSize(12)
        .fontColor(HOT_DESC_COLOR)
        .lineHeight(18)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Blank()

      Row() {
        Text('点击查看')
          .fontSize(12)
          .fontColor(HOT_PRIMARY_COLOR)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F4F8FF')
    .borderRadius(HOT_CARD_RADIUS)
    .border({ width: 1, color: '#DCE7FB' })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetPage: 'hot', hotItemId: this.hotItemId }
      });
    })
  }
}
