import { router, window } from '@kit.ArkUI';
import { ItemCard, ItemService } from '../services/ItemService';
import { ItemCardView } from './Card';

@Entry
@Component
export struct MyLikedPage {
  @State items: ItemCard[] = [];
  @State isLoading: boolean = true;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    this.loadItems();
  }

  private async loadItems(): Promise<void> {
    this.isLoading = true;
    try {
      const list = await ItemService.listLiked();
      this.items = list;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.text_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => { router.back() })

        Text('我的收藏')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#4E8FDF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.items.length === 0) {
        Column({ space: 8 }) {
          Text('❤️').fontSize(56).margin({ top: 60 })
          Text('暂无收藏物品')
            .fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('点赞过的物品会展示在这里')
            .fontSize(13).fontColor($r('app.color.text_hint'))
        }
        .layoutWeight(1)
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.items, (item: ItemCard) => {
            ListItem() {
              ItemCardView({ item: item })
            }
          }, (item: ItemCard): string => item.itemId.toString())
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: this.bottomHeight + 20 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
