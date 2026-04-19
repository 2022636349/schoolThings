import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * 本地会话存储：封装 Preferences 读写，避免各处重复初始化
 * 存放字段：
 *   - userId     当前用户 id（Long 的字符串形式，与后端返回一致）
 *   - studentNo  学号（展示 / 登录用）
 *   - name       昵称
 *   - avatar     头像 URL
 *   - accessToken  访问令牌
 *   - refreshToken 刷新令牌
 */

const STORE_NAME = 'auth';

const KEY_USER_ID = 'userId';
const KEY_STUDENT_NO = 'studentNo';
const KEY_NAME = 'name';
const KEY_AVATAR = 'avatar';
const KEY_ACCESS = 'access_token';
const KEY_REFRESH = 'refresh_token';
const KEY_AVATAR_VERSION = 'avatar_version';

export class Session {
  /** 登录成功后保存 token + 基本信息 */
  static save(context: common.UIAbilityContext, info: SessionSaveData): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_USER_ID, info.userId || '');
    store.putSync(KEY_STUDENT_NO, info.studentNo || '');
    store.putSync(KEY_NAME, info.name || '');
    store.putSync(KEY_AVATAR, info.avatar || '');
    store.putSync(KEY_ACCESS, info.accessToken || '');
    store.putSync(KEY_REFRESH, info.refreshToken || '');
    store.flush();
  }

  /** 仅更新 access token（刷新流程用） */
  static updateAccessToken(context: common.UIAbilityContext, token: string): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_ACCESS, token);
    store.flush();
  }

  static updateTokens(context: common.UIAbilityContext, accessToken: string, refreshToken: string): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_ACCESS, accessToken);
    store.putSync(KEY_REFRESH, refreshToken);
    store.flush();
  }

  /** 退出登录 */
  static clear(context: common.UIAbilityContext): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.clearSync();
    store.flush();
  }

  /** 是否已登录（有 userId + accessToken） */
  static isLoggedIn(context: common.UIAbilityContext): boolean {
    const s = Session.read(context);
    return s.userId.length > 0 && s.accessToken.length > 0;
  }

  /** 读所有字段 */
  static read(context: common.UIAbilityContext): SessionData {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    const data: SessionData = {
      userId: store.getSync(KEY_USER_ID, '') as string,
      studentNo: store.getSync(KEY_STUDENT_NO, '') as string,
      name: store.getSync(KEY_NAME, '') as string,
      avatar: store.getSync(KEY_AVATAR, '') as string,
      accessToken: store.getSync(KEY_ACCESS, '') as string,
      refreshToken: store.getSync(KEY_REFRESH, '') as string
    };
    return data;
  }

  /** 只读 userId（用于各 service 判断当前用户） */
  static getUserId(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_USER_ID, '') as string;
  }

  /** 只读 accessToken（HTTP 拦截器用） */
  static getAccessToken(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_ACCESS, '') as string;
  }

  static getRefreshToken(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_REFRESH, '') as string;
  }

  /** 保存头像版本号（本地缓存绕过用） */
  static saveAvatarVersion(context: common.UIAbilityContext, version: string): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_AVATAR_VERSION, version);
    store.flush();
  }

  static getAvatarVersion(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_AVATAR_VERSION, '') as string;
  }

  /** 更新本地缓存的昵称 / 头像（个人页编辑后同步） */
  static updateProfile(context: common.UIAbilityContext, name: string | null, avatar: string | null): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    if (name !== null) store.putSync(KEY_NAME, name);
    if (avatar !== null) store.putSync(KEY_AVATAR, avatar);
    store.flush();
  }
}

export interface SessionSaveData {
  userId: string;
  studentNo: string;
  name: string;
  avatar: string;
  accessToken: string;
  refreshToken: string;
}

export interface SessionData {
  userId: string;
  studentNo: string;
  name: string;
  avatar: string;
  accessToken: string;
  refreshToken: string;
}
