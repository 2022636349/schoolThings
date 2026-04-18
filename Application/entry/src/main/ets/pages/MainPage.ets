import { ItemCardView } from './Card'
import { ItemService, ItemCard } from '../services/ItemService'

@Component
@Entry
export struct MainPage {
  @Prop topHeight: number = 0;
  @Prop bottomHeight: number = 0;
  @Prop @Watch('onExternalRefresh') refreshTrigger: number = 0;
  @State searchKeyword: string = '';
  @State currentIndex: number = 0;
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = false;

  @State allItems: ItemCard[] = [];
  @State lostItems: ItemCard[] = [];
  @State foundItems: ItemCard[] = [];
  @State claimedItems: ItemCard[] = [];
  @State allItemsEnd: boolean = false;
  @State lostItemsEnd: boolean = false;
  @State foundItemsEnd: boolean = false;
  @State claimedItemsEnd: boolean = false;

  @State isSearchMode: boolean = false;
  @State activeKeyword: string = '';
  @State searchResults: ItemCard[] = [];

  aboutToAppear(): void {
    // 重置静态分页状态，防止退出重登后 ItemService 误判已加载完毕返回空
    ItemService.resetAllPagination();
    // 触发下拉刷新动画并加载数据
    this.isRefreshing = true;
    this.onRefresh();
  }

  onExternalRefresh(): void {
    if (this.refreshTrigger <= 0) return;
    this.allItems = [];
    this.lostItems = [];
    this.foundItems = [];
    this.claimedItems = [];
    this.allItemsEnd = false;
    this.lostItemsEnd = false;
    this.foundItemsEnd = false;
    this.claimedItemsEnd = false;
    ItemService.resetAllPagination();
    this.loadByType('all');
  }

  async loadByType(type: string): Promise<void> {
    this.isLoading = true;
    console.info('[MainPage] 开始加载 type:', type);
    const result = await ItemService.getCardInfoListByType(type);
    console.info('[MainPage] 加载结果数量:', result.length);
    if (type === 'all') { this.allItems = result; }
    else if (type === 'lost') { this.lostItems = result; }
    else if (type === 'find') { this.foundItems = result; }
    else { this.claimedItems = result; }
    this.isLoading = false;
  }

  async loadMoreByType(type: string): Promise<void> {
    if (this.isLoading) { return; }
    this.isLoading = true;
    const more = await ItemService.getCardInfoListByType(type);
    if (more.length > 0) {
      if (type === 'all') { this.allItems = [...this.allItems, ...more]; }
      else if (type === 'lost') { this.lostItems = [...this.lostItems, ...more]; }
      else if (type === 'find') { this.foundItems = [...this.foundItems, ...more]; }
      else { this.claimedItems = [...this.claimedItems, ...more]; }
    } else {
      if (type === 'all') { this.allItemsEnd = true; }
      else if (type === 'lost') { this.lostItemsEnd = true; }
      else if (type === 'find') { this.foundItemsEnd = true; }
      else { this.claimedItemsEnd = true; }
    }
    this.isLoading = false;
  }

  async onRefresh(): Promise<void> {
    const type = this.getCurrentType();
    if (type === 'all') { this.allItems = []; this.allItemsEnd = false; }
    else if (type === 'lost') { this.lostItems = []; this.lostItemsEnd = false; }
    else if (type === 'find') { this.foundItems = []; this.foundItemsEnd = false; }
    else { this.claimedItems = []; this.claimedItemsEnd = false; }
    ItemService.resetPaginationByType(type);
    await this.loadByType(type);
    this.isRefreshing = false;
  }

  getCurrentType(): string {
    if (this.currentIndex === 0) { return 'all'; }
    else if (this.currentIndex === 1) { return 'lost'; }
    else if (this.currentIndex === 2) { return 'find'; }
    else { return 'claimed'; }
  }

  async doSearch(keyword: string): Promise<void> {
    this.activeKeyword = keyword;
    this.isSearchMode = true;
    this.isLoading = true;
    this.searchResults = await ItemService.searchByKeyword(keyword);
    this.isLoading = false;
  }

  clearSearch(): void {
    this.searchKeyword = '';
    this.activeKeyword = '';
    this.isSearchMode = false;
    this.searchResults = [];
  }

  getTabStyle(index: number, title: ResourceStr) {
    return SubTabBarStyle.of(title)
      .indicator({
        color: '#4E8FDF',
        height: 3,
        width: 28,
        marginTop: 6
      })
      .labelStyle({
        selectedColor: '#4E8FDF',
        unselectedColor: $r('app.color.text_secondary'),
        font: {
          size: 16,
          weight: this.currentIndex === index ? FontWeight.Bold : FontWeight.Medium
        }
      })
  }

  build() {
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
      .padding({
        left: 16,
        right: 16,
        top: this.topHeight,
        bottom: 8
      })
      .backgroundColor($r('app.color.bg_card'))

      // 搜索关键词标签
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
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.bg_card'))
      }

      if (!this.isSearchMode) {
        Tabs({ barPosition: BarPosition.Start }) {

          TabContent() {
          Refresh({ refreshing: $$this.isRefreshing }) {
            if (this.isLoading && this.allItems.length === 0) {
              // ✅ 加载中显示转圈
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color('#4E8FDF')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else if (!this.isLoading && this.allItems.length === 0) {
              Column({ space: 8 }) {
                Text('暂无信息').fontSize(16).fontColor($r('app.color.text_hint'))
                Text('下拉刷新试试').fontSize(13).fontColor($r('app.color.text_disabled'))
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              List({ space: 12 }) {
                ForEach(this.allItems, (item: ItemCard) => {
                  ListItem() {
                    ItemCardView({ item: item })
                  }
                }, (item: ItemCard): string => item.itemId.toString())
                if (this.allItemsEnd) {
                  ListItem() {
                    Row() {
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                      Text('已经到底了~').fontSize(12).fontColor($r('app.color.text_hint')).margin({ left: 10, right: 10 })
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 14, bottom: 14 })
                  }
                }
              }
              .width('100%')
              .height('100%')
              .padding({ left: 12, right: 12, top: 12, bottom: this.bottomHeight + 96 })
              .onScrollIndex((start: number, end: number) => {
                if (end >= this.allItems.length - 2 && !this.isLoading) {
                  this.loadMoreByType('all');
                }
              })
            }
          }
          .onRefreshing((): void => { this.onRefresh() })
        }
        .tabBar(this.getTabStyle(0, $r('app.string.all')))

        TabContent() {
          Refresh({ refreshing: $$this.isRefreshing }) {
            if (this.isLoading && this.lostItems.length === 0) {
              // ✅ 加载中显示转圈
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color('#4E8FDF')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else if (!this.isLoading && this.lostItems.length === 0) {
              Column({ space: 8 }) {
                Text('暂无信息').fontSize(16).fontColor($r('app.color.text_hint'))
                Text('下拉刷新试试').fontSize(13).fontColor($r('app.color.text_disabled'))
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              List({ space: 12 }) {
                ForEach(this.lostItems, (item: ItemCard) => {
                  ListItem() {
                    ItemCardView({ item: item })
                  }
                }, (item: ItemCard): string => item.itemId.toString())
                if (this.lostItemsEnd) {
                  ListItem() {
                    Row() {
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                      Text('已经到底了~').fontSize(12).fontColor($r('app.color.text_hint')).margin({ left: 10, right: 10 })
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 14, bottom: 14 })
                  }
                }
              }
              .width('100%')
              .height('100%')
              .padding({ left: 12, right: 12, top: 12, bottom: this.bottomHeight + 96 })
              .onScrollIndex((start: number, end: number) => {
                if (end >= this.lostItems.length - 2 && !this.isLoading) {
                  this.loadMoreByType('lost');
                }
              })
            }
          }
          .onRefreshing((): void => { this.onRefresh() })
        }
        .tabBar(this.getTabStyle(1, $r('app.string.lost')))

        TabContent() {
          Refresh({ refreshing: $$this.isRefreshing }) {
            if (this.isLoading && this.foundItems.length === 0) {
              // ✅ 加载中显示转圈
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color('#4E8FDF')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else if (!this.isLoading && this.foundItems.length === 0) {
              Column({ space: 8 }) {
                Text('暂无信息').fontSize(16).fontColor($r('app.color.text_hint'))
                Text('下拉刷新试试').fontSize(13).fontColor($r('app.color.text_disabled'))
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              List({ space: 12 }) {
                ForEach(this.foundItems, (item: ItemCard) => {
                  ListItem() {
                    ItemCardView({ item: item })
                  }
                }, (item: ItemCard): string => item.itemId.toString())
                if (this.foundItemsEnd) {
                  ListItem() {
                    Row() {
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                      Text('已经到底了~').fontSize(12).fontColor($r('app.color.text_hint')).margin({ left: 10, right: 10 })
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 14, bottom: 14 })
                  }
                }
              }
              .width('100%')
              .height('100%')
              .padding({ left: 12, right: 12, top: 12, bottom: this.bottomHeight + 96 })
              .onScrollIndex((start: number, end: number) => {
                if (end >= this.foundItems.length - 2 && !this.isLoading) {
                  this.loadMoreByType('find');
                }
              })
            }
          }
          .onRefreshing((): void => { this.onRefresh() })
        }
        .tabBar(this.getTabStyle(2, $r('app.string.found')))

        TabContent() {
          Refresh({ refreshing: $$this.isRefreshing }) {
            if (this.isLoading && this.claimedItems.length === 0) {
              // ✅ 加载中显示转圈
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color('#4E8FDF')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else if (!this.isLoading && this.claimedItems.length === 0) {
              Column({ space: 8 }) {
                Text('暂无信息').fontSize(16).fontColor($r('app.color.text_hint'))
                Text('下拉刷新试试').fontSize(13).fontColor($r('app.color.text_disabled'))
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              List({ space: 12 }) {
                ForEach(this.claimedItems, (item: ItemCard) => {
                  ListItem() {
                    ItemCardView({ item: item })
                  }
                }, (item: ItemCard): string => item.itemId.toString())
                if (this.claimedItemsEnd) {
                  ListItem() {
                    Row() {
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                      Text('已经到底了~').fontSize(12).fontColor($r('app.color.text_hint')).margin({ left: 10, right: 10 })
                      Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 14, bottom: 14 })
                  }
                }
              }
              .width('100%')
              .height('100%')
              .padding({ left: 12, right: 12, top: 12, bottom: this.bottomHeight + 96 })
              .onScrollIndex((start: number, end: number) => {
                if (end >= this.claimedItems.length - 2 && !this.isLoading) {
                  this.loadMoreByType('claimed');
                }
              })
            }
          }
          .onRefreshing((): void => { this.onRefresh() })
        }
        .tabBar(this.getTabStyle(3, $r('app.string.claimed')))

      }
      .barBackgroundColor($r('app.color.bg_card'))
      .barMode(BarMode.Fixed)
      .animationDuration(300)
      .onChange((index: number) => {
        this.currentIndex = index;
        const type = this.getCurrentType();
        if (type === 'all') { this.allItems = []; this.allItemsEnd = false; }
        else if (type === 'lost') { this.lostItems = []; this.lostItemsEnd = false; }
        else if (type === 'find') { this.foundItems = []; this.foundItemsEnd = false; }
        else { this.claimedItems = []; this.claimedItemsEnd = false; }
        ItemService.resetPaginationByType(type);
        this.loadByType(type);
      })
      } else {
        // 搜索结果区域
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#4E8FDF')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.searchResults.length === 0) {
          Column({ space: 8 }) {
            Text('未找到相关内容')
              .fontSize(15)
              .fontColor('#AAAAAA')
            Text(`关键词：${this.activeKeyword}`)
              .fontSize(13)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.searchResults, (item: ItemCard) => {
              ListItem() {
                ItemCardView({ item: item })
              }
            }, (item: ItemCard): string => item.itemId.toString())
            ListItem() {
              Row() {
                Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
                Text('已经到底了~').fontSize(12).fontColor($r('app.color.text_hint')).margin({ left: 10, right: 10 })
                Divider().strokeWidth(0.5).color($r('app.color.divider')).layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 14, bottom: 14 })
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12, top: 12, bottom: this.bottomHeight + 96 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}