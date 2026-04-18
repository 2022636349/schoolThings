import { Item, ItemStatus } from '../model/ItemModel';

@Component
export struct ItemCard {
  @Prop item: Item = {
    id: '',
    title: '',
    description: '',
    location: '',
    contact: '',
    imageUrl: '',
    date: new Date(),
    status: ItemStatus.LOST,
    userId: ''
  };
  onItemClick?: (item: Item) => void;

  build() {
    Column() {
      Row() {
        if (this.item.imageUrl) {
          Image(this.item.imageUrl)
            .width(100)
            .height(100)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('暂无图片')
              .fontSize(12)
              .fontColor('#999')
          }
          .width(100)
          .height(100)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        Column() {
          Text(this.item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.item.description)
            .fontSize(14)
            .fontColor('#666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })

          Text(`${this.item.location} | ${this.item.contact}`)
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 4 })

          Row() {
            Text(this.formatDate(this.item.date))
              .fontSize(12)
              .fontColor('#999')

            Blank()

            Text(this.getStatusText(this.item.status))
              .fontSize(12)
              .fontColor(this.getStatusColor(this.item.status))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor(this.getStatusBgColor(this.item.status))
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
        .height(100)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(this.item);
      }
    })
  }

  formatDate(date: Date): string {
    const now: Date = new Date();
    const diff: number = now.getTime() - date.getTime();
    const days: number = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days === 0) return '今天';
    if (days === 1) return '昨天';
    if (days < 7) return `${days}天前`;
    return `${date.getMonth() + 1}/${date.getDate()}`;
  }

  getStatusText(status: ItemStatus): string {
    switch (status) {
      case ItemStatus.LOST: return '丢失';
      case ItemStatus.FOUND: return '招领';
      case ItemStatus.CLAIMED: return '已认领';
      default: return '';
    }
  }

  getStatusColor(status: ItemStatus): ResourceColor {
    switch (status) {
      case ItemStatus.LOST: return '#FF6B6B';
      case ItemStatus.FOUND: return '#4ECDC4';
      case ItemStatus.CLAIMED: return '#95A5A6';
      default: return '#999';
    }
  }

  getStatusBgColor(status: ItemStatus): ResourceColor {
    switch (status) {
      case ItemStatus.LOST: return '#FFE5E5';
      case ItemStatus.FOUND: return '#E8F8F5';
      case ItemStatus.CLAIMED: return '#F0F0F0';
      default: return '#F5F5F5';
    }
  }
}
