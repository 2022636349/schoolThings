import { router, window } from '@kit.ArkUI';

/**
 * 失物处理预警公示页（Phase 4 填充真实查询 status=warning）
 */
@Entry
@Component
export struct WarningPage {
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
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

      // 说明条
      Row({ space: 8 }) {
        Text('⚠️').fontSize(16)
        Text('此处公示超过 60 天无人认领、已移交学校处置的物品；公示 15 天后将正式下架。')
          .fontSize(12).fontColor('#A46615').layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor('#FFF6E5')

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
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
