/**
 * 大厅页面（Phase 3）
 * 功能：失物招领 / 寻物启事 导航 + 卡片显示（分类/状态/点赞） + 筛选工具栏
 */
import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { ItemService, ItemCard } from '../services/ItemService';
import { HallItemCard } from '../components/HallItemCard';
import { ITEM_CATEGORIES } from '../model/ItemCategory';
import { HallItemData } from '../model/HallItemData';

interface HallLikeSyncPayload {
  itemId: number;
  isLiked: boolean;
  likeCount: number;
}

@Entry
@Component
export struct HallPage {
  // 用 @Prop 接收 HomePage 已经算好的安全区高度，和 FrontPage 保持一致
  @Prop topHeight: number = 0;
  @Prop bottomHeight: number = 0;
  @Prop refreshTrigger: number = 0;
  @State currentTypeIndex: number = 0;  // 0=失物招领, 1=寻物启事
  @State lostItems: HallItemData[] = [];
  @State foundItems: HallItemData[] = [];
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;

  // 筛选/排序状态
  @State searchKeyword: string = '';
  @State searchHistory: string[] = [];
  @State activeKeyword: string = '';
  @State isSearchMode: boolean = false;
  @State searchResults: HallItemData[] = [];
  @State sortBy: string = 'time-desc';
  @State filterCategory: string = '';
  @State filterLocationKeyword: string = '';
  @State timeRange: string = 'all';
  @State showCategoryFilter: boolean = false;

  aboutToAppear(): void {
    ItemService.resetAllPagination();
    this.consumeLikeSync();
    this.loadSearchHistory();
    this.loadItems();
  }

  updateStateVars(): void {
    if (this.refreshTrigger > 0) {
      ItemService.resetAllPagination();
      this.lostItems = [];
      this.foundItems = [];
      this.loadItems();
    }
  }

  private loadSearchHistory(): void {
    try {
      const store = preferences.getPreferencesSync(getContext(this), { name: 'hall_search' });
      const raw = store.getSync('keywords', '[]') as string;
      this.searchHistory = JSON.parse(raw) as string[];
    } catch (e) {
      this.searchHistory = [];
    }
  }

  private saveSearchHistory(keyword: string): void {
    const next = [keyword, ...this.searchHistory.filter((item: string) => item !== keyword)].slice(0, 8);
    this.searchHistory = next;
    const store = preferences.getPreferencesSync(getContext(this), { name: 'hall_search' });
    store.putSync('keywords', JSON.stringify(next));
    store.flush();
  }

  private clearSearchHistory(): void {
    this.searchHistory = [];
    const store = preferences.getPreferencesSync(getContext(this), { name: 'hall_search' });
    store.putSync('keywords', '[]');
    store.flush();
  }

  private getCurrentType(): string {
    return this.currentTypeIndex === 0 ? 'lost' : 'found';
  }

  private getCurrentItems(): HallItemData[] {
    const raw = this.isSearchMode
      ? this.searchResults
      : (this.currentTypeIndex === 0 ? this.lostItems : this.foundItems);
    return this.applySortAndFilter(raw);
  }

  private consumeLikeSync(): void {
    const raw = AppStorage.get<string>('hallLikeSync');
    if (!raw) return;
    try {
      const sync = JSON.parse(raw) as HallLikeSyncPayload;
      this.updateItemLikeState(sync.itemId, sync.likeCount);
    } catch (e) {
    }
    AppStorage.setOrCreate('hallLikeSync', '');
  }

  private cloneItem(item: HallItemData): HallItemData {
    const next = new HallItemData();
    next.itemId = item.itemId;
    next.type = item.type;
    next.text = item.text;
    next.publishTime = item.publishTime;
    next.publishId = item.publishId;
    next.publisherName = item.publisherName;
    next.publisherAvatar = item.publisherAvatar;
    next.mediaList = item.mediaList;
    next.category = item.category;
    next.likeCount = item.likeCount;
    next.status = item.status;
    next.claimedBy = item.claimedBy;
    next.claimedByStudentNo = item.claimedByStudentNo;
    next.lostTime = item.lostTime;
    return next;
  }

  private updateItemLikeState(itemId: number, likeCount: number): void {
    const patch = (items: HallItemData[]): HallItemData[] => {
      return items.map((item: HallItemData) => {
        if (item.itemId !== itemId) return item;
        const next = this.cloneItem(item);
        next.likeCount = likeCount;
        return next;
      });
    };
    this.lostItems = patch(this.lostItems);
    this.foundItems = patch(this.foundItems);
    this.searchResults = patch(this.searchResults);
  }

  private async doSearch(keyword: string): Promise<void> {
    this.searchKeyword = keyword;
    this.activeKeyword = keyword;
    this.isSearchMode = true;
    this.saveSearchHistory(keyword);
    const list = await ItemService.searchByKeyword(keyword);
    const hallItems = this.enrichItems(list).filter((item: HallItemData) => item.type === this.getCurrentType());
    this.searchResults = hallItems;
  }

  private clearSearch(): void {
    this.searchKeyword = '';
    this.activeKeyword = '';
    this.isSearchMode = false;
    this.searchResults = [];
  }

  private applySortAndFilter(items: HallItemData[]): HallItemData[] {
    let result: HallItemData[] = [...items];
    if (this.filterCategory) {
      result = result.filter((item: HallItemData) => item.category === this.filterCategory);
    }
    if (this.filterLocationKeyword.trim().length > 0) {
      const keyword = this.filterLocationKeyword.trim();
      result = result.filter((item: HallItemData) => item.text.indexOf(keyword) >= 0);
    }
    if (this.timeRange !== 'all') {
      const now = Date.now();
      const limitMs = this.timeRange === '7d' ? 7 * 24 * 60 * 60 * 1000 : 30 * 24 * 60 * 60 * 1000;
      result = result.filter((item: HallItemData) => item.lostTime > 0 && (now - item.lostTime) <= limitMs);
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
      data.claimedByStudentNo = item.claimedByStudentNo || '';
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
  buildSearchBar() {
    Column() {
      Row() {
        Search({ value: this.searchKeyword, placeholder: '搜索物品名称、描述...' })
          .searchButton('搜索')
          .width('100%')
          .onChange((value: string): void => {
            this.searchKeyword = value
          })
          .onSubmit((value: string): void => {
            if (value.trim()) {
              this.doSearch(value.trim());
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
      .backgroundColor($r('app.color.bg_card'))

      if (this.searchHistory.length > 0 && !this.isSearchMode) {
        Row({ space: 8 }) {
          Text('最近搜索').fontSize(12).fontColor($r('app.color.text_hint'))
          Blank()
          Text('清空')
            .fontSize(12)
            .fontColor('#4E8FDF')
            .onClick(() => { this.clearSearchHistory() })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 0, bottom: 6 })
        .backgroundColor($r('app.color.bg_card'))

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.searchHistory, (keyword: string) => {
              Row() {
                Text(keyword).fontSize(12).fontColor('#4E8FDF')
              }
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#EBF3FF')
              .borderRadius(18)
              .onClick(() => { this.doSearch(keyword) })
            })
          }
          .padding({ left: 12, right: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%').height(40)
        .backgroundColor($r('app.color.bg_card'))
      }

      if (this.isSearchMode) {
        Row() {
          Row({ space: 6 }) {
            Text(this.activeKeyword)
              .fontSize(13)
              .fontColor('#4E8FDF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 200 })
            Text('✕')
              .fontSize(12)
              .fontColor('#4E8FDF')
              .onClick(() => { this.clearSearch() })
          }
          .padding({ left: 12, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#EBF3FF')
          .borderRadius(20)
          .border({ width: 1, color: '#C0D8F8' })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 0, bottom: 8 })
        .backgroundColor($r('app.color.bg_card'))
      }
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
      .onClick(() => {
        this.currentTypeIndex = 0;
        if (this.lostItems.length === 0 && !this.isLoading) {
          ItemService.resetPaginationByType('lost');
          this.loadItems();
        }
      })

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
      .onClick(() => {
        this.currentTypeIndex = 1;
        if (this.foundItems.length === 0 && !this.isLoading) {
          ItemService.resetPaginationByType('found');
          this.loadItems();
        }
      })
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
        TextInput({ placeholder: '地点关键词', text: this.filterLocationKeyword })
          .width(110).height(32).fontSize(12)
          .backgroundColor('#F5F5F5')
          .borderRadius(4)
          .padding({ left: 8, right: 8 })
          .onChange((value: string) => { this.filterLocationKeyword = value })

        Row({ space: 4 }) {
          Text(this.timeRange === 'all' ? '全部时间' : (this.timeRange === '7d' ? '近7天' : '近30天')).fontSize(12)
          Text('▼').fontSize(10)
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.timeRange === 'all' ? '#F5F5F5' : '#E6F0FF')
        .borderRadius(4)
        .onClick(() => {
          if (this.timeRange === 'all') {
            this.timeRange = '7d';
          } else if (this.timeRange === '7d') {
            this.timeRange = '30d';
          } else {
            this.timeRange = 'all';
          }
        })
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
              Text(this.isSearchMode ? '未找到相关物品' : '暂无物品').fontSize(16).fontColor($r('app.color.text_hint'))
              Text(this.isSearchMode ? '试试更换关键词' : '下拉刷新试试').fontSize(13).fontColor($r('app.color.text_disabled'))
            }
            .width('100%').height(200).justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 12 }) {
              ForEach(this.getCurrentItems(), (item: HallItemData) => {
                HallItemCard({
                  item,
                  onCardClick: (i: HallItemData) => { this.handleCardClick(i) },
                  onLikeClick: (itemId: number, _isLiked: boolean, likeCount: number) => {
                    this.updateItemLikeState(itemId, likeCount)
                  }
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

      this.buildSearchBar()

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
