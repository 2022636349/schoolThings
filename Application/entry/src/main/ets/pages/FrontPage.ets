import { router, curves } from '@kit.ArkUI';
import { AnnouncementService, AnnouncementItem } from '../services/AnnouncementService';
import { ItemService, ItemCard } from '../services/ItemService';
import { TopNavBar } from '../components/TopNavBar';

/**
 * 首页（Phase 1 骨架版）
 * - 顶部公告轮播占位
 * - 表彰排行 / 失物预警 入口
 * - 热门推荐占位
 * 真实内容在 Phase 4 填充（Announcement 查询、HeartValue 排行、likeCount 推荐）
 */
@Component
@Entry
export struct FrontPage {
  @Prop topHeight: number = 0;
  @Prop bottomHeight: number = 0;
  @State isRefreshing: boolean = false;
  @State announcements: AnnouncementItem[] = [];
  @State currentAnnouncementIndex: number = 0;
  @State hotItems: ItemCard[] = [];

  // 🚀 控制卡片缩放比例和透明度的状态变量
  @State cardScale: number = 0.8;
  @State cardOpacity: number = 0;

  onPageShow() {
    this.playPopAnimation();
    this.loadAnnouncements();
  }

  aboutToAppear() {
    this.playPopAnimation();
    this.loadAnnouncements();
  }

  private async loadAnnouncements(): Promise<void> {
    try {
      this.announcements = await AnnouncementService.list(5);
      this.hotItems = await ItemService.listHot(3);
    } catch (e) {
      console.error('[FrontPage] loadAnnouncements failed:', e);
    }
  }

  // 🚀 弹簧动画逻辑
  private playPopAnimation() {
    // 1. 初始化为缩小且透明的状态
    this.cardScale = 0.8;
    this.cardOpacity = 0;

    // 2. 稍微延迟等待 UI 渲染完成再触发动画
    setTimeout(() => {
      // 动画 A：透明度渐变（使用平滑过渡，不需要回弹）
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.cardOpacity = 1.0;
      });

      // 动画 B：缩放比例（使用弹簧曲线，自带回弹震荡效果）
      // curves.springMotion 参数解析：
      // - 第一个参数 0.5 是 response (响应时长，控制动画快慢)
      // - 第二个参数 0.5 是 dampingFraction (阻尼系数，0-1之间，越小弹跳越猛烈，0.5 恰到好处)
      animateTo({
        curve: curves.springMotion(0.8, 0.4)
      }, () => {
        this.cardScale = 1.0;
      });
    }, 50);
  }

  private openAnnouncement(): void {
    if (this.announcements.length === 0) return;
    const current = this.announcements[this.currentAnnouncementIndex] || this.announcements[0];
    router.pushUrl({ url: 'pages/AnnouncementDetailPage', params: { id: current.id } });
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

  private buildDetailParams(item: ItemCard): Record<string, Object> {
    const p: Record<string, Object> = {};
    p['itemId'] = item.itemId;
    p['type'] = item.type || 'lost';
    p['text'] = item.text || '热门物品';
    p['publishTime'] = item.publishTime || '';
    p['publishId'] = item.publishId || '';
    p['publisherName'] = item.publisherName || '匿名用户';
    p['publisherAvatar'] = item.publisherAvatar || '';
    p['mediaList'] = JSON.stringify(item.mediaList || []);
    p['category'] = item.category || '其他';
    p['likeCount'] = item.likeCount || 0;
    p['status'] = item.status || 'active';
    p['claimedBy'] = item.claimedBy || '';
    p['lostTime'] = item.lostTime || 0;
    return p;
  }

  async doRefresh(): Promise<void> {
    await this.loadAnnouncements();
    setTimeout(() => { this.isRefreshing = false; }, 600);
  }

  build() {
    Column() {
      TopNavBar({ title: '首页' }).padding({ top: this.topHeight })

      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 16 }) {

            // ── 公告轮播 ──
            Stack({ alignContent: Alignment.Bottom }) {
              Swiper() {
                ForEach(this.announcements.length > 0 ? this.announcements : [{ id: 0, title: '欢迎来到校园失物招领', content: '', cover: null, priority: 0, createdAt: 0 }], (announcement: AnnouncementItem) => {
                  Column() {
                    Row() {
                      Text('📢')
                        .fontSize(28)
                      Column({ space: 4 }) {
                        Text('校园公告')
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#FFFFFF')
                        Text(announcement.title)
                          .fontSize(12)
                          .fontColor('rgba(255,255,255,0.85)')
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .margin({ left: 14 })
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                  }
                  .width('100%')
                  .height(130)
                  .padding(18)
                  .borderRadius(16)
                  .linearGradient({
                    angle: 135,
                    colors: [['#4E8FDF', 0], ['#7AAEE8', 0.6], ['#B5D1F2', 1]]
                  })
                  .justifyContent(FlexAlign.Center)
                })
              }
              .width('100%')
              .height(130)
              .autoPlay(this.announcements.length > 1)
              .interval(4000)
              .indicator(this.announcements.length > 1)
              .onChange((index: number) => { this.currentAnnouncementIndex = index })
            }
            .width('100%')
            .onClick(() => { this.openAnnouncement() })
            // 🚀 绑定状态变量
            .scale({ x: this.cardScale, y: this.cardScale })
            .opacity(this.cardOpacity)


            // ── 功能入口：表彰排行 + 失物预警 ──
            Row({ space: 12 }) {
              // 表彰排行
              Column({ space: 6 }) {
                Text('🏆').fontSize(32)
                Text('表彰排行')
                  .fontSize(15).fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                Text('热心榜 TOP 10')
                  .fontSize(11).fontColor($r('app.color.text_hint'))
              }
              .layoutWeight(1).height(120)
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              .backgroundColor($r('app.color.bg_card')).borderRadius(14)
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
              .onClick(() => { this.openRanking() })

              // 失物预警
              Column({ space: 6 }) {
                Text('⚠️').fontSize(32)
                Text('失物预警')
                  .fontSize(15).fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                Text('15 天公示中')
                  .fontSize(11).fontColor($r('app.color.text_hint'))
              }
              .layoutWeight(1).height(120)
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              .backgroundColor($r('app.color.bg_card')).borderRadius(14)
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
              .onClick(() => { this.openWarning() })
            }
            .width('100%')
            // 🚀 绑定状态变量
            .scale({ x: this.cardScale, y: this.cardScale })
            .opacity(this.cardOpacity)


            // ── 热门推荐 ──
            Column({ space: 12 }) {
              Row({ space: 6 }) {
                Row().width(3).height(16).borderRadius(2).backgroundColor('#4E8FDF')
                Text('🔥 热门推荐')
                  .fontSize(16).fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
              }
              .width('100%').alignItems(VerticalAlign.Center)

              if (this.hotItems.length === 0) {
                Column() {
                  Text('暂无热门内容')
                    .fontSize(14).fontColor($r('app.color.text_hint'))
                }
                .width('100%').height(160)
                .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                .backgroundColor($r('app.color.bg_card')).borderRadius(14)
              } else {
                Column({ space: 10 }) {
                  ForEach(this.hotItems, (item: ItemCard) => {
                    Row({ space: 8 }) {
                      Text('•').fontSize(14).fontColor('#4E8FDF')
                      Text(item.text || '热门物品')
                        .fontSize(14)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                      Text(`❤️ ${item.likeCount}`)
                        .fontSize(12)
                        .fontColor($r('app.color.text_hint'))
                    }
                    .width('100%')
                    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                    .backgroundColor($r('app.color.bg_card'))
                    .borderRadius(12)
                    .onClick(() => {
                      const p = this.buildDetailParams(item);
                      if (AppStorage.get<boolean>('isTabletMode') === true) {
                        AppStorage.setOrCreate('tabletPrevRightType', 'none');
                        AppStorage.setOrCreate('tabletRightType', 'detail');
                        AppStorage.setOrCreate('tabletRightParams', JSON.stringify(p));
                      } else {
                        router.pushUrl({ url: 'pages/DetailPage', params: p });
                      }
                    })
                  })
                }
                .width('100%')
              }
            }
            .width('100%')
            // 🚀 绑定状态变量
            .scale({ x: this.cardScale, y: this.cardScale })
            .opacity(this.cardOpacity)

          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: this.bottomHeight + 110 })
        }
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .onRefreshing(() => { this.doRefresh() })
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}