import { ItemCard, MediaItem } from '../services/ItemService'
import { router } from '@kit.ArkUI';
import { deriveStatus, getStatusLabel, getStatusColor, getStatusBg } from '../model/ItemCategory';

@Component
export struct ItemCardView {
  @Prop item: ItemCard;
  @Prop compact: boolean = false;

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

  private getDisplayStatus() {
    return deriveStatus(this.item.type, this.item.status);
  }

  private goDetail(): void {
    const p: Record<string, Object> = {};
    p['itemId'] = this.item.itemId;
    p['type'] = this.item.type;
    p['text'] = this.item.text;
    p['publishTime'] = this.item.publishTime;
    p['publishId'] = this.item.publishId;
    p['publisherName'] = this.item.publisherName;
    p['publisherAvatar'] = this.item.publisherAvatar;
    p['mediaList'] = JSON.stringify(this.item.mediaList);
    p['category'] = this.item.category;
    p['likeCount'] = this.item.likeCount;
    p['status'] = this.item.status;
    p['claimedBy'] = this.item.claimedBy || '';
    p['claimedByStudentNo'] = this.item.claimedByStudentNo || '';
    p['lostTime'] = this.item.lostTime;
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      const cur = AppStorage.get<string>('tabletRightType') || 'none';
      AppStorage.setOrCreate('tabletPrevRightType', cur);
      AppStorage.setOrCreate('tabletRightType', 'detail');
      AppStorage.setOrCreate('tabletRightParams', JSON.stringify(p));
    } else {
      router.pushUrl({ url: 'pages/DetailPage', params: p });
    }
  }

  @Builder
  buildCompactCard() {
    Row({ space: 12 }) {
      if (this.item.mediaList.length > 0 && this.item.mediaList[0].url) {
        Image(this.item.mediaList[0].url)
          .width(100).height(100).borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('📷').fontSize(28)
        }
        .width(100).height(100).borderRadius(8)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
      }

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text(this.item.text.split('\n')[0] || '物品')
            .fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.item.category) {
            Text(this.item.category)
              .fontSize(10).fontColor('#666')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#F0F0F0')
              .borderRadius(3)
          }
        }

        Text(this.item.text)
          .fontSize(13).fontColor($r('app.color.text_hint'))
          .lineHeight(18)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 8 }) {
          Text(this.item.publisherName || '匿名')
            .fontSize(11).fontColor($r('app.color.text_hint'))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(getStatusLabel(this.item.type, this.getDisplayStatus()))
            .fontSize(10).fontColor(getStatusColor(this.getDisplayStatus()))
            .backgroundColor(getStatusBg(this.getDisplayStatus()))
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .borderRadius(2)

          Blank()

          Row({ space: 2 }) {
            Text($r('app.media.like_s')).fontSize(12)
            Text((this.item.likeCount || 0).toString())
              .fontSize(10)
              .fontColor($r('app.color.text_hint'))
          }
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .height(100)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildRichCard() {
    Column() {
      Row() {
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

            Text(getStatusLabel(this.item.type, this.getDisplayStatus()))
              .fontColor(getStatusColor(this.getDisplayStatus()))
              .backgroundColor(getStatusBg(this.getDisplayStatus()))
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
  }

  build() {
    Column() {
      if (this.compact) {
        this.buildCompactCard()
      } else {
        this.buildRichCard()
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => { this.goDetail() })
  }
}
