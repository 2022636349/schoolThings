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

  private statusText(status: string): string {
    if (status === 'pending') return '待处理';
    if (status === 'resolved') return '已处理';
    if (status === 'rejected') return '已驳回';
    return status || '待处理';
  }

  private statusColor(status: string): string {
    if (status === 'pending') return '#FF9500';
    if (status === 'resolved') return '#4CAF50';
    if (status === 'rejected') return '#FF4D4F';
    return '#8A8A8A';
  }

  private statusBgColor(status: string): string {
    if (status === 'pending') return 'rgba(255,149,0,0.12)';
    if (status === 'resolved') return 'rgba(76,175,80,0.12)';
    if (status === 'rejected') return 'rgba(255,77,79,0.12)';
    return 'rgba(138,138,138,0.12)';
  }

  private hasReviewResult(item: Dispute): boolean {
    return item.status === 'resolved' || item.status === 'rejected' || item.resolution.trim().length > 0;
  }

  private reviewResultText(item: Dispute): string {
    const text = item.resolution.trim();
    if (text.length > 0) return text;
    if (item.status === 'resolved') return '管理员已完成处理，请以帖子状态和账号数据变化为准。';
    if (item.status === 'rejected') return '管理员已驳回本次异议，暂不支持变更处理。';
    return '管理员正在核实，请耐心等待处理结果。';
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
                  Text(item.targetTitle ? item.targetTitle : `目标ID：${item.itemId}`)
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(this.statusText(item.status))
                    .fontSize(12)
                    .fontColor(this.statusColor(item.status))
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .backgroundColor(this.statusBgColor(item.status))
                    .borderRadius(10)
                }
                .width('100%')
                Text(`帖子ID：${item.itemId}`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_disabled'))
                  .width('100%')
                Text(item.description)
                  .fontSize(13)
                  .fontColor($r('app.color.text_hint'))
                  .width('100%')
                if (this.hasReviewResult(item)) {
                  Column({ space: 4 }) {
                    Text('处理结果')
                      .fontSize(12)
                      .fontColor($r('app.color.text_tertiary'))
                    Text(this.reviewResultText(item))
                      .fontSize(13)
                      .fontColor($r('app.color.text_primary'))
                      .width('100%')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                  .padding(10)
                  .backgroundColor($r('app.color.bg_secondary'))
                  .borderRadius(10)
                }
                if (item.createTime) {
                  Text(item.updateTime !== null && item.status !== 'pending'
                    ? `处理时间：${item.updateTime.toLocaleString()}`
                    : `提交时间：${item.createTime.toLocaleString()}`)
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
