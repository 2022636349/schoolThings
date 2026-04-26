import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME = 'auth';

const KEY_USER_ID = 'userId';
const KEY_STUDENT_NO = 'studentNo';
const KEY_NAME = 'name';
const KEY_AVATAR = 'avatar';
const KEY_ACCESS = 'access_token';
const KEY_REFRESH = 'refresh_token';
const KEY_AVATAR_VERSION = 'avatar_version';

export class Session {

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

  static clear(context: common.UIAbilityContext): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.clearSync();
    store.flush();
  }

  static isLoggedIn(context: common.UIAbilityContext): boolean {
    const s = Session.read(context);
    return s.userId.length > 0 && s.accessToken.length > 0;
  }

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

  static getUserId(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_USER_ID, '') as string;
  }

  static getAccessToken(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_ACCESS, '') as string;
  }

  static getRefreshToken(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_REFRESH, '') as string;
  }

  static saveAvatarVersion(context: common.UIAbilityContext, version: string): void {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    store.putSync(KEY_AVATAR_VERSION, version);
    store.flush();
  }

  static getAvatarVersion(context: common.UIAbilityContext): string {
    const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return store.getSync(KEY_AVATAR_VERSION, '') as string;
  }

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
