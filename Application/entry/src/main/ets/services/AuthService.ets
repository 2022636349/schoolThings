import { common } from '@kit.AbilityKit';
import { ApiClient, ApiError } from '../common/ApiClient';
import { Session } from '../common/Session';

export interface SessionInfo {
  id: string;          
  studentNo: string;   
  name: string;
  avatar: string;
  published: number;
  claimed: number;
  heartValue: number;
  fraudCount: number;
  phoneMasked: string;
}

interface LoginResp {
  accessToken: string;
  refreshToken: string;
  userId: number | string;
  nickname: string | null;
  avatar: string | null;
  expiresIn: number;
  tokenType: string;
}

function getErrorMessage(error: Object): string {
  if (error instanceof ApiError) {
    return error.message;
  }
  return '登录失败，请稍后重试';
}

interface MeResp {
  id: string;
  studentNo: string;
  name: string | null;
  avatar: string | null;
  published: number;
  claimed: number;
  heartValue: number;
  fraudCount: number;
  phoneMasked: string | null;
}

interface StudentLoginBody {
  studentNo: string;
  password: string;
}

interface StudentRegisterBody {
  studentNo: string;
  password: string;
  nickname: string;
  phone: string;
}

interface StudentTakenQuery extends Record<string, string | number | boolean | null | undefined> {
  studentNo: string;
}

interface ChangePasswordBody {
  oldPassword: string;
  newPassword: string;
}

interface PushTokenBody {
  token: string;
}

function appendAvatarVersion(avatar: string, version: string): string {
  if (!avatar || !version || avatar.startsWith('data:') || avatar.startsWith('file:')) return avatar;
  const separator = avatar.indexOf('?') >= 0 ? '&' : '?';
  return `${avatar}${separator}v=${encodeURIComponent(version)}`;
}

export class AuthService {

  static async login(studentNo: string, password: string): Promise<boolean> {
    const ctx = ApiClient.getContext();
    const body: StudentLoginBody = { studentNo: studentNo, password: password };
    try {
      const resp = await ApiClient.post<LoginResp>('/auth/login/student', body);
      if (!resp || !resp.accessToken) {
        throw new Error('登录失败，请稍后重试');
      }
      if (ctx) {
        Session.save(ctx, {
          userId: String(resp.userId),
          studentNo: studentNo,
          name: resp.nickname || studentNo,
          avatar: resp.avatar || '',
          accessToken: resp.accessToken,
          refreshToken: resp.refreshToken || ''
        });
      }
      return true;
    } catch (error) {
      throw new Error(getErrorMessage(error));
    }
  }

  static async register(studentNo: string, password: string, name: string, phone: string): Promise<boolean> {
    const ctx = ApiClient.getContext();
    const body: StudentRegisterBody = {
      studentNo: studentNo,
      password: password,
      nickname: name,
      phone: phone
    };
    const resp = await ApiClient.post<LoginResp>('/auth/register/student', body);
    if (!resp || !resp.accessToken) {
      throw new Error('注册失败');
    }
    if (ctx) {
      Session.save(ctx, {
        userId: String(resp.userId),
        studentNo: studentNo,
        name: resp.nickname || name,
        avatar: resp.avatar || '',
        accessToken: resp.accessToken,
        refreshToken: resp.refreshToken || ''
      });
    }
    return true;
  }

  static async isStudentIdTaken(studentNo: string): Promise<boolean> {
    try {
      const taken = await ApiClient.get<boolean>('/auth/student/taken', { studentNo: studentNo } as StudentTakenQuery);
      return !!taken;
    } catch (e) {
      console.error('[AuthService] isStudentIdTaken failed:', e);
      throw new Error('学号查重失败');
    }
  }

  static saveSession(context: common.UIAbilityContext, id: string, _password: string): void {

    const data = Session.read(context);
    Session.save(context, {
      userId: data.userId || id,
      studentNo: data.studentNo || id,
      name: data.name,
      avatar: data.avatar,
      accessToken: data.accessToken,
      refreshToken: data.refreshToken
    });
  }

  static clearSession(context: common.UIAbilityContext): void {
    Session.clear(context);
  }

  static isLoggedIn(context: common.UIAbilityContext): boolean {
    return Session.isLoggedIn(context);
  }

  static async changePassword(
    context: common.UIAbilityContext,
    oldPwd: string,
    newPwd: string
  ): Promise<boolean> {
    try {
      const body: ChangePasswordBody = { oldPassword: oldPwd, newPassword: newPwd };
      const ok = await ApiClient.post<boolean>('/user/change-password', body, context);
      return !!ok;
    } catch (e) {
      console.error('[AuthService] changePassword failed:', e);
      return false;
    }
  }

  static saveAvatarVersion(context: common.UIAbilityContext, version: string): void {
    Session.saveAvatarVersion(context, version);
  }

  static getAvatarVersion(context: common.UIAbilityContext): string {
    return Session.getAvatarVersion(context);
  }

  static async savePushToken(context: common.UIAbilityContext, token: string): Promise<void> {
    try {
      if (!Session.isLoggedIn(context)) return;
      const body: PushTokenBody = { token: token };
      await ApiClient.post<Object>('/user/push-token', body, context);
    } catch (e) {
      console.warn('[AuthService] savePushToken failed:', e);
    }
  }

  static async getSession(context: common.UIAbilityContext): Promise<SessionInfo | null> {
    try {
      if (!Session.isLoggedIn(context)) return null;
      const resp = await ApiClient.get<MeResp>('/user/me', undefined, context);
      if (!resp) return null;

      Session.updateProfile(context, resp.name, resp.avatar || '');
      const avatarVersion = Session.getAvatarVersion(context);
      const info: SessionInfo = {
        id: String(resp.id),
        studentNo: resp.studentNo || '',
        name: resp.name || '',
        avatar: appendAvatarVersion(resp.avatar || '', avatarVersion),
        published: resp.published || 0,
        claimed: resp.claimed || 0,
        heartValue: resp.heartValue || 0,
        fraudCount: resp.fraudCount || 0,
        phoneMasked: resp.phoneMasked || ''
      };
      return info;
    } catch (e) {
      console.error('[AuthService] getSession failed:', e);
      return null;
    }
  }
}
