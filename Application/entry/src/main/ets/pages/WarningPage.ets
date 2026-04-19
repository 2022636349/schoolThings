import { router, window } from '@kit.ArkUI';
import { WarningService } from '../services/WarningService';
import { ItemCard } from '../services/ItemService';

/**
 * 失物处理预警公示页
 */
@Entry
@Component
export struct WarningPage {
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;
  @State items: ItemCard[] = [];
  @State isLoading: boolean = true;

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
      this.items = await WarningService.list(20);
    } finally {
      this.isLoading = false;
    }
  }

  goBack(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletRightType', 'none');
    } else {
      router.back();
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
        .onClick(() => { this.goBack() })

        Text('失物处理预警')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      Row({ space: 8 }) {
        Text('⚠️').fontSize(16)
        Text('此处公示超过 60 天无人认领、已移交学校处置的物品；公示 15 天后将正式下架。')
          .fontSize(12).fontColor('#A46615').layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor('#FFF6E5')

      if (this.isLoading) {
        Column({ space: 8 }) {
          LoadingProgress().width(40).height(40).color('#4E8FDF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.items.length === 0) {
        Column({ space: 8 }) {
          Text('⏳').fontSize(56).margin({ top: 60 })
          Text('暂无公示物品')
            .fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('符合条件的物品将在此展示')
            .fontSize(13).fontColor($r('app.color.text_hint'))
        }
        .layoutWeight(1)
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: ItemCard) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.text || '预警物品')
                  .fontSize(15).fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 10 }) {
                  Text(item.category || '其他')
                    .fontSize(12).fontColor('#A46615')
                  Text(item.publishTime)
                    .fontSize(12).fontColor($r('app.color.text_hint'))
                }
                .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.bg_card'))
              .borderRadius(12)
              .onClick(() => {
                const p: Record<string, Object> = {};
                p['itemId'] = item.itemId;
                p['type'] = item.type;
                p['text'] = item.text;
                p['publishTime'] = item.publishTime;
                p['publishId'] = item.publishId;
                p['publisherName'] = item.publisherName;
                p['publisherAvatar'] = item.publisherAvatar;
                p['mediaList'] = JSON.stringify(item.mediaList);
                p['category'] = item.category;
                p['likeCount'] = item.likeCount;
                p['status'] = item.status;
                p['claimedBy'] = item.claimedBy || '';
                p['lostTime'] = item.lostTime;
                router.pushUrl({ url: 'pages/DetailPage', params: p });
              })
            }
          })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: this.bottomHeight + 20 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
