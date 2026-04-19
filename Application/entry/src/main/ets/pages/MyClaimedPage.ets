import { router, window } from '@kit.ArkUI';
import { ClaimService } from '../services/ClaimService';
import { ClaimRequest } from '../model/ClaimRequest';

/**
 * 我的认领申请
 */
@Entry
@Component
export struct MyClaimedPage {
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;
  @State items: ClaimRequest[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    this.loadClaims();
  }

  private async loadClaims(): Promise<void> {
    this.isLoading = true;
    try {
      this.items = await ClaimService.listMine();
    } finally {
      this.isLoading = false;
    }
  }

  goBack(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletRightType', 'personal');
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

        Text('我的已认领')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      if (this.isLoading) {
        Column({ space: 8 }) {
          LoadingProgress().width(40).height(40).color('#4E8FDF')
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else if (this.items.length === 0) {
        Column({ space: 8 }) {
          Text('✅').fontSize(56).margin({ top: 80 })
          Text('暂无认领申请')
            .fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('提交过的认领申请将在此展示')
            .fontSize(13).fontColor($r('app.color.text_hint'))
        }
        .layoutWeight(1).width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.items, (item: ClaimRequest) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(item.itemTitle || `物品ID：${item.itemId}`)
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(item.status === 'pending' ? '待处理' : (item.status === 'approved' ? '已通过' : (item.status === 'rejected' ? '已驳回' : item.status)))
                    .fontSize(12)
                    .fontColor(item.status === 'pending' ? '#FF9500' : (item.status === 'approved' ? '#4CAF50' : '#999999'))
                }
                .width('100%')
                if (item.itemStatus) {
                  Text(`帖子状态：${item.itemStatus}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_disabled'))
                    .width('100%')
                }
                Text(item.description)
                  .fontSize(13)
                  .fontColor($r('app.color.text_hint'))
                  .width('100%')
                if (item.createTime) {
                  Text(item.createTime.toLocaleString())
                    .fontSize(12)
                    .fontColor($r('app.color.text_disabled'))
                    .width('100%')
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.bg_card'))
              .borderRadius(12)
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
