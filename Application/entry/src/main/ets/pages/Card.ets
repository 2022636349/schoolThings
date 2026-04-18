import { ItemCard, MediaItem } from '../services/ItemService'
import { router } from '@kit.ArkUI';

@Component
export struct ItemCardView {
  @Prop item: ItemCard;

  onMediaClick(index: number): void {
    router.pushUrl({
      url: 'pages/MediaPreview',
      params: {
        mediaList: this.item.mediaList,
        currentIndex: index
      }
    });
  }

  @Builder
  thumbnailBuilder(media: MediaItem, index: number, height: number) {
    Stack() {
      if (media.type === 'image') {
        Image(media.url)
          .width('100%')
          .height(height)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.bg_image_placeholder'))
      } else {
        Stack() {
          Image('')
            .width('100%')
            .height(height)
            .backgroundColor('#ff161616')
          Text('▶')
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(height)
      }

      if (index === 2 && this.item.mediaList.length > 3) {
        Text(`+${this.item.mediaList.length - 3}`)
          .width('100%')
          .height(height)
          .textAlign(TextAlign.Center)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(0,0,0,0.45)')
      }
    }
    .width('100%')
    .height(height)
    .onClick(() => { this.onMediaClick(index) })
  }

  @Builder
  twoMediaBuilder() {
    Row({ space: 2 }) {
      Image(this.item.mediaList[0].url)
        .layoutWeight(1)
        .height(160)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.bg_image_placeholder'))
        .onClick(() => { this.onMediaClick(0) })

      Image(this.item.mediaList[1].url)
        .layoutWeight(1)
        .height(160)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.bg_image_placeholder'))
        .onClick(() => { this.onMediaClick(1) })
    }
    .width('100%')
    .borderRadius(8)
    .clip(true)
  }

  @Builder
  threeMediaBuilder() {
    Row({ space: 2 }) {
      Image(this.item.mediaList[0].url)
        .layoutWeight(1)
        .height(200)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.bg_image_placeholder'))
        .onClick(() => { this.onMediaClick(0) })

      Column({ space: 2 }) {
        Image(this.item.mediaList[1].url)
          .width('100%')
          .height(99)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.bg_image_placeholder'))
          .onClick(() => { this.onMediaClick(1) })

        Stack() {
          Image(this.item.mediaList[2].url)
            .width('100%')
            .height(99)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.bg_image_placeholder'))

          // 超过3张显示 +N
          if (this.item.mediaList.length > 3) {
            Text(`+${this.item.mediaList.length - 3}`)
              .width('100%')
              .height(99)
              .textAlign(TextAlign.Center)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor('rgba(0,0,0,0.45)')
          }
        }
        .width('100%')
        .onClick(() => { this.onMediaClick(2) })
      }
      .layoutWeight(1)
      .height(200)
    }
    .width('100%')
    .height(200)
    .borderRadius(8)
    .clip(true)
  }

  @Builder
  oneMediaBuilder() {
    Image(this.item.mediaList[0].url)
      .width('100%')
      .height(200)
      .objectFit(ImageFit.Cover)
      .backgroundColor($r('app.color.bg_image_placeholder'))
      .borderRadius(8)
      .onClick(() => { this.onMediaClick(0) })
  }

  build() {
    Column() {
      Row() {
        // 发布者头像
        if (this.item.publisherAvatar) {
          Image(this.item.publisherAvatar)
            .width(40)
            .height(40)
            .borderRadius(20)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.bg_avatar_placeholder'))
        } else {
          Stack() {
            Circle().width(40).height(40).fill('#4E8FDF').opacity(0.12)
            Text(this.item.publisherName?.charAt(0) || '?')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4E8FDF')
          }
          .width(40)
          .height(40)
          .borderRadius(20)
        }

        Column() {
          Row() {
            Text(this.item.publisherName || '匿名用户')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.item.type === 'lost' ? '寻物' : this.item.type === 'find' ? '招领' : '已认领')
              .fontColor(this.item.type === 'lost' ? '#E07B39' : this.item.type === 'find' ? '#4E8FDF' : '#4CAF50')
              .backgroundColor(this.item.type === 'lost' ? $r('app.color.badge_lost_bg') : this.item.type === 'find' ? $r('app.color.badge_find_bg') : $r('app.color.badge_claimed_bg'))
              .fontSize(11)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              .margin({ left: 6 })
          }
          .alignItems(VerticalAlign.Center)

          Text(this.item.publishTime)
            .fontSize(12)
            .fontColor($r('app.color.text_caption'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.item.text)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(22)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 10 })

      if (this.item.mediaList.length === 1) {
        this.oneMediaBuilder()
      } else if (this.item.mediaList.length === 2) {
        this.twoMediaBuilder()
      } else if (this.item.mediaList.length >= 3) {
        this.threeMediaBuilder()
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
    .onClick(() => {
      const p: Record<string, Object> = {};
      p['itemId'] = this.item.itemId;
      p['type'] = this.item.type;
      p['text'] = this.item.text;
      p['publishTime'] = this.item.publishTime;
      p['publishId'] = this.item.publishId;
      p['publisherName'] = this.item.publisherName;
      p['publisherAvatar'] = this.item.publisherAvatar;
      p['mediaList'] = JSON.stringify(this.item.mediaList);
      if (AppStorage.get<boolean>('isTabletMode') === true) {
        const cur = AppStorage.get<string>('tabletRightType') || 'none';
        AppStorage.setOrCreate('tabletPrevRightType', cur);
        AppStorage.setOrCreate('tabletRightType', 'detail');
        AppStorage.setOrCreate('tabletRightParams', JSON.stringify(p));
      } else {
        router.pushUrl({ url: 'pages/DetailPage', params: p });
      }
    })
  }
}
