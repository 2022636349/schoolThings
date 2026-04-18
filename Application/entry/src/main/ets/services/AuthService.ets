import { cloudDatabase } from '@kit.CloudFoundationKit';
import auth from '@hw-agconnect/auth';
import { UserInfo } from '../model/User';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME = 'auth';
const KEY_ACCOUNT = 'account';
const KEY_NAME = 'name';
const KEY_PHONE = 'phone';
const KEY_AVATAR_VERSION = 'avatar_version';

// 在文件顶部加这个 interface
export interface SessionInfo {
  id: string;
  name: string;
  published: number;
  claimed: number;
  avatar: string;
}

export class AuthService {
  private static readonly ZONE_NAME = 'User';

  static async initAnonymousLogin(): Promise<void> {
    // EntryAbility 已在 onWindowStageCreate 中完成匿名登录
    // 此处做兜底检查，若 auth 尚未就绪则重试
    try {
      const currentUser = await auth.getCurrentUser();
      if (!currentUser) {
        await auth.signInAnonymously();
        console.info('AuthService', '静默匿名登录成功');
      }
    } catch (error) {
      // auth 模块可能尚未初始化，等待后重试一次
      console.warn('AuthService', '首次 auth 调用失败，500ms 后重试', error);
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
      try {
        await auth.signInAnonymously();
        console.info('AuthService', '重试匿名登录成功');
      } catch (retryErr) {
        console.error('AuthService', '授权失败，请确保 AGC 后台已开启匿名帐号', retryErr);
      }
    }
  }

  static async login(account: string, pwd: string): Promise<boolean> {
    try {
      const db = cloudDatabase.zone(AuthService.ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', account);
      const result = (await db.query(query)) as UserInfo[];

      if (result.length > 0) {
        const user = result[0];
        return user.Password === pwd;
      }
      return false;
    } catch (error) {
      console.error('AuthService', '查询数据库失败', error);
      throw new Error('登录报错代码: ' + JSON.stringify(error));
    }
  }

  static async register(account: string, pwd: string, name: string, phone: string): Promise<boolean> {
    try {
      const db = cloudDatabase.zone(AuthService.ZONE_NAME);
      let newUser = new UserInfo();
      newUser.ID = account;
      newUser.Password = pwd;
      newUser.Name = name;
      newUser.Phone = phone;
      // heartValue / fraudCount 由 UserInfo 构造函数默认 0
      await db.upsert(newUser);
      return true;
    } catch (error) {
      console.error('AuthService', '写入数据库失败', error);
      throw new Error('注册报错代码: ' + JSON.stringify(error));
    }
  }

  /**
   * 学号是否已被注册（用于前端实时校验 + 提交前二次确认）
   */
  static async isStudentIdTaken(studentId: string): Promise<boolean> {
    try {
      const db = cloudDatabase.zone(AuthService.ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', studentId);
      const result = (await db.query(query)) as UserInfo[];
      return result.length > 0;
    } catch (error) {
      console.error('AuthService', '学号查重失败', error);
      // 查询失败时保守返回 true 阻止注册，让用户重试
      throw new Error('学号查重失败: ' + JSON.stringify(error));
    }
  }

  // ✅ 登录成功后调用，持久化用户信息
  static saveSession(context: common.UIAbilityContext, id: string, password: string): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_ACCOUNT, id);
    store.putSync(KEY_NAME, password);
    store.flush();
  }

  // ✅ 退出登录时调用，清除持久化信息
  static clearSession(context: common.UIAbilityContext): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.clearSync();
    store.flush();
  }

  // ✅ 检查是否已登录，App 启动时用
  static isLoggedIn(context: common.UIAbilityContext): boolean {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return (store.getSync(KEY_ACCOUNT, '') as string) !== '';
  }

  // ✅ 修改密码：验证旧密码后写入新密码，返回是否成功
  static async changePassword(context: common.UIAbilityContext, oldPwd: string, newPwd: string): Promise<boolean> {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    const account = store.getSync(KEY_ACCOUNT, '') as string;
    if (!account) return false;
    try {
      const db = cloudDatabase.zone(AuthService.ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', account);
      const result = (await db.query(query)) as UserInfo[];
      if (!result || result.length === 0) return false;
      const user = result[0];
      if (user.Password !== oldPwd) return false;
      user.Password = newPwd;
      await db.upsert(user);
      return true;
    } catch (error) {
      console.error('AuthService', '修改密码失败', error);
      return false;
    }
  }

  // ✅ 保存 / 读取头像版本号（本地 Preferences，重启后依然有效）
  static saveAvatarVersion(context: common.UIAbilityContext, version: string): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_AVATAR_VERSION, version);
    store.flush();
  }

  static getAvatarVersion(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_AVATAR_VERSION, '') as string;
  }

  // ✅ 保存/更新设备推送 token 到云数据库
  static async savePushToken(context: common.UIAbilityContext, token: string): Promise<void> {
    try {
      const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      const account = store.getSync(KEY_ACCOUNT, '') as string;
      if (!account) return;
      const db = cloudDatabase.zone(AuthService.ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', account);
      const result = (await db.query(query)) as UserInfo[];
      if (result.length > 0) {
        const user = result[0];
        if (user.pushToken === token) return; // 无变化不更新
        user.pushToken = token;
        await db.upsert(user);
        console.info('[AuthService] Push token saved');
      }
    } catch (e) {
      console.warn('[AuthService] savePushToken failed:', e);
    }
  }

  // ✅ 获取当前登录用户信息
  static async getSession(context: common.UIAbilityContext): Promise<SessionInfo | null> {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    const account = store.getSync(KEY_ACCOUNT, '') as string;
    const db = cloudDatabase.zone(AuthService.ZONE_NAME);
    const query = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', account);
    try {
      const result = (await db.query(query)) as UserInfo[];
      if (result.length > 0) {
        const user = result[0];
        const session: SessionInfo = {
          id: user.ID,
          name: user.Name,
          published: user.Published,
          claimed: user.Claimed,
          avatar: user.Avatar ?? ''
        };
        return session;
      }
      else {
        return null;
      }
    } catch (error) {
      return null;
    }

  }
}