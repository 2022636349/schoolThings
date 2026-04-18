import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { cloudDatabase } from '@kit.CloudFoundationKit';
import { AuthService, SessionInfo } from '../services/AuthService';
import { ItemCardView } from './Card';
import { ItemCard, MediaItem, formatTime } from '../services/ItemService';
import { ItemInfo } from '../model/ItemCard';
import { UploadService } from '../services/UploadService';

@Entry
@Component
export struct MyPostsPage {
  @State items: ItemCard[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State currentUser: SessionInfo | null = null;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    AuthService.getSession(getContext(this) as common.UIAbilityContext).then((session) => {
      this.currentUser = session;
      if (session) {
        this.loadMyPosts(session.id);
      } else {
        this.isLoading = false;
      }
    });
  }

  async loadMyPosts(userId: string): Promise<void> {
    this.isLoading = true;
    try {
      const db = cloudDatabase.zone('User');
      const q = new cloudDatabase.DatabaseQuery(ItemInfo)
        .equalTo('publishId', userId)
        .orderByDesc('itemId');
      const result = (await db.query(q)) as ItemInfo[];
      const itemList = result || [];
      const cards: ItemCard[] = [];
      for (const info of itemList) {
        let mediaList: MediaItem[] = [];
        try {
          const rawMedia = JSON.parse(info.resource) as MediaItem[];
          const resolvedMedia: MediaItem[] = [];
          for (const m of rawMedia) {
            let url = m.url;
            if (url && !url.startsWith('http')) {
              url = await UploadService.getDownloadURL(url);
            }
            resolvedMedia.push({ type: m.type, url });
          }
          mediaList = resolvedMedia;
        } catch (e) {
          mediaList = [];
        }
        cards.push({
          itemId: info.itemId,
          type: info.type,
          text: info.text,
          publishTime: info.publishTime ? formatTime(new Date(info.publishTime)) : '',
          publishId: info.publishId,
          publisherName: this.currentUser?.name || info.publishId,
          publisherAvatar: this.currentUser?.avatar || '',
          mediaList: mediaList
        } as ItemCard);
      }
      this.items = cards;
    } catch (e) {
      console.error('[MyPostsPage] 加载失败:', e);
    } finally {
      this.isLoading = false;
    }
  }

  async doRefresh(): Promise<void> {
    if (this.currentUser) {
      await this.loadMyPosts(this.currentUser.id);
    }
    this.isRefreshing = false;
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.icon_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary')).justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (AppStorage.get<boolean>('isTabletMode') === true) {
            const prev = AppStorage.get<string>('tabletPrevRightType') || 'none';
            const prevParams = AppStorage.get<string>('tabletPrevRightParams') || '';
            AppStorage.setOrCreate('tabletRightParams', prevParams);
            AppStorage.setOrCreate('tabletRightType', prev);
            AppStorage.setOrCreate('tabletPrevRightType', 'none');
            AppStorage.setOrCreate('tabletPrevRightParams', '');
          } else {
            router.back();
          }
        })

        Text('我的发布')
          .fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topHeight + 10, bottom: 14 })
      .backgroundColor($r('app.color.bg_card'))
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })

      Refresh({ refreshing: $$this.isRefreshing }) {
        List({ space: 12 }) {
          if (this.isLoading) {
            ListItem() {
              Column() {
                LoadingProgress().width(40).height(40).color('#4E8FDF')
              }
              .width('100%').height(300).justifyContent(FlexAlign.Center)
            }
          } else if (this.items.length === 0) {
            ListItem() {
              Column({ space: 12 }) {
                Text('📭').fontSize(48)
                Text('暂无发布记录')
                  .fontSize(16).fontColor($r('app.color.text_hint'))
                Text('发布第一条寻物或招领信息吧')
                  .fontSize(13).fontColor($r('app.color.text_disabled'))
              }
              .width('100%').height(300)
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
            }
          } else {
            ForEach(this.items, (item: ItemCard) => {
              ListItem() {
                ItemCardView({ item: item })
              }
            }, (item: ItemCard): string => item.itemId.toString())
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
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
