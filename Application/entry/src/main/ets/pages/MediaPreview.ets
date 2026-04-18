import { router } from '@kit.ArkUI';
import { MediaItem } from '../services/ItemService';

interface PreviewParams {
  mediaList: MediaItem[];
  currentIndex: number;
}

@Entry
@Component
struct MediaPreview {
  @State currentIndex: number = 0;
  @State mediaList: MediaItem[] = [];
  @State bgOpacity: number = 1.0;
  @State offsetY: number = 0; // 下滑距离

  aboutToAppear(): void {
    const params = router.getParams() as PreviewParams;
    if (params) {
      this.mediaList = params.mediaList;
      this.currentIndex = params.currentIndex;
    }
  }

  // 下滑关闭
  closePreview(): void {
    router.back();
  }

  @Builder
  mediaItemBuilder(media: MediaItem) {
    if (media.type === 'image') {
      Image(media.url)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain) // Contain 保持比例不裁剪
    } else {
      Video({ src: media.url })
        .width('100%')
        .height('100%')
        .autoPlay(true)
        .controls(true)
        .objectFit(ImageFit.Contain)
    }
  }

  build() {
    Stack() {
      // 黑色背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(`rgba(0,0,0,${this.bgOpacity})`)

      // 图片/视频 Swiper
      Swiper() {
        ForEach(this.mediaList, (media: MediaItem) => {
          Stack() {
            this.mediaItemBuilder(media)
          }
          .width('100%')
          .height('100%')
        }, (media: MediaItem): string => media.url)
      }
      .index(this.currentIndex)
      .width('100%')
      .height('100%')
      .loop(false)
      .indicator(
        new DotIndicator()
          .color('rgba(255,255,255,0.4)')
          .selectedColor('#FFFFFF')
      )
      .translate({ y: this.offsetY }) // 下滑偏移
      .animation({ duration: 200, curve: Curve.FastOutSlowIn })
      .gesture(
        // 下滑手势关闭
        PanGesture({ direction: PanDirection.Down })
          .onActionUpdate((event: GestureEvent) => {
            this.offsetY = event.offsetY;
            // 背景随下滑变透明
            this.bgOpacity = Math.max(0, 1 - this.offsetY / 300);
          })
          .onActionEnd(() => {
            if (this.offsetY > 100) {
              // 下滑超过 100 关闭
              this.closePreview();
            } else {
              // 没超过回弹
              this.offsetY = 0;
              this.bgOpacity = 1.0;
            }
          })
      )

      // 关闭按钮
      Row() {
        Text('✕')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .padding(12)
          .onClick(() => { this.closePreview() })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ top: 50, right: 16 })
      .position({ x: 0, y: 0 })

      // 页码指示（当有多张时显示）
      if (this.mediaList.length > 1) {
        Text(`${this.currentIndex + 1} / ${this.mediaList.length}`)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .position({ x: 0, y: 60 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}