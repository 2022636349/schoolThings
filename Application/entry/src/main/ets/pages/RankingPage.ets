import { router, window } from '@kit.ArkUI';
import { RankingService, RankingUser } from '../services/RankingService';

/**
 * 表彰排行页
 */
@Entry
@Component
export struct RankingPage {
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;
  @State items: RankingUser[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    this.loadRanking();
  }

  private async loadRanking(): Promise<void> {
    this.isLoading = true;
    try {
      this.items = await RankingService.list(10);
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

        Text('表彰排行')
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
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.items.length === 0) {
        Column({ space: 8 }) {
          Text('🏆').fontSize(64).margin({ top: 80 })
          Text('暂无排行数据')
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('热心榜数据会在用户互动后生成')
            .fontSize(13).fontColor($r('app.color.text_hint'))
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: RankingUser, index: number) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(`${index + 1}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(index < 3 ? '#E07B39' : '#4E8FDF')
                  .width(28)
                if (item.avatar) {
                  Image(item.avatar)
                    .width(44).height(44).borderRadius(22)
                    .objectFit(ImageFit.Cover)
                } else {
                  Stack() {
                    Circle().width(44).height(44).fill('#4E8FDF').opacity(0.12)
                    Text(item.name?.charAt(0) || '?')
                      .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#4E8FDF')
                  }
                  .width(44).height(44).borderRadius(22)
                }
                Column({ space: 4 }) {
                  Text(item.name || '匿名用户')
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text(`热心值 ${item.heartValue} · 成功归还 ${item.returnCount}`)
                    .fontSize(12).fontColor($r('app.color.text_hint'))
                }
                .layoutWeight(1)
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
