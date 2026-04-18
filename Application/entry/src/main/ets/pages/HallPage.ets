/**
 * 大厅页面（Phase 3）
 * 功能：失物招领 / 寻物启事 导航 + 卡片显示（分类/状态/点赞） + 筛选工具栏
 */
import { router } from '@kit.ArkUI';
import { ItemService, ItemCard } from '../services/ItemService';
import { HallItemCard } from '../components/HallItemCard';
import { ITEM_CATEGORIES } from '../model/ItemCategory';
import { HallItemData } from '../model/HallItemData';

@Entry
@Component
export struct HallPage {
  // 用 @Prop 接收 HomePage 已经算好的安全区高度，和 FrontPage 保持一致
  @Prop topHeight: number = 0;
  @Prop bottomHeight: number = 0;
  @State currentTypeIndex: number = 0;  // 0=失物招领, 1=寻物启事
  @State lostItems: HallItemData[] = [];
  @State foundItems: HallItemData[] = [];
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;

  // 筛选/排序状态
  @State sortBy: string = 'time-desc';   // time-desc/time-asc/like-desc/like-asc
  @State filterCategory: string = '';     // 空=全部，否则为具体分类
  @State showCategoryFilter: boolean = false;

  aboutToAppear(): void {
    ItemService.resetAllPagination();
    this.loadItems();
  }

  private getCurrentType(): string {
    return this.currentTypeIndex === 0 ? 'lost' : 'find';
  }

  private getCurrentItems(): HallItemData[] {
    const raw = this.currentTypeIndex === 0 ? this.lostItems : this.foundItems;
    return this.applySortAndFilter(raw);
  }

  private applySortAndFilter(items: HallItemData[]): HallItemData[] {
    let result: HallItemData[] = items;
    if (this.filterCategory) {
      result = result.filter((item: HallItemData) => item.category === this.filterCategory);
    }
    if (this.sortBy === 'time-asc') {
      result = result.reverse();
    } else if (this.sortBy === 'like-desc') {
      result.sort((a: HallItemData, b: HallItemData) => (b.likeCount || 0) - (a.likeCount || 0));
    } else if (this.sortBy === 'like-asc') {
      result.sort((a: HallItemData, b: HallItemData) => (a.likeCount || 0) - (b.likeCount || 0));
    }
    return result;
  }

  private async loadItems(): Promise<void> {
    this.isLoading = true;
    try {
      const type = this.getCurrentType();
      const result = await ItemService.getCardInfoListByType(type);
      if (this.currentTypeIndex === 0) {
        this.lostItems = this.enrichItems(result);
      } else {
        this.foundItems = this.enrichItems(result);
      }
    } finally {
      this.isLoading = false;
    }
  }

  private enrichItems(items: ItemCard[]): HallItemData[] {
    return items.map((item: ItemCard) => {
      const data = new HallItemData();
      data.itemId = item.itemId;
      data.type = item.type;
      data.text = item.text;
      data.publishTime = item.publishTime;
      data.publishId = item.publishId;
      data.publisherName = item.publisherName;
      data.publisherAvatar = item.publisherAvatar;
      data.mediaList = JSON.stringify(item.mediaList);
      data.category = item.category || '其他';
      data.likeCount = item.likeCount || 0;
      data.status = item.status || 'active';
      data.claimedBy = item.claimedBy || '';
      data.lostTime = item.lostTime || 0;
      return data;
    });
  }

  private handleCardClick(item: HallItemData): void {
    const options: router.RouterOptions = {
      url: 'pages/DetailPage',
      params: item
    };
    router.pushUrl(options);
  }

  private async onRefresh(): Promise<void> {
    // 重置当前 tab 的分页游标，重新从头拉
    ItemService.resetPaginationByType(this.getCurrentType());
    try {
      await this.loadItems();
    } finally {
      this.isRefreshing = false;
    }
  }

  @Builder
  buildTopNav() {
    Row() {
      Column() {
        Text('失物招领')
          .fontSize(15)
          .fontWeight(this.currentTypeIndex === 0 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.currentTypeIndex === 0 ? '#4E8FDF' : $r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .height(44)
        Row()
          .width(40).height(3).borderRadius(1.5)
          .backgroundColor(this.currentTypeIndex === 0 ? '#4E8FDF' : Color.Transparent)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { this.currentTypeIndex = 0 })

      Column() {
        Text('寻物启事')
          .fontSize(15)
          .fontWeight(this.currentTypeIndex === 1 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.currentTypeIndex === 1 ? '#4E8FDF' : $r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .height(44)
        Row()
          .width(40).height(3).borderRadius(1.5)
          .backgroundColor(this.currentTypeIndex === 1 ? '#4E8FDF' : Color.Transparent)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { this.currentTypeIndex = 1 })
    }
    .width('100%')
    .height(52)
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  buildFilterBar() {
    Row({ space: 8 }) {
      Row({ space: 4 }) {
        Text('⏱').fontSize(12)
        Text(this.sortBy === 'time-desc' ? '↓' : '↑').fontSize(10)
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.sortBy.startsWith('time') ? '#E6F0FF' : '#F5F5F5')
      .borderRadius(4)
      .onClick(() => {
        this.sortBy = this.sortBy === 'time-desc' ? 'time-asc' : 'time-desc';
      })

      Row({ space: 4 }) {
        Text('❤️').fontSize(12)
        Text(this.sortBy === 'like-desc' ? '↓' : '↑').fontSize(10)
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.sortBy.startsWith('like') ? '#FFE6E6' : '#F5F5F5')
      .borderRadius(4)
      .onClick(() => {
        this.sortBy = this.sortBy === 'like-desc' ? 'like-asc' : 'like-desc';
      })

      Row({ space: 4 }) {
        Text(this.filterCategory || '分类').fontSize(12)
        Text('▼').fontSize(10)
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.filterCategory ? '#FFF3E0' : '#F5F5F5')
      .borderRadius(4)
      .onClick(() => { this.showCategoryFilter = !this.showCategoryFilter })

      Blank()
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  buildCategoryFilter() {
    Scroll() {
      Row({ space: 8 }) {
        Row() {
          Text('全部').fontSize(12)
          if (!this.filterCategory) {
            Text(' ✓').fontSize(12).fontColor('#4E8FDF')
          }
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor(!this.filterCategory ? '#EBF3FF' : '#F5F5F5')
        .borderRadius(3)
        .onClick(() => {
          this.filterCategory = '';
          this.showCategoryFilter = false;
        })

        ForEach(ITEM_CATEGORIES, (cat: string) => {
          Row() {
            Text(cat).fontSize(12)
            if (this.filterCategory === cat) {
              Text(' ✓').fontSize(12).fontColor('#4E8FDF')
            }
          }
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .backgroundColor(this.filterCategory === cat ? '#EBF3FF' : '#F5F5F5')
          .borderRadius(3)
          .onClick(() => {
            this.filterCategory = cat;
            this.showCategoryFilter = false;
          })
        })
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%').height(40)
    .backgroundColor('#FAFAFA')
  }

  @Builder
  buildList() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Scroll() {
        Column() {
          if (this.isLoading && this.getCurrentItems().length === 0) {
            Column() {
              LoadingProgress().width(40).height(40).color('#4E8FDF')
            }
            .width('100%').height(200).justifyContent(FlexAlign.Center)
          } else if (this.getCurrentItems().length === 0) {
            Column({ space: 8 }) {
              Text('暂无物品').fontSize(16).fontColor($r('app.color.text_hint'))
              Text('下拉刷新试试').fontSize(13).fontColor($r('app.color.text_disabled'))
            }
            .width('100%').height(200).justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 12 }) {
              ForEach(this.getCurrentItems(), (item: HallItemData) => {
                HallItemCard({
                  item,
                  onCardClick: (i: HallItemData) => { this.handleCardClick(i) },
                  onLikeClick: () => { /* 刷新点赞数，后续实现 */ }
                })
              })
              Row().height(this.bottomHeight + 80)
            }
            .width('100%').padding({ left: 12, right: 12, top: 12 })
          }
        }
        .width('100%')
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .layoutWeight(1)
    .width('100%')
    .onRefreshing(() => { this.onRefresh() })
  }

  build() {
    Column() {
      // 顶部安全区占位
      Row().width('100%').height(this.topHeight).backgroundColor($r('app.color.bg_card'))

      // 顶部导航（失物招领 / 寻物启事）
      this.buildTopNav()

      // 筛选工具栏
      this.buildFilterBar()

      // 分类下拉（条件）
      if (this.showCategoryFilter) {
        this.buildCategoryFilter()
      }

      // 卡片列表
      this.buildList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
