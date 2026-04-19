import { ConfigurationConstant, UIAbility, Want, AbilityConstant, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { ApiClient } from '../common/ApiClient';
import { preferences } from '@kit.ArkData';
import { notificationManager } from '@kit.NotificationKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { formProvider, formBindingData } from '@kit.FormKit';

const HILOG_DOMAIN = 0x0000;
const TAG = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;
  private bgPollTimer: number = -1;
  private suspendDelayId: number = -1;

  // 冷启动
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(HILOG_DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onCreate');
    // 注入全局 context 到 ApiClient，所有 service 都能用
    ApiClient.setContext(this.context);
    // 冷启动：提取跳转参数（卡片或推送点击）
    this.parseLaunchWant(want);
  }

  onDestroy(): void {
    this.clearBgPoll();
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    this.windowStage = windowStage;
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');
    // 确保 context 已注入
    ApiClient.setContext(this.context);

    const isLoggedIn = AuthService.isLoggedIn(this.context);
    const startPage = isLoggedIn ? 'pages/HomePage' : 'pages/LoginPage';
    windowStage.loadContent(startPage, (err) => {
      if (err.code) {
        hilog.error(HILOG_DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(HILOG_DOMAIN, TAG, 'Succeeded in loading the content.');
    });

    windowStage.getMainWindow().then((win) => {
      win.setWindowLayoutFullScreen(true);
    });
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(HILOG_DOMAIN, TAG, 'onNewWant called');
    this.parseLaunchWant(want);
  }

  private parseLaunchWant(want: Want): void {
    const isLoggedIn = AuthService.isLoggedIn(this.context);

    if (want.parameters) {
      const targetPage = want.parameters['targetPage'] as string;
      if (targetPage) {
        if (isLoggedIn) {
          AppStorage.setOrCreate('widgetAction', targetPage);
        }
        hilog.info(HILOG_DOMAIN, TAG, 'Launch param targetPage: %{public}s', targetPage);
        return;
      }
    }

    if (want.uri && want.uri.indexOf('findthings://push/message') >= 0) {
      if (isLoggedIn) {
        AppStorage.setOrCreate('widgetAction', 'message');
      }
      hilog.info(HILOG_DOMAIN, TAG, 'Push click → message page');
      return;
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onForeground');
    this.bgPollOnce();
    this.clearBgPoll();
  }

  onBackground(): void {
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onBackground');
    this.startBgMessageCheck();
  }

  // ── 后台消息检测：应用退到后台后继续轮询一段时间 ──

  private startBgMessageCheck(): void {
    try {
      const delayInfo = backgroundTaskManager.requestSuspendDelay('message_check', () => {
        hilog.info(HILOG_DOMAIN, TAG, 'Suspend delay expired, stopping bg poll');
        this.clearBgPoll();
      });
      this.suspendDelayId = delayInfo.requestId;
      hilog.info(HILOG_DOMAIN, TAG, 'Suspend delay granted, id: %{public}d', this.suspendDelayId);
    } catch (e) {
      hilog.warn(HILOG_DOMAIN, TAG, 'requestSuspendDelay failed: %{public}s', JSON.stringify(e));
      return;
    }
    this.bgPollOnce();
    this.bgPollTimer = setInterval(() => { this.bgPollOnce(); }, 5000);
  }

  private clearBgPoll(): void {
    if (this.bgPollTimer !== -1) {
      clearInterval(this.bgPollTimer);
      this.bgPollTimer = -1;
    }
    if (this.suspendDelayId !== -1) {
      try {
        backgroundTaskManager.cancelSuspendDelay(this.suspendDelayId);
      } catch (e) { /* ignore */ }
      this.suspendDelayId = -1;
    }
  }

  private async bgPollOnce(): Promise<void> {
    try {
      if (!AuthService.isLoggedIn(this.context)) return;
      const authStore = preferences.getPreferencesSync(this.context, { name: 'auth' });
      const userId = authStore.getSync('userId', '') as string;
      if (!userId) return;

      // 从本地偏好拉取 lastReadMsgId 和 hidden
      const msgStore = preferences.getPreferencesSync(this.context, { name: 'message_state' });

      const sessions = await ChatService.getSessionsForUser(userId);
      const lastReadMsgIdMap: Record<string, number> = {};
      const hiddenMap: Record<string, number> = {};
      for (const s of sessions) {
        lastReadMsgIdMap[s.sessionId] = msgStore.getSync('lastReadMsgId_' + s.sessionId, 0) as number;
        hiddenMap[s.sessionId] = msgStore.getSync('hidden_' + s.sessionId, 0) as number;
      }
      const summary = await ChatService.getUnreadSummary(userId, lastReadMsgIdMap, hiddenMap);
      const hasUnread = summary.count > 0;
      const cacheStore = preferences.getPreferencesSync(this.context, { name: 'message_state' });
      const lastBgLatest = cacheStore.getSync('last_bg_latest', '') as string;

      this.pushWidgetData(summary.count, summary.latest);

      if (hasUnread && summary.latest && summary.latest !== lastBgLatest) {
        cacheStore.putSync('last_bg_latest', summary.latest);
        cacheStore.flush();
        const request: notificationManager.NotificationRequest = {
          id: 1002,
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: { title: '校园失物招领 - 新消息', text: summary.latest }
          }
        };
        await notificationManager.publish(request);
        hilog.info(HILOG_DOMAIN, TAG, 'Bg notification published');
      }
    } catch (e) {
      hilog.warn(HILOG_DOMAIN, TAG, 'bgPollOnce error: %{public}s', JSON.stringify(e));
    }
  }

  private pushWidgetData(unreadCount: number, latestMessage: string): void {
    try {
      const widgetStore = preferences.getPreferencesSync(this.context, { name: 'widget_data' });
      widgetStore.putSync('unreadCount', unreadCount);
      widgetStore.putSync('latestMessage', latestMessage);
      widgetStore.flush();
      const formIdStore = preferences.getPreferencesSync(this.context, { name: 'widget_form_ids' });
      const allKeys = formIdStore.getAllSync();
      const keys = Object.keys(allKeys);
      if (keys.length === 0) return;
      const data: Record<string, Object> = {};
      data['unreadCount'] = unreadCount;
      data['latestMessage'] = latestMessage;
      const bindingData = formBindingData.createFormBindingData(data);
      for (const formId of keys) {
        formProvider.updateForm(formId, bindingData).catch((err: Error) => {
          hilog.warn(HILOG_DOMAIN, TAG, 'pushWidgetData updateForm failed: %{public}s', JSON.stringify(err));
        });
      }
    } catch (e) { /* ignore */ }
  }
}
