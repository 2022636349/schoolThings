import { router } from '@kit.ArkUI';
import { MediaItem } from '../services/ItemService';
import { MeteorOverlay } from '../components/MeteorOverlay';

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
  @State offsetY: number = 0; 

  aboutToAppear(): void {
    const params = router.getParams() as PreviewParams;
    if (params) {
      this.mediaList = params.mediaList;
      this.currentIndex = params.currentIndex;
    }
  }

  closePreview(): void {
    router.back();
  }

  @Builder
  mediaItemBuilder(media: MediaItem) {
    if (media.type === 'image') {
      Image(media.url)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain) 
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
      Stack() {

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(`rgba(0,0,0,${this.bgOpacity})`)

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
      .translate({ y: this.offsetY }) 
      .animation({ duration: 200, curve: Curve.FastOutSlowIn })
      .gesture(

        PanGesture({ direction: PanDirection.Down })
          .onActionUpdate((event: GestureEvent) => {
            this.offsetY = event.offsetY;

            this.bgOpacity = Math.max(0, 1 - this.offsetY / 300);
          })
          .onActionEnd(() => {
            if (this.offsetY > 100) {

              this.closePreview();
            } else {

              this.offsetY = 0;
              this.bgOpacity = 1.0;
            }
          })
      )

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

      MeteorOverlay()
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
