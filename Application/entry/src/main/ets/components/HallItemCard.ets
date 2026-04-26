import { ItemService, MediaItem } from '../services/ItemService';
import { AuthService } from '../services/AuthService';
import { common } from '@kit.AbilityKit';
import { deriveStatus, getStatusLabel, getStatusColor, getStatusBg } from '../model/ItemCategory';
import { HallItemData } from '../model/HallItemData';

const CARD_RADIUS: number = 16;
const COVER_SIZE: number = 106;

@Component
export struct HallItemCard {
  @Prop item: HallItemData;
  @Prop itemIndex: number = 0;
  @Prop @Watch('onAnimationTriggerChange') animationTrigger: number = 0;
  @State isLiked: boolean = false;
  @State likeCount: number = 0;
  @State currentUserId: string = '';
  @State translateX: number = 72;
  @State cardOpacity: number = 0;

  onCardClick: (item: HallItemData) => void = () => {};
  onLikeClick: (itemId: number, isLiked: boolean, likeCount: number) => void = () => {};

  aboutToAppear(): void {
    this.playEnterAnimation();
    this.likeCount = this.item.likeCount || 0;
    AuthService.getSession(getContext(this) as common.UIAbilityContext).then((session) => {
      if (session) {
        this.currentUserId = session.id;
        this.syncLikeState();
      }
    });
  }

  onAnimationTriggerChange(): void {
    this.playEnterAnimation();
  }

  private playEnterAnimation(): void {
    this.translateX = 72;
    this.cardOpacity = 0;
    const delay = Math.min(this.itemIndex, 8) * 110;
    setTimeout(() => {
      animateTo({ duration: 520, curve: Curve.EaseOut }, () => {
        this.translateX = 0;
        this.cardOpacity = 1;
      });
    }, delay);
  }

  private async syncLikeState(): Promise<void> {
    if (!this.currentUserId || !this.item.itemId) return;
    try {
      this.isLiked = await ItemService.hasLiked(this.item.itemId, this.currentUserId);
    } catch (e) {
      console.warn('[HallItemCard] sync like state failed:', e);
    }
  }

  private async handleLikeClick(): Promise<void> {
    if (!this.currentUserId || !this.item.itemId) return;
    try {
      const newLikeStatus = await ItemService.toggleLike(this.item.itemId, this.currentUserId);
      this.isLiked = newLikeStatus;
      this.likeCount = newLikeStatus ? this.likeCount + 1 : Math.max(0, this.likeCount - 1);
      this.onLikeClick(this.item.itemId, this.isLiked, this.likeCount);
    } catch (e) {
      console.warn('[HallItemCard] toggle like failed:', e);
    }
  }

  private getMediaUrl(): string {
    try {
      const list = JSON.parse(this.item.mediaList) as MediaItem[];
      if (list && list.length > 0) {
        return list[0].url || '';
      }
    } catch (e) {
    }
    return '';
  }

  private getDisplayStatus() {
    return deriveStatus(this.item.type, this.item.status);
  }

  private getTitle(): string {
    const lines = this.item.text.split('\n');
    const title = lines.length > 0 ? lines[0].trim() : '';
    return title.length > 0 ? title : 'Item';
  }

  private getSummary(): string {
    const title = this.getTitle();
    const summary = this.item.text.replace(title, '').trim();
    return summary.length > 0 ? summary : this.item.text;
  }

  private getPublishInfo(): string {
    const publisher = this.item.publisherName || 'Anonymous';
    if (this.item.publishTime && this.item.publishTime.length > 0) {
      return `${publisher} / ${this.item.publishTime}`;
    }
    return publisher;
  }

  build() {
    Column() {
      Row({ space: 14 }) {
        Stack({ alignContent: Alignment.TopStart }) {
          if (this.getMediaUrl()) {
            Image(this.getMediaUrl())
              .width(COVER_SIZE)
              .height(COVER_SIZE)
              .borderRadius(14)
              .objectFit(ImageFit.Cover)
          } else {
            Column({ space: 6 }) {
              Image($r('app.media.empty_image'))
                .width(34)
                .height(34)
                .opacity(0.72)
              Text(this.item.category || 'Item')
                .fontSize(11)
                .fontColor('#7A8799')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width(COVER_SIZE)
            .height(COVER_SIZE)
            .borderRadius(14)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor($r('app.color.bg_secondary'))
          }

          Text(getStatusLabel(this.item.type, this.getDisplayStatus()))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(getStatusColor(this.getDisplayStatus()))
            .backgroundColor(getStatusBg(this.getDisplayStatus()))
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .borderRadius(8)
            .margin({ left: 8, top: 8 })
        }
        .width(COVER_SIZE)
        .height(COVER_SIZE)

        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text(this.getTitle())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            if (this.item.category) {
              Text(this.item.category)
                .fontSize(11)
                .fontColor('#4E8FDF')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor($r('app.color.bg_secondary'))
                .borderRadius(8)
            }
          }

          Text(this.getSummary())
            .fontSize(13)
            .fontColor($r('app.color.text_tertiary'))
            .lineHeight(19)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row({ space: 8 }) {
            Text(this.getPublishInfo())
              .fontSize(11)
              .fontColor($r('app.color.text_caption'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Row({ space: 4 }) {
              if (this.isLiked) {
                Image($r('app.media.like_s'))
                  .width(14)
                  .height(14)
              } else {
                Image($r('app.media.like'))
                  .width(14)
                  .height(14)
              }
              Text(this.likeCount.toString())
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.isLiked ? '#FF4D6D' : $r('app.color.text_caption'))
            }
            .height(28)
            .padding({ left: 9, right: 9 })
            .borderRadius(14)
            .backgroundColor(this.isLiked ? 'rgba(255,77,109,0.16)' : $r('app.color.bg_secondary'))
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.handleLikeClick(); })
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .height(COVER_SIZE)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(CARD_RADIUS)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.10)', offsetY: 5 })
    .border({ width: 1, color: $r('app.color.border') })
    .margin({ bottom: 12 })
    .translate({ x: this.translateX, y: 0 })
    .opacity(this.cardOpacity)
    .onClick(() => { this.onCardClick(this.item) })
  }
}
