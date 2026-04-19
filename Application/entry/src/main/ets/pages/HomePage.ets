import {HallPage} from './HallPage'
import {MessagePage} from './MessagePage'
import {PersonalPage} from './PersonalPage'
import {DetailPage} from './DetailPage'
import {ChatPage} from './ChatPage'
import {MyPostsPage} from './MyPostsPage'
import {FrontPage} from './FrontPage'
import {RankingPage} from './RankingPage'
import {WarningPage} from './WarningPage'
import {MyClaimedPage} from './MyClaimedPage'
import { router, window, display } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { AuthService } from '../services/AuthService';
import { preferences } from '@kit.ArkData';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { pushService } from '@kit.PushKit';

interface TabItem {
  title: ResourceStr;
  icon: Resource;
  icon_s: Resource;
}

@Entry
@Component
struct HomePage {
  // 4+1 结构：0=首页 1=大厅 [中间+按钮] 2=消息 3=我的
  @State currentIndex: number = 0;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;
  @State scaleList: number[] = [1, 1, 1, 1];
  @State sliderScale: number = 1.0;
  @State capsuleScale: number = 1.0;
  @State addBtnScale: number = 1.0;
  @State mainPageRefreshTrigger: number = 0;
  @State hasUnreadMessage: boolean = false;
  @State isTablet: boolean = false;
  @StorageProp('tabletRightType') @Watch('onRightPanelChange') rightPanelType: string = 'none';
  @StorageProp('tabletRightParams') rightPanelParams: string = '';
  @StorageProp('widgetAction') @Watch('onWidgetAction') widgetAction: string = '';
  private unreadPollTimer: number = -1;
  private lastNotifyTime: number = 0;
  private currentUserId: string = '';

  // 消息 tab 索引（便于集中管理）
  private readonly MESSAGE_TAB_INDEX: number = 2;

  aboutToAppear(): void {
    const screenWidth = px2vp(display.getDefaultDisplaySync().width);
    this.isTablet = screenWidth >= 600;
    AppStorage.setOrCreate('isTabletMode', this.isTablet);
    AppStorage.setOrCreate('tabletRightType', 'none');
    AppStorage.setOrCreate('tabletRightParams', '');
    AppStorage.setOrCreate('tabletPrevRightType', 'none');
    AppStorage.setOrCreate('tabletPrevRightParams', '');

    window.getLastWindow(getContext(this)).then((win) => {
      let topArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let bottomArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.topHeight = px2vp(topArea.topRect.height);
      this.bottomHeight = px2vp(bottomArea.bottomRect.height);
    });
    this.initUnreadPolling();
  }

  aboutToDisappear(): void {
    if (this.unreadPollTimer !== -1) {
      clearInterval(this.unreadPollTimer);
      this.unreadPollTimer = -1;
    }
  }

  onPageShow(): void {
    if (AppStorage.get<boolean>('homeNeedRefresh') === true) {
      AppStorage.setOrCreate('homeNeedRefresh', false);
      this.mainPageRefreshTrigger++;
    }
    if (this.currentIndex === this.MESSAGE_TAB_INDEX) {
      this.hasUnreadMessage = false;
      this.saveLastReadTime();
    }
    if (this.currentUserId) {
      this.pollUnread(false);
    }
    const pendingRefresh = AppStorage.get<number>('messageListRefresh') || 0;
    if (pendingRefresh > 0 && this.currentUserId) {
      this.pollUnread(false);
    }
    const pendingAction = AppStorage.get<string>('widgetAction');
    if (pendingAction && pendingAction.length > 0) {
      this.onWidgetAction();
    }
  }

  onRightPanelChange(): void {
    // 右侧面板变化时的处理（预留）
  }

  onWidgetAction(): void {
    if (!this.widgetAction) return;
    const action = this.widgetAction;
    AppStorage.setOrCreate('widgetAction', '');
    if (action === 'message') {
      this.switchTab(this.MESSAGE_TAB_INDEX);
    } else if (action === 'post') {
      router.pushUrl({ url: 'pages/PostPage', params: { height: this.topHeight } });
    }
  }

  // ── 消息未读轮询 & 通知 ──

  async initUnreadPolling(): Promise<void> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        await notificationManager.requestEnableNotification(getContext(this) as common.UIAbilityContext);
      }
    } catch (e) {
      console.warn('[HomePage] notification permission:', e);
    }
    const session = await AuthService.getSession(getContext(this) as common.UIAbilityContext);
    if (session) {
      this.currentUserId = session.id;
      this.pollUnread();
      this.unreadPollTimer = setInterval(() => { this.pollUnread(); }, 10000);
      this.syncPushToken();
    }
  }

  private async syncPushToken(): Promise<void> {
    try {
      const token = await pushService.getToken();
      if (token) {
        await AuthService.savePushToken(getContext(this) as common.UIAbilityContext, token);
      }
    } catch (e) {
      console.error('[HomePage] syncPushToken failed:', JSON.stringify(e));
    }
  }

  async pollUnread(showNotification: boolean = true): Promise<void> {
    if (!this.currentUserId) return;
    try {
      const store = preferences.getPreferencesSync(getContext(this), { name: 'message_state' });
      let lastReadTime = store.getSync('lastReadTime', 0) as number;
      if (lastReadTime === 0) {
        lastReadTime = Date.now();
        store.putSync('lastReadTime', lastReadTime);
        store.flush();
        return;
      }

      const sessions = await ChatService.getSessionsForUser(this.currentUserId);
      const lastReadMsgIdMap: Record<string, number> = {};
      const hiddenMap: Record<string, number> = {};
      for (const s of sessions) {
        lastReadMsgIdMap[s.sessionId] = store.getSync('lastReadMsgId_' + s.sessionId, 0) as number;
        hiddenMap[s.sessionId] = store.getSync('hidden_' + s.sessionId, 0) as number;
      }
      const summary = await ChatService.getUnreadSummary(this.currentUserId, lastReadMsgIdMap, hiddenMap);
      const hasUnread = summary.count > 0;

      if (hasUnread) {
        if (!this.hasUnreadMessage) {
          this.hasUnreadMessage = true;
          if (showNotification && this.currentIndex !== this.MESSAGE_TAB_INDEX) {
            this.showMessageNotification(summary.latest);
          }
        }
      } else {
        this.hasUnreadMessage = false;
      }
      this.updateWidgetData(summary.count, summary.latest);
    } catch (e) {
      console.error('[HomePage] pollUnread failed:', e);
    }
  }

  private updateWidgetData(unreadCount: number, latestMessage: string): void {
    try {
      const widgetStore = preferences.getPreferencesSync(getContext(this), { name: 'widget_data' });
      widgetStore.putSync('unreadCount', unreadCount);
      widgetStore.putSync('latestMessage', latestMessage);
      widgetStore.flush();
      const formIdStore = preferences.getPreferencesSync(getContext(this), { name: 'widget_form_ids' });
      const allKeys = formIdStore.getAllSync();
      const keys = Object.keys(allKeys);
      if (keys.length === 0) return;
      const data: Record<string, Object> = {};
      data['unreadCount'] = unreadCount;
      data['latestMessage'] = latestMessage;
      const bindingData = formBindingData.createFormBindingData(data);
      for (const formId of keys) {
        formProvider.updateForm(formId, bindingData).catch((err: Error) => {
          console.warn('[HomePage] updateForm failed for ' + formId, err);
        });
      }
    } catch (e) {
      console.error('[HomePage] updateWidgetData failed:', e);
    }
  }

  async showMessageNotification(content: string): Promise<void> {
    const now = Date.now();
    if (now - this.lastNotifyTime < 30000) return;
    this.lastNotifyTime = now;
    try {
      let request: notificationManager.NotificationRequest = {
        id: 1001,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '校园失物招领 - 新消息',
            text: content
          }
        }
      };
      await notificationManager.publish(request);
    } catch (e) {
      console.error('[HomePage] notification publish failed:', e);
    }
  }

  saveLastReadTime(): void {
    const store = preferences.getPreferencesSync(getContext(this), { name: 'message_state' });
    store.putSync('lastReadTime', Date.now());
    store.flush();
  }

  // ── 导航栏逻辑 ──

  private tabItems: TabItem[] = [
    { title: $r('app.string.homepage_front'), icon: $r('app.media.frontpage'), icon_s: $r('app.media.frontpage_s') },
    { title: $r('app.string.homepage_hall'),  icon: $r('app.media.dating'), icon_s: $r('app.media.dating_s') },
    { title: $r('app.string.homepage_message'), icon: $r('app.media.message'), icon_s: $r('app.media.message_s') },
    { title: $r('app.string.homepage_my'),      icon: $r('app.media.my'),      icon_s: $r('app.media.my_s') }
  ];

  switchTab(index: number): void {
    this.currentIndex = index;

    if (this.isTablet) {
      if (index === 0 || index === 1) {
        AppStorage.setOrCreate('tabletRightType', 'none');
      } else if (index === 2) {
        AppStorage.setOrCreate('tabletRightType', 'message');
      } else if (index === 3) {
        AppStorage.setOrCreate('tabletRightType', 'personal');
      }
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
    }

    if (index === this.MESSAGE_TAB_INDEX) {
      this.hasUnreadMessage = false;
      this.saveLastReadTime();
    }

    // 胶囊 / slider 弹动
    this.capsuleScale = 1.06;
    setTimeout(() => { this.capsuleScale = 1.0; }, 220);
    this.sliderScale = 1.2;
    setTimeout(() => { this.sliderScale = 1.0; }, 300);
    let s1 = [1.0, 1.0, 1.0, 1.0];
    s1[index] = 1.4;
    this.scaleList = s1;
    setTimeout(() => {
      let s2 = [1.0, 1.0, 1.0, 1.0];
      s2[index] = 0.85;
      this.scaleList = s2;
      setTimeout(() => { this.scaleList = [1.0, 1.0, 1.0, 1.0]; }, 150);
    }, 150);
  }

  getScale(index: number): number {
    return this.scaleList[index] ?? 1.0;
  }

  // 中间加号按钮点击
  onAddClick(): void {
    this.addBtnScale = 0.88;
    setTimeout(() => { this.addBtnScale = 1.0; }, 180);
    router.pushUrl({ url: 'pages/PostPage', params: { height: this.topHeight } });
  }

  // slider 气泡在 4 个 tab 上的位移（跳过中间的 + 区域）
  // 布局：[tab0 22%][tab1 22%][+ 12% 间距][tab2 22%][tab3 22%]
  // 气泡宽 18%，其左边距随 currentIndex 变化
  getBubbleLeft(): string {
    // 气泡 anchor 左边距
    if (this.currentIndex === 0) return '2%';
    if (this.currentIndex === 1) return '22%';
    if (this.currentIndex === 2) return '61%';
    return '81%';
  }

  // ── 构建 ──

  build() {
    if (this.isTablet) {
      this.buildTabletLayout()
    } else {
      this.buildPhoneLayout()
    }
  }

  // ── 手机布局 ──
  @Builder
  buildPhoneLayout() {
    Stack({ alignContent: Alignment.Bottom }) {

      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          FrontPage({ topHeight: this.topHeight, bottomHeight: this.bottomHeight })
        }
        TabContent() {
          HallPage({ topHeight: this.topHeight, bottomHeight: this.bottomHeight, refreshTrigger: this.mainPageRefreshTrigger })
        }
        TabContent() {
          MessagePage({ topHeight: this.topHeight })
        }
        TabContent() {
          PersonalPage({ topHeight: this.topHeight })
        }
      }
      .scrollable(false)
      .onChange((index: number) => { this.currentIndex = index })
      .animationDuration(0)
      .barHeight(0)
      .width('100%')
      .height('100%')

      // 悬浮导航胶囊（包含 4 tab + 凸起的 + 按钮）
      this.buildNavCapsuleWithAdd()
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ── 平板布局 ──
  @Builder
  buildTabletLayout() {
    Row() {
      Stack({ alignContent: Alignment.Bottom }) {
        if (this.currentIndex === 0) {
          FrontPage({ topHeight: this.topHeight, bottomHeight: this.bottomHeight })
        } else {
          HallPage({ topHeight: this.topHeight, bottomHeight: this.bottomHeight, refreshTrigger: this.mainPageRefreshTrigger })
        }

        // 导航胶囊（含 + 按钮）
        this.buildNavCapsuleWithAdd()
      }
      .width('40%')
      .height('100%')
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && this.currentIndex > 1) {
          this.currentIndex = 0;
        }
      })

      Column()
        .width(0.5)
        .height('100%')
        .backgroundColor($r('app.color.divider'))

      Column() {
        if (this.rightPanelType === 'message') {
          MessagePage({ topHeight: this.topHeight })
        } else if (this.rightPanelType === 'personal') {
          PersonalPage({ topHeight: this.topHeight })
        } else if (this.rightPanelType === 'detail') {
          DetailPage({ paramsJson: this.rightPanelParams })
        } else if (this.rightPanelType === 'chat') {
          ChatPage({ paramsJson: this.rightPanelParams })
        } else if (this.rightPanelType === 'myPosts') {
          MyPostsPage()
        } else if (this.rightPanelType === 'ranking') {
          RankingPage()
        } else if (this.rightPanelType === 'warning') {
          WarningPage()
        } else if (this.rightPanelType === 'myClaimed') {
          MyClaimedPage()
        } else {
          Column() {
            Image($r('app.media.startIcon'))
              .width(64).height(64).opacity(0.15)
              .margin({ bottom: 16 })
            Text('点击左侧内容查看详情')
              .fontSize(15)
              .fontColor($r('app.color.text_hint'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ── 4 tab 胶囊 + 中央凸起 + 按钮 ──
  @Builder
  buildNavCapsuleWithAdd() {
    Stack({ alignContent: Alignment.Top }) {
      // 胶囊主体（4 tabs）
      this.buildNavCapsule()

      // 中央凸起的 + 按钮（提升到胶囊上方约 14vp）
      Stack() {
        // 主体
        Column() {
          Image($r('app.media.add'))
            .width(32).height(32)
            .fillColor('#FFFFFF')
        }
        .width(52).height(52)
        .borderRadius(26)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .linearGradient({
          angle: 135,
          colors: [['#4E8FDF', 0], ['#6FA5E5', 0.5], ['#8FBBEB', 1]]
        })
        .shadow({ radius: 14, color: 'rgba(78,143,223,0.45)', offsetY: 6 })
      }
      .width(58).height(58)
      .offset({ y: 22 })
      .scale({ x: this.addBtnScale, y: this.addBtnScale })
      .animation({ duration: 200, curve: Curve.FastOutSlowIn })
      .onClick(() => { this.onAddClick() })
    }
    .margin({ bottom: this.bottomHeight + 16 })
    .width('95%')
    .height(86) // 64 胶囊 + 22 凸起
  }

  @Builder
  buildNavCapsule() {
    Row() {
      Stack({ alignContent: Alignment.Start }) {

        // 玻璃主体
        Row()
          .width('100%').height('100%')
          .borderRadius(31)
          .backdropBlur(8)
          .backgroundColor('rgba(255, 255, 255, 0.12)')

        // 液态气泡（4 tab 的选中背景）
        Row()
          .margin({ left: this.getBubbleLeft() })
          .width('17%')
          .height('76%')
          .backgroundColor('rgba(255, 255, 255, 0.22)')
          .borderRadius(32)
          .shadow({ radius: 10, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
          .scale({ x: this.sliderScale, y: this.sliderScale })
          .animation({ duration: 350, curve: Curve.FastOutSlowIn })

        // Tab 图标 + 中间留白
        Row() {
          // Tab 0
          this.buildTabSlot(0)
          // Tab 1
          this.buildTabSlot(1)
          // 中间占位（容纳凸起 + 按钮的投影区）
          Column()
            .width('20%').height('100%')
          // Tab 2
          this.buildTabSlot(2)
          // Tab 3
          this.buildTabSlot(3)
        }
        .width('100%').height('100%')

      }
      .width('100%').height('100%')
      .borderRadius(31)
      .clip(true)
    }
    .position({ x: 0, y: 22 }) // 胶囊往下偏，让 + 凸出在胶囊顶部
    .width('100%')
    .height(64)
    .borderRadius(32)
    .padding(1)
    .linearGradient({
      angle: 145,
      colors: [
        ['rgba(255,255,255,0.82)', 0],
        ['rgba(255,255,255,0.30)', 0.42],
        ['rgba(0,0,0,0.20)', 1]
      ]
    })
    .shadow({ radius: 36, color: 'rgba(0, 0, 0, 0.20)', offsetY: 12 })
    .scale({ x: this.capsuleScale, y: this.capsuleScale })
    .animation({ duration: 250, curve: Curve.FastOutSlowIn })
  }

  @Builder
  buildTabSlot(index: number) {
    Column({ space: 2 }) {
      Stack() {
        Image(this.currentIndex === index ? this.tabItems[index].icon_s : this.tabItems[index].icon)
          .width(22).height(22)
          .scale({ x: this.getScale(index), y: this.getScale(index) })
          .animation({ duration: 200, curve: Curve.FastOutSlowIn })
        if (index === this.MESSAGE_TAB_INDEX && this.hasUnreadMessage && this.currentIndex !== this.MESSAGE_TAB_INDEX) {
          Circle()
            .width(8).height(8)
            .fill('#FF3B30')
            .offset({ x: 8, y: -2 })
        }
      }
      Text(this.tabItems[index].title)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? '#4E8FDF' : $r('app.color.text_tertiary'))
        .scale({ x: this.getScale(index), y: this.getScale(index) })
        .animation({ duration: 200, curve: Curve.FastOutSlowIn })
    }
    .width('20%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.switchTab(index) })
  }
}
