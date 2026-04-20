import { common } from '@kit.AbilityKit';
import { ApiClient, ApiError } from '../common/ApiClient';
import { Session } from '../common/Session';

/**
 * 登录/注册/账号相关封装（Phase 4：统一走后端 REST）
 */

export interface SessionInfo {
  id: string;          // userId 的字符串形式（后端 Long → 字符串）
  studentNo: string;   // 学号
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
  /** 兼容旧代码：匿名登录已不再需要，保留空实现 */
  static async initAnonymousLogin(): Promise<void> {
    return;
  }

  /** 登录（学号 + 密码），成功后把 token + 基本信息落盘 */
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

  /** 注册（学号 + 密码 + 昵称 + 手机号），成功后自动登录 */
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

  /** 学号是否已被注册（注册页实时校验用） */
  static async isStudentIdTaken(studentNo: string): Promise<boolean> {
    try {
      const taken = await ApiClient.get<boolean>('/auth/student/taken', { studentNo: studentNo } as StudentTakenQuery);
      return !!taken;
    } catch (e) {
      console.error('[AuthService] isStudentIdTaken failed:', e);
      throw new Error('学号查重失败');
    }
  }

  /** 兼容旧代码：登录成功后由 login() 内部已保存，这里仅兜底做一次同名写入 */
  static saveSession(context: common.UIAbilityContext, id: string, _password: string): void {
    // 老调用方式 (id, password) 存不了完整信息，这里只补学号字段
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

  /** 退出登录 */
  static clearSession(context: common.UIAbilityContext): void {
    Session.clear(context);
  }

  /** 是否已登录（本地 token 存在即可） */
  static isLoggedIn(context: common.UIAbilityContext): boolean {
    return Session.isLoggedIn(context);
  }

  /** 修改密码：校验旧密码后改为新密码 */
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

  /** 保存/更新推送 token 到后端 */
  static async savePushToken(context: common.UIAbilityContext, token: string): Promise<void> {
    try {
      if (!Session.isLoggedIn(context)) return;
      const body: PushTokenBody = { token: token };
      await ApiClient.post<Object>('/user/push-token', body, context);
    } catch (e) {
      console.warn('[AuthService] savePushToken failed:', e);
    }
  }

  /** 从后端获取当前登录用户信息（每次都刷） */
  static async getSession(context: common.UIAbilityContext): Promise<SessionInfo | null> {
    try {
      if (!Session.isLoggedIn(context)) return null;
      const resp = await ApiClient.get<MeResp>('/user/me', undefined, context);
      if (!resp) return null;
      // 同步更新本地缓存的 name / avatar，方便离线时显示
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
