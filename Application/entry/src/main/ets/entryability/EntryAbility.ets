import { ConfigurationConstant, UIAbility, Want, AbilityConstant, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { preferences } from '@kit.ArkData';
import { notificationManager } from '@kit.NotificationKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { pushService } from '@kit.PushKit';
import auth from '@hw-agconnect/auth';

const HILOG_DOMAIN = 0x0000;
const TAG = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;
  private bgPollTimer: number = -1;
  private suspendDelayId: number = -1;

  // 冷启动：从 want 中提取卡片跳转参数
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(HILOG_DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onCreate');
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

    // 先确保 AGC auth 初始化完成，再加载页面
    try {
      await auth.signInAnonymously();
      hilog.info(HILOG_DOMAIN, TAG, 'AGC anonymous auth ready');
    } catch (e) {
      hilog.warn(HILOG_DOMAIN, TAG, 'AGC anonymous auth init: %{public}s', JSON.stringify(e));
    }

    const isLoggedIn = AuthService.isLoggedIn(this.context);
    const startPage = isLoggedIn ? 'pages/HomePage' : 'pages/LoginPage';
    windowStage.loadContent(startPage, (err) => {
      if (err.code) {
        hilog.error(HILOG_DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(HILOG_DOMAIN, TAG, 'Succeeded in loading the content.');
      // 登录状态下异步获取推送 token 并保存到云数据库
      if (isLoggedIn) {
        this.registerPushToken();
      }
    });

    windowStage.getMainWindow().then((win) => {
      win.setWindowLayoutFullScreen(true);
    });
  }

  // 热启动：应用已在运行，卡片/推送点击唤起
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(HILOG_DOMAIN, TAG, 'onNewWant called');
    this.parseLaunchWant(want);
  }

  // 统一解析 want 中的跳转参数（卡片 targetPage / 推送 URI）
  private parseLaunchWant(want: Want): void {
    const isLoggedIn = AuthService.isLoggedIn(this.context);

    // 1. 卡片参数：targetPage
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

    // 2. 推送点击：URI 格式 findthings://push/message
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
    // 回到前台时：先立刻刷一次卡片和未读状态，再停止后台轮询
    this.bgPollOnce();
    this.clearBgPoll();
  }

  onBackground(): void {
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onBackground');
    // 申请短时延迟挂起，在后台继续检测消息约3分钟
    this.startBgMessageCheck();
  }

  // ── AGC 推送 token 注册 ──
  private async registerPushToken(): Promise<void> {
    try {
      const token = await pushService.getToken();
      if (token) {
        hilog.info(HILOG_DOMAIN, TAG, 'Push token obtained, saving...');
        await AuthService.savePushToken(this.context, token);
      }
    } catch (e) {
      hilog.warn(HILOG_DOMAIN, TAG, 'registerPushToken failed: %{public}s', JSON.stringify(e));
    }
  }

  // ── 后台消息检测：应用退到后台后继续轮询一段时间 ──

  private startBgMessageCheck(): void {
    try {
      const delayInfo = backgroundTaskManager.requestSuspendDelay('message_check', () => {
        // 即将被挂起，清理
        hilog.info(HILOG_DOMAIN, TAG, 'Suspend delay expired, stopping bg poll');
        this.clearBgPoll();
      });
      this.suspendDelayId = delayInfo.requestId;
      hilog.info(HILOG_DOMAIN, TAG, 'Suspend delay granted, id: %{public}d', this.suspendDelayId);
    } catch (e) {
      hilog.warn(HILOG_DOMAIN, TAG, 'requestSuspendDelay failed: %{public}s', JSON.stringify(e));
      return;
    }
    // 立即检测一次，然后每 5 秒检测一次（推送到达后卡片最晚 5 秒刷新）
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
      const authStore = preferences.getPreferencesSync(this.context, { name: 'auth' });
      const userId = authStore.getSync('account', '') as string;
      if (!userId) return;
      const msgStore = preferences.getPreferencesSync(this.context, { name: 'message_state' });
      const lastReadTime = msgStore.getSync('lastReadTime', 0) as number;
      if (lastReadTime === 0) return;

      // 拉取每会话 lastReadMsgId 和 hidden 偏好
      const sessions = await ChatService.getSessionsForUser(userId);
      const lastReadMsgIdMap: Record<string, number> = {};
      const hiddenMap: Record<string, number> = {};
      for (const s of sessions) {
        lastReadMsgIdMap[s.sessionId] = msgStore.getSync('lastReadMsgId_' + s.sessionId, 0) as number;
        hiddenMap[s.sessionId] = msgStore.getSync('hidden_' + s.sessionId, 0) as number;
      }
      const summary = await ChatService.getUnreadSummary(userId, lastReadMsgIdMap, hiddenMap);
      const hasUnread = summary.count > 0;

      // 更新桌面卡片数据（真实总数 + 最新一条内容）
      this.pushWidgetData(summary.count, summary.latest);

      // 有新消息 → 发本地通知
      if (hasUnread) {
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
