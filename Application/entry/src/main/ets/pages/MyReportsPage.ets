import { router, window } from '@kit.ArkUI';
import { ReportService } from '../services/ReportService';
import { Dispute } from '../model/Dispute';
import { MeteorOverlay } from '../components/MeteorOverlay';

@Entry
@Component
export struct MyReportsPage {
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;
  @State items: Dispute[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    this.loadReports();
  }

  private async loadReports(): Promise<void> {
    this.isLoading = true;
    try {
      this.items = await ReportService.listMine();
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      Column() {
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.text_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (AppStorage.get<boolean>('isTabletMode') === true) {
            AppStorage.setOrCreate('tabletRightType', 'none');
            AppStorage.setOrCreate('tabletRightParams', '');
            AppStorage.setOrCreate('tabletPrevRightType', 'none');
            AppStorage.setOrCreate('tabletPrevRightParams', '');
          } else {
            router.back();
          }
        })

        Text('我的异议')
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
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else if (this.items.length === 0) {
        Column({ space: 8 }) {
          Text('🛡').fontSize(56).margin({ top: 60 })
          Text('暂无举报记录')
            .fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('你提交的异议会显示在这里')
            .fontSize(13).fontColor($r('app.color.text_hint'))
        }
        .layoutWeight(1).width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.items, (item: Dispute) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(`目标ID：${item.itemId}`)
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(item.status === 'pending' ? '待处理' : '已处理')
                    .fontSize(12)
                    .fontColor(item.status === 'pending' ? '#FF9500' : '#4CAF50')
                }
                .width('100%')
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
        .layoutWeight(1).width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: this.bottomHeight + 20 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))

      MeteorOverlay({ suppressInTablet: true })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
