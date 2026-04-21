import { connection } from '@kit.NetworkKit';
import { promptAction } from '@kit.ArkUI';

/**
 * 全局网络连通性监听
 *
 * - 通过系统 `connection` API 订阅 netAvailable / netLost 事件
 * - ApiClient 在请求抛出网络异常时也会主动上报（兜底）
 * - 状态写入 AppStorage['isOnline']，UI 层通过 @StorageProp 监听实时刷新
 * - 首次断网 & 每 10s 内至多一次展示 toast，避免刷屏
 */

export const KEY_ONLINE: string = 'isOnline';

export class NetworkMonitor {
  private static netConn: connection.NetConnection | null = null;
  private static started: boolean = false;
  private static lastToastTime: number = 0;
  private static readonly TOAST_INTERVAL_MS: number = 10000;

  /** 在 EntryAbility.onCreate 中调用一次 */
  static start(): void {
    if (NetworkMonitor.started) return;
    NetworkMonitor.started = true;

    // 初始状态：默认在线，避免 UI 闪红
    AppStorage.setOrCreate(KEY_ONLINE, true);

    // 初始一次主动查询（防止启动瞬间没等到事件）
    try {
      connection.hasDefaultNet().then((has: boolean) => {
        NetworkMonitor.setOnline(has);
      }).catch((e: Object) => {
        console.warn('[NetworkMonitor] hasDefaultNet failed:', JSON.stringify(e));
      });
    } catch (e) {
      console.warn('[NetworkMonitor] hasDefaultNet threw:', JSON.stringify(e));
    }

    // 订阅网络变化事件
    try {
      NetworkMonitor.netConn = connection.createNetConnection();
      NetworkMonitor.netConn.on('netAvailable', () => {
        NetworkMonitor.setOnline(true);
      });
      NetworkMonitor.netConn.on('netLost', () => {
        const wasOnline = NetworkMonitor.isOnline();
        NetworkMonitor.setOnline(false);
        if (wasOnline) {
          NetworkMonitor.showOfflineToast();
        }
      });
      NetworkMonitor.netConn.on('netUnavailable', () => {
        NetworkMonitor.setOnline(false);
      });
      NetworkMonitor.netConn.register((err: Object) => {
        if (err) {
          console.warn('[NetworkMonitor] register failed:', JSON.stringify(err));
        }
      });
    } catch (e) {
      console.warn('[NetworkMonitor] start failed:', JSON.stringify(e));
    }
  }

  /** 在 EntryAbility.onDestroy 中调用一次 */
  static stop(): void {
    if (!NetworkMonitor.started) return;
    NetworkMonitor.started = false;
    try {
      if (NetworkMonitor.netConn) {
        NetworkMonitor.netConn.unregister(() => {});
        NetworkMonitor.netConn = null;
      }
    } catch (e) {
      /* ignore */
    }
  }

  static isOnline(): boolean {
    const v = AppStorage.get<boolean>(KEY_ONLINE);
    return v === undefined ? true : v;
  }

  /** ApiClient 请求抛出网络异常时调用 */
  static reportRequestFailure(): void {
    const wasOnline = NetworkMonitor.isOnline();
    NetworkMonitor.setOnline(false);
    if (wasOnline) {
      // 与系统事件并行时用短间隔窗去重
      NetworkMonitor.showOfflineToast();
    } else {
      // 状态未变，但用户多次请求仍失败，节流后再弹一次以强化提示
      NetworkMonitor.showOfflineToast();
    }
  }

  /** ApiClient 请求成功时调用（抢修：系统事件漏报时的兜底） */
  static reportRequestSuccess(): void {
    if (!NetworkMonitor.isOnline()) {
      NetworkMonitor.setOnline(true);
    }
  }

  private static setOnline(online: boolean): void {
    const prev = AppStorage.get<boolean>(KEY_ONLINE);
    if (prev !== online) {
      AppStorage.setOrCreate(KEY_ONLINE, online);
    }
  }

  private static showOfflineToast(): void {
    const now = Date.now();
    if (now - NetworkMonitor.lastToastTime < NetworkMonitor.TOAST_INTERVAL_MS) return;
    NetworkMonitor.lastToastTime = now;
    try {
      promptAction.showToast({ message: '网络连接已断开，请检查网络', duration: 2000 });
    } catch (e) {
      /* ignore */
    }
  }
}
