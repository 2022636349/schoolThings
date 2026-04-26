import { connection } from '@kit.NetworkKit';
import { promptAction } from '@kit.ArkUI';

export const KEY_ONLINE: string = 'isOnline';

export class NetworkMonitor {
  private static netConn: connection.NetConnection | null = null;
  private static started: boolean = false;
  private static lastToastTime: number = 0;
  private static readonly TOAST_INTERVAL_MS: number = 10000;

  static start(): void {
    if (NetworkMonitor.started) return;
    NetworkMonitor.started = true;

    AppStorage.setOrCreate(KEY_ONLINE, true);

    try {
      connection.hasDefaultNet().then((has: boolean) => {
        NetworkMonitor.setOnline(has);
      }).catch((e: Object) => {
        console.warn('[NetworkMonitor] hasDefaultNet failed:', JSON.stringify(e));
      });
    } catch (e) {
      console.warn('[NetworkMonitor] hasDefaultNet threw:', JSON.stringify(e));
    }

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

  static stop(): void {
    if (!NetworkMonitor.started) return;
    NetworkMonitor.started = false;
    try {
      if (NetworkMonitor.netConn) {
        NetworkMonitor.netConn.unregister(() => {});
        NetworkMonitor.netConn = null;
      }
    } catch (e) {

    }
  }

  static isOnline(): boolean {
    const v = AppStorage.get<boolean>(KEY_ONLINE);
    return v === undefined ? true : v;
  }

  static reportRequestFailure(): void {
    const wasOnline = NetworkMonitor.isOnline();
    NetworkMonitor.setOnline(false);
    if (wasOnline) {

      NetworkMonitor.showOfflineToast();
    } else {

      NetworkMonitor.showOfflineToast();
    }
  }

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

    }
  }
}
