/**
 * HallPage 物品卡片组件
 * 显示：图片 + 名称 + 描述 + 分类 badge + 状态标签 + 点赞按钮
 */
import { ItemService, MediaItem } from '../services/ItemService';
import { deriveStatus, getStatusLabel, getStatusColor, getStatusBg } from '../model/ItemCategory';
import { HallItemData } from '../model/HallItemData';

@Component
export struct HallItemCard {
  @Prop item: HallItemData;
  @State isLiked: boolean = false;
  @State likeCount: number = 0;
  @State currentUserId: string = '';

  onCardClick: (item: HallItemData) => void = () => {};
  onLikeClick: () => void = () => {};

  aboutToAppear(): void {
    this.likeCount = this.item.likeCount || 0;
  }

  private async handleLikeClick(): Promise<void> {
    if (!this.currentUserId || !this.item.itemId) return;
    try {
      const newLikeStatus = await ItemService.toggleLike(this.item.itemId, this.currentUserId);
      this.isLiked = newLikeStatus;
      this.likeCount = newLikeStatus ? this.likeCount + 1 : Math.max(0, this.likeCount - 1);
      this.onLikeClick();
    } catch (e) {
      console.warn('[HallItemCard] 点赞失败:', e);
    }
  }

  private getMediaUrl(): string {
    try {
      const list = JSON.parse(this.item.mediaList) as MediaItem[];
      if (list && list.length > 0) {
        return list[0].url || '';
      }
    } catch (e) {
      // ignore
    }
    return '';
  }

  private getDisplayStatus() {
    return deriveStatus(this.item.type, this.item.status);
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        // 图片
        if (this.getMediaUrl()) {
          Image(this.getMediaUrl())
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

        // 信息列
        Column({ space: 8 }) {
          // 标题和分类
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

          // 描述（2 行）
          Text(this.item.text)
            .fontSize(13).fontColor($r('app.color.text_hint'))
            .lineHeight(18)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          // 底行：发布者 + 状态 + 点赞
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
              Text(this.isLiked ? '❤️' : '🤍').fontSize(12)
              Text(this.likeCount.toString()).fontSize(10).fontColor($r('app.color.text_hint'))
            }
            .padding(4).borderRadius(3)
            .onClick(() => { this.handleLikeClick(); })
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
    .width('100%').padding(12)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => { this.onCardClick(this.item) })
  }
}
