import {HallPage} from './HallPage'
import {MessagePage} from './MessagePage'
import {PersonalPage} from './PersonalPage'
import {DetailPage} from './DetailPage'
import {ChatPage} from './ChatPage'
import {MyPostsPage} from './MyPostsPage'
import {MyLikedPage} from './MyLikedPage'
import {MyReportsPage} from './MyReportsPage'
import {FeedbackPage} from './FeedbackPage'
import {SettingsPage} from './SettingsPage'
import {FrontPage} from './FrontPage'
import {RankingPage} from './RankingPage'
import {WarningPage} from './WarningPage'
import {AnnouncementDetailPage} from './AnnouncementDetailPage'
import {PostPage} from './PostPage'
import { router, window, display } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { AuthService } from '../services/AuthService';
import { AnnouncementService } from '../services/AnnouncementService';
import { ItemService } from '../services/ItemService';
import { preferences } from '@kit.ArkData';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { pushService } from '@kit.PushKit';
import { MeteorOverlay } from '../components/MeteorOverlay';

interface TabItem {
  title: ResourceStr;
  icon: Resource;
  icon_s: Resource;
}

@Entry
@Component
struct HomePage {

  @StorageProp('tabletRightType') @Watch('onRightPanelChange') rightPanelType: string = 'none';
  @StorageProp('tabletRightParams') rightPanelParams: string = '';
  @StorageProp('widgetAction') @Watch('onWidgetAction') widgetAction: string = '';
  @StorageProp('currentIndex') currentIndex: number = 0;
  @StorageProp('messageListRefresh') @Watch('onMessageListRefresh') messageListRefreshTrigger: number = 0;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;
  @State scaleList: number[] = [1, 1, 1, 1];
  @State sliderScale: number = 1.0;
  @State capsuleScale: number = 1.0;
  @State addBtnScale: number = 1.0;
  @State mainPageRefreshTrigger: number = 0;
  @State frontPageAnimationTrigger: number = 0;
  @State hallPageAnimationTrigger: number = 0;
  @State hasUnreadMessage: boolean = false;
  @State isTablet: boolean = false;

  @StorageProp('isOnline') isOnline: boolean = true;
  private unreadPollTimer: number = -1;
  private lastNotifyTime: number = 0;
  private lastMessageListRefreshTime: number = 0;
  private currentUserId: string = '';

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
    this.handleWidgetNavigation();
    if (this.currentUserId) {
      this.pollUnread(false);
    }
    const pendingRefresh = AppStorage.get<number>('messageListRefresh') || 0;
    if (pendingRefresh > 0 && this.currentUserId) {
      this.pollUnread(false);
    }
  }

  private async handleWidgetNavigation(): Promise<void> {
    const pendingAction = AppStorage.get<string>('widgetAction');
    if (pendingAction && pendingAction.length > 0) {
      this.onWidgetAction();
      return;
    }
    const pendingAnnouncementId = AppStorage.get<string>('widgetAnnouncementId');
    if (pendingAnnouncementId && pendingAnnouncementId.length > 0) {
      AppStorage.setOrCreate('widgetAnnouncementId', '');
      if (AppStorage.get<boolean>('isTabletMode') === true) {
        AppStorage.setOrCreate('tabletPrevRightType', 'none');
        AppStorage.setOrCreate('tabletPrevRightParams', '');
        AppStorage.setOrCreate('tabletRightParams', JSON.stringify({ id: Number(pendingAnnouncementId) }));
        AppStorage.setOrCreate('tabletRightType', 'announcementDetail');
      } else {
        router.pushUrl({ url: 'pages/AnnouncementDetailPage', params: { id: Number(pendingAnnouncementId) } });
      }
      return;
    }
    const pendingHotItemId = AppStorage.get<string>('widgetHotItemId');
    if (pendingHotItemId && pendingHotItemId.length > 0) {
      AppStorage.setOrCreate('widgetHotItemId', '');
      ItemService.detail(Number(pendingHotItemId)).then((hot) => {
        if (!hot) {
          return;
        }
        if (AppStorage.get<boolean>('isTabletMode') === true) {
          AppStorage.setOrCreate('tabletPrevRightType', 'none');
          AppStorage.setOrCreate('tabletPrevRightParams', '');
          AppStorage.setOrCreate('tabletRightParams', JSON.stringify(hot));
          AppStorage.setOrCreate('tabletRightType', 'detail');
        } else {
          router.pushUrl({ url: 'pages/DetailPage', params: hot });
        }
      }).catch((e: Error) => {
        console.error('[HomePage] handleWidgetNavigation hot detail failed:', e);
      });
    }
  }

  onRightPanelChange(): void {

  }

  onMessageListRefresh(): void {
    if (this.currentUserId) {
      this.pollUnread(false, false);
    }
  }

  private refreshMessageListIfNeeded(): void {
    const now = Date.now();
    if (now - this.lastMessageListRefreshTime < 1200) return;
    this.lastMessageListRefreshTime = now;
    AppStorage.setOrCreate('messageListRefresh', now);
  }

  onWidgetAction(): void {
    if (!this.widgetAction) return;
    const action = this.widgetAction;
    AppStorage.setOrCreate('widgetAction', '');
    if (action === 'message') {
      this.switchTab(this.MESSAGE_TAB_INDEX);
    } else if (action === 'post') {
      if (this.isTablet) {
        AppStorage.setOrCreate('tabletPrevRightType', 'none');
        AppStorage.setOrCreate('tabletPrevRightParams', '');
        AppStorage.setOrCreate('tabletRightParams', JSON.stringify({ height: this.topHeight }));
        AppStorage.setOrCreate('tabletRightType', 'post');
      } else {
        router.pushUrl({ url: 'pages/PostPage', params: { height: this.topHeight } });
      }
    }
  }

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

  async pollUnread(showNotification: boolean = true, refreshVisibleList: boolean = true): Promise<void> {
    if (!this.currentUserId) return;
    try {
      const store = preferences.getPreferencesSync(getContext(this), { name: 'message_state' });
      let lastReadTime = store.getSync('lastReadTime', 0) as number;
      if (lastReadTime === 0) {
        store.putSync('lastReadTime', Date.now());
        store.flush();
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
        if (refreshVisibleList && this.currentIndex === this.MESSAGE_TAB_INDEX) {
          this.refreshMessageListIfNeeded();
        }
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
      this.updateWidgetContent(widgetStore).then(() => {
        widgetStore.flush();
        this.refreshWidgetForms(unreadCount, latestMessage);
      });
    } catch (e) {
      console.error('[HomePage] updateWidgetData failed:', e);
    }
  }

  private async updateWidgetContent(widgetStore: preferences.Preferences): Promise<void> {
    try {
      const announcements = await AnnouncementService.list(1);
      widgetStore.putSync('announcementTitle', announcements.length > 0 ? announcements[0].title : '');
      widgetStore.putSync('announcementId', announcements.length > 0 ? String(announcements[0].id) : '');
    } catch (e) {
      widgetStore.putSync('announcementTitle', '');
    }
    try {
      const hot = await ItemService.listHot(1);
      widgetStore.putSync('hotTitle', hot.length > 0 ? (hot[0].text || '') : '');
      widgetStore.putSync('hotItemId', hot.length > 0 ? String(hot[0].itemId) : '');
    } catch (e) {
      widgetStore.putSync('hotTitle', '');
    }
  }

  private refreshWidgetForms(unreadCount: number, latestMessage: string): void {
    try {
      const widgetStore = preferences.getPreferencesSync(getContext(this), { name: 'widget_data' });
      const announcementTitle = widgetStore.getSync('announcementTitle', '') as string;
      const hotTitle = widgetStore.getSync('hotTitle', '') as string;
      const announcementId = widgetStore.getSync('announcementId', '') as string;
      const hotItemId = widgetStore.getSync('hotItemId', '') as string;
      const formIdStore = preferences.getPreferencesSync(getContext(this), { name: 'widget_form_ids' });
      const allKeys = formIdStore.getAllSync();
      const keys = Object.keys(allKeys);
      if (keys.length === 0) return;
      const data: Record<string, Object> = {};
      data['unreadCount'] = unreadCount;
      data['latestMessage'] = latestMessage;
      data['announcementTitle'] = announcementTitle;
      data['hotTitle'] = hotTitle;
      data['announcementId'] = announcementId;
      data['hotItemId'] = hotItemId;
      const bindingData = formBindingData.createFormBindingData(data);
      for (const formId of keys) {
        formProvider.updateForm(formId, bindingData).catch((err: Error) => {
          console.warn('[HomePage] updateForm failed for ' + formId, err);
        });
      }
    } catch (e) {
      console.error('[HomePage] refreshWidgetForms failed:', e);
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

  private tabItems: TabItem[] = [
    { title: $r('app.string.homepage_front'), icon: $r('app.media.frontpage'), icon_s: $r('app.media.frontpage_s') },
    { title: $r('app.string.homepage_hall'),  icon: $r('app.media.dating'), icon_s: $r('app.media.dating_s') },
    { title: $r('app.string.homepage_message'), icon: $r('app.media.message'), icon_s: $r('app.media.message_s') },
    { title: $r('app.string.homepage_my'),      icon: $r('app.media.my'),      icon_s: $r('app.media.my_s') }
  ];

  private clearTabletRightPanel(): void {
    AppStorage.setOrCreate('tabletRightType', 'none');
    AppStorage.setOrCreate('tabletRightParams', '');
    AppStorage.setOrCreate('tabletPrevRightType', 'none');
    AppStorage.setOrCreate('tabletPrevRightParams', '');
  }

  switchTab(index: number): void {
    const changed = this.currentIndex !== index;
    const prevIndex = this.currentIndex;
    this.currentIndex = index;
    AppStorage.setOrCreate('currentIndex', index);

    if (changed && index === 0 && prevIndex !== 0) {
      this.frontPageAnimationTrigger++;
    }
    if (changed && index === 1 && prevIndex !== 1) {
      this.hallPageAnimationTrigger++;
    }
    if (changed && index === this.MESSAGE_TAB_INDEX && this.hasUnreadMessage) {
      this.refreshMessageListIfNeeded();
    }

    if (this.isTablet && changed) {
      this.clearTabletRightPanel();
    }

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

  onAddClick(): void {
    this.addBtnScale = 0.88;
    setTimeout(() => { this.addBtnScale = 1.0; }, 180);
    if (this.isTablet) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
      AppStorage.setOrCreate('tabletRightParams', JSON.stringify({ height: this.topHeight }));
      AppStorage.setOrCreate('tabletRightType', 'post');
      return;
    }
    router.pushUrl({ url: 'pages/PostPage', params: { height: this.topHeight } });
  }

  getBubbleLeft(): string {

    if (this.currentIndex === 0) return '2%';
    if (this.currentIndex === 1) return '22%';
    if (this.currentIndex === 2) return '61%';
    return '81%';
  }

  build() {
    Stack() {
      if (this.isTablet) {
        this.buildTabletLayout()
      } else {
        this.buildPhoneLayout()
      }
      MeteorOverlay()
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildPhoneLayout() {
    Stack({ alignContent: Alignment.Bottom }) {

      Column() {

        if (!this.isOnline) {
          this.buildOfflineBanner()
        }

        Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
          TabContent() {
            FrontPage({
              topHeight: this.getEffectiveTopHeight(),
              bottomHeight: this.bottomHeight,
              refreshTrigger: this.frontPageAnimationTrigger,
              onOpenHall: (): void => { this.switchTab(1); }
            })
          }
          TabContent() {
            HallPage({ topHeight: this.getEffectiveTopHeight(), bottomHeight: this.bottomHeight, refreshTrigger: this.mainPageRefreshTrigger, animationTrigger: this.hallPageAnimationTrigger })
          }
          TabContent() {
            MessagePage({ topHeight: this.getEffectiveTopHeight() })
          }
          TabContent() {
            PersonalPage({ topHeight: this.getEffectiveTopHeight() })
          }
        }
        .scrollable(false)
        .onChange((index: number) => { this.switchTab(index) })
        .animationDuration(0)
        .barHeight(0)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      this.buildNavCapsuleWithAdd()
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildTabletLayout() {
    Column() {
      if (!this.isOnline) {
        this.buildOfflineBanner()
      }

      Row() {
        Stack({ alignContent: Alignment.Bottom }) {
          if (this.currentIndex === 0) {
            FrontPage({
              topHeight: this.getEffectiveTopHeight(),
              bottomHeight: this.bottomHeight,
              refreshTrigger: this.frontPageAnimationTrigger,
              onOpenHall: (): void => { this.switchTab(1); }
            })
          } else if (this.currentIndex === 1) {
            HallPage({ topHeight: this.getEffectiveTopHeight(), bottomHeight: this.bottomHeight, refreshTrigger: this.mainPageRefreshTrigger, animationTrigger: this.hallPageAnimationTrigger })
          } else if (this.currentIndex === 2) {
            MessagePage({ topHeight: this.getEffectiveTopHeight() })
          } else {
            PersonalPage({ topHeight: this.getEffectiveTopHeight() })
          }

          this.buildNavCapsuleWithAdd()
        }
        .width('40%')
        .height('100%')

        Column()
          .width(0.5)
          .height('100%')
          .backgroundColor($r('app.color.divider'))

        Column() {
          if (this.rightPanelType === 'detail') {
            DetailPage({ paramsJson: this.rightPanelParams })
          } else if (this.rightPanelType === 'chat') {
            ChatPage({ paramsJson: this.rightPanelParams })
          } else if (this.rightPanelType === 'myPosts') {
            MyPostsPage()
          } else if (this.rightPanelType === 'myLiked') {
            MyLikedPage()
          } else if (this.rightPanelType === 'myReports') {
            MyReportsPage()
          } else if (this.rightPanelType === 'feedback') {
            FeedbackPage()
          } else if (this.rightPanelType === 'settings') {
            SettingsPage()
          } else if (this.rightPanelType === 'post') {
            PostPage({ paramsJson: this.rightPanelParams })
          } else if (this.rightPanelType === 'ranking') {
            RankingPage()
          } else if (this.rightPanelType === 'warning') {
            WarningPage()
          } else if (this.rightPanelType === 'announcementDetail') {
            AnnouncementDetailPage({ paramsJson: this.rightPanelParams })
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
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private getEffectiveTopHeight(): number {
    return this.isOnline ? this.topHeight : 0;
  }

  @Builder
  buildOfflineBanner() {
    Column() {

      Column().width('100%').height(this.topHeight)

      Row({ space: 8 }) {
        Text('📵')
          .fontSize(14)
        Text('网络已断开，请检查网络连接')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor('#FF6B35')
  }

  @Builder
  buildNavCapsuleWithAdd() {
    Stack({ alignContent: Alignment.Top }) {

      this.buildNavCapsule()

      Stack() {

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
    .height(86)
  }

  @Builder
  buildNavCapsule() {
    Row() {
      Stack({ alignContent: Alignment.Start }) {

        Row()
          .width('100%').height('100%')
          .borderRadius(31)
          .backdropBlur(8)
          .backgroundColor('rgba(255, 255, 255, 0.12)')

        Row()
          .margin({ left: this.getBubbleLeft() })
          .width('17%')
          .height('76%')
          .backgroundColor('rgba(255, 255, 255, 0.22)')
          .borderRadius(32)
          .shadow({ radius: 10, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
          .scale({ x: this.sliderScale, y: this.sliderScale })
          .animation({ duration: 350, curve: Curve.FastOutSlowIn })

        Row() {

          this.buildTabSlot(0)

          this.buildTabSlot(1)

          Column()
            .width('20%').height('100%')

          this.buildTabSlot(2)

          this.buildTabSlot(3)
        }
        .width('100%').height('100%')

      }
      .width('100%').height('100%')
      .borderRadius(31)
      .clip(true)
    }
    .position({ x: 0, y: 22 })
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
        if (index === this.MESSAGE_TAB_INDEX && this.hasUnreadMessage) {
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
