import { router, curves } from '@kit.ArkUI';
import { AnnouncementService, AnnouncementItem } from '../services/AnnouncementService';
import { ItemService, ItemCard } from '../services/ItemService';
import { HallItemCard } from '../components/HallItemCard';
import { HallItemData } from '../model/HallItemData';

interface QuickActionConfig {
  title: string;
  subtitle: string;
  icon: Resource;
  bg: string;
  color: string;
  action: () => void;
}

@Component
@Entry
export struct FrontPage {
  @Prop topHeight: number = 0;
  @Prop bottomHeight: number = 0;
  @Prop @Watch('onRefreshTriggerChange') refreshTrigger: number = 0;
  @State isRefreshing: boolean = false;
  @State announcements: AnnouncementItem[] = [];
  @State currentAnnouncementIndex: number = 0;
  @State hotItems: HallItemData[] = [];

  @State cardScale: number = 0.8;
  @State cardOpacity: number = 0;

  onOpenHall: () => void = () => {};

  onRefreshTriggerChange(): void {
    if (this.refreshTrigger > 0) {
      this.playPopAnimation();
    }
  }

  onPageShow(): void {
    this.playPopAnimation();
    this.loadAnnouncements();
  }

  aboutToAppear(): void {
    this.playPopAnimation();
    this.loadAnnouncements();
  }

  private async loadAnnouncements(): Promise<void> {
    try {
      this.announcements = await AnnouncementService.list(5);
      const hot = await ItemService.listHot(8);
      const visibleHot = hot.filter((item: ItemCard) => !item.claimedBy && !item.claimedByStudentNo);
      this.hotItems = this.enrichItems(visibleHot.slice(0, 3));
    } catch (e) {
      console.error('[FrontPage] loadAnnouncements failed:', e);
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

  private handleHotCardClick(item: HallItemData): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletRightType', 'detail');
      AppStorage.setOrCreate('tabletRightParams', JSON.stringify(item));
    } else {
      router.pushUrl({ url: 'pages/DetailPage', params: item });
    }
  }

  private updateHotLikeState(itemId: number, likeCount: number): void {
    this.hotItems = this.hotItems.map((it: HallItemData) => {
      if (it.itemId !== itemId) return it;
      const copy = new HallItemData();
      copy.itemId = it.itemId;
      copy.type = it.type;
      copy.text = it.text;
      copy.publishTime = it.publishTime;
      copy.publishId = it.publishId;
      copy.publisherName = it.publisherName;
      copy.publisherAvatar = it.publisherAvatar;
      copy.mediaList = it.mediaList;
      copy.category = it.category;
      copy.likeCount = likeCount;
      copy.status = it.status;
      copy.claimedBy = it.claimedBy;
      copy.claimedByStudentNo = it.claimedByStudentNo;
      copy.lostTime = it.lostTime;
      return copy;
    });
  }

  private playPopAnimation(): void {
    this.cardScale = 0.8;
    this.cardOpacity = 0;

    setTimeout(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.cardOpacity = 1.0;
      });

      animateTo({
        curve: curves.springMotion(0.8, 0.4)
      }, () => {
        this.cardScale = 1.0;
      });
    }, 50);
  }

  private openHall(): void {
    this.onOpenHall();
    AppStorage.setOrCreate('currentIndex', 1);
  }

  private openPost(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
      AppStorage.setOrCreate('tabletRightParams', JSON.stringify({ height: this.topHeight }));
      AppStorage.setOrCreate('tabletRightType', 'post');
      return;
    }
    router.pushUrl({ url: 'pages/PostPage', params: { height: this.topHeight } });
  }

  private openMyPosts(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
      AppStorage.setOrCreate('tabletRightParams', '');
      AppStorage.setOrCreate('tabletRightType', 'myPosts');
      return;
    }
    router.pushUrl({ url: 'pages/MyPostsPage' });
  }

  private openAnnouncement(): void {
    if (this.announcements.length === 0) return;
    const current = this.announcements[this.currentAnnouncementIndex] || this.announcements[0];
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
      AppStorage.setOrCreate('tabletRightParams', JSON.stringify({ id: current.id }));
      AppStorage.setOrCreate('tabletRightType', 'announcementDetail');
    } else {
      router.pushUrl({ url: 'pages/AnnouncementDetailPage', params: { id: current.id } });
    }
  }

  openRanking(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletRightType', 'ranking');
    } else {
      router.pushUrl({ url: 'pages/RankingPage' });
    }
  }

  openWarning(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletRightType', 'warning');
    } else {
      router.pushUrl({ url: 'pages/WarningPage' });
    }
  }

  async doRefresh(): Promise<void> {
    await this.loadAnnouncements();
    setTimeout(() => { this.isRefreshing = false; }, 600);
  }

  @Builder
  HeroSection() {
    Column({ space: 18 }) {
      Row() {
        Column({ space: 6 }) {
          Text('校园失物招领')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('帮物品回到原来的主人身边')
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.82)')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Stack() {
          Circle()
            .width(54)
            .height(54)
            .fill('rgba(255,255,255,0.18)')
          Image($r('app.media.app_icon'))
            .width(38)
            .height(38)
            .borderRadius(10)
        }
        .width(54)
        .height(54)
      }
      .width('100%')

      Row({ space: 10 }) {
        Row({ space: 8 }) {
          Image($r('app.media.ic_public_time'))
            .width(16)
            .height(16)
          Text('实时发布')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor('rgba(255,255,255,0.16)')

        Row({ space: 8 }) {
          Image($r('app.media.like_s'))
            .width(16)
            .height(16)
          Text('热心互助')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor('rgba(255,255,255,0.16)')

        Blank()
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('去大厅看看')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(255,255,255,0.18)')
          .height(40)
          .borderRadius(20)
          .layoutWeight(1)
          .onClick(() => { this.openHall(); })

        Button('我的发布')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(255,255,255,0.18)')
          .height(40)
          .borderRadius(20)
          .layoutWeight(1)
          .onClick(() => { this.openMyPosts(); })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: this.topHeight + 18, bottom: 22 })
    .linearGradient({
      angle: 135,
      colors: [['#2F78E8', 0], ['#38B6A6', 1]]
    })
    .borderRadius({ bottomLeft: 26, bottomRight: 26 })
  }

  @Builder
  QuickActionCard(config: QuickActionConfig) {
    Column({ space: 8 }) {
      Stack() {
        Circle()
          .width(42)
          .height(42)
          .fill(config.bg)
        Image(config.icon)
          .width(24)
          .height(24)
      }
      .width(42)
      .height(42)

      Row()
        .width(22)
        .height(3)
        .borderRadius(2)
        .backgroundColor(config.color)

      Text(config.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(config.subtitle)
        .fontSize(11)
        .fontColor($r('app.color.text_caption'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(118)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(16)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.10)', offsetY: 5 })
    .border({ width: 1, color: $r('app.color.border') })
    .onClick(config.action)
  }

  @Builder
  SectionTitle(title: string, action: string = '') {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      if (action.length > 0) {
        Text(action)
          .fontSize(13)
          .fontColor('#4E8FDF')
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  AnnouncementCard() {
    Column({ space: 12 }) {
      this.SectionTitle('校园公告', '查看')

      Swiper() {
        ForEach(this.announcements.length > 0 ? this.announcements : [{ id: 0, title: '欢迎来到校园失物招领', content: '', cover: null, priority: 0, createdAt: 0 }], (announcement: AnnouncementItem) => {
          Row({ space: 12 }) {
            Stack() {
              Circle()
                .width(42)
                .height(42)
                .fill('rgba(78,143,223,0.12)')
              Image($r('app.media.bill'))
                .width(24)
                .height(24)
            }
            .width(42)
            .height(42)

            Column({ space: 5 }) {
              Text(announcement.title)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text('点击查看公告详情')
                .fontSize(12)
                .fontColor($r('app.color.text_caption'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Image($r('app.media.arrow_right'))
              .width(18)
              .height(18)
              .opacity(0.52)
          }
          .width('100%')
          .height(74)
          .padding({ left: 14, right: 12 })
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_secondary'))
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')
      .height(74)
      .autoPlay(this.announcements.length > 1)
      .interval(4000)
      .indicator(false)
      .onChange((index: number) => { this.currentAnnouncementIndex = index })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(18)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.10)', offsetY: 5 })
    .border({ width: 1, color: $r('app.color.border') })
    .onClick(() => { this.openAnnouncement(); })
  }

  @Builder
  EmptyHotState() {
    Column({ space: 8 }) {
      Image($r('app.media.empty_image'))
        .width(54)
        .height(54)
        .opacity(0.7)
      Text('暂无热门内容')
        .fontSize(14)
        .fontColor($r('app.color.text_caption'))
    }
    .width('100%')
    .height(150)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(16)
  }

  build() {
    Column() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 16 }) {
            this.HeroSection()

            Column({ space: 16 }) {
              Row({ space: 12 }) {
                this.QuickActionCard({
                  title: '寻物大厅',
                  subtitle: '筛选最新线索',
                  icon: $r('app.media.dating_s'),
                  bg: 'rgba(78,143,223,0.12)',
                  color: '#4E8FDF',
                  action: (): void => { this.openHall(); }
                })

                this.QuickActionCard({
                  title: '发布信息',
                  subtitle: '失物/招领登记',
                  icon: $r('app.media.add'),
                  bg: 'rgba(56,182,166,0.14)',
                  color: '#38B6A6',
                  action: (): void => { this.openPost(); }
                })
              }
              .width('100%')

              Row({ space: 12 }) {
                this.QuickActionCard({
                  title: '热心榜',
                  subtitle: '校园互助排行',
                  icon: $r('app.media.startIcon'),
                  bg: 'rgba(255,149,0,0.14)',
                  color: '#FF9500',
                  action: (): void => { this.openRanking(); }
                })

                this.QuickActionCard({
                  title: '失物预警',
                  subtitle: '关注风险提醒',
                  icon: $r('app.media.abnormal'),
                  bg: 'rgba(255,77,109,0.12)',
                  color: '#FF4D6D',
                  action: (): void => { this.openWarning(); }
                })
              }
              .width('100%')

              this.AnnouncementCard()

              Column({ space: 12 }) {
                this.SectionTitle('热门推荐', '')

                if (this.hotItems.length === 0) {
                  this.EmptyHotState()
                } else {
                  Column() {
                    ForEach(this.hotItems, (item: HallItemData, index: number) => {
                      HallItemCard({
                        item,
                        itemIndex: index,
                        onCardClick: (i: HallItemData) => { this.handleHotCardClick(i) },
                        onLikeClick: (itemId: number, _isLiked: boolean, likeCount: number) => {
                          this.updateHotLikeState(itemId, likeCount)
                        }
                      })
                    })
                  }
                  .width('100%')
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding({ left: 14, right: 14, bottom: this.bottomHeight + 110 })
            .scale({ x: this.cardScale, y: this.cardScale })
            .opacity(this.cardOpacity)
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .onRefreshing(() => { this.doRefresh() })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
