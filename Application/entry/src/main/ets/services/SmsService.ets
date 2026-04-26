import { ApiClient, ApiError } from '../common/ApiClient';

export interface SmsSendResult {
  ok: boolean;
  msg?: string;
  retryAfter?: number;
  debugCode?: string;   
}

export interface SmsVerifyResult {
  ok: boolean;
  msg?: string;
}

interface SmsSendBody {
  phone: string;
  scene: string;
}

interface SmsVerifyBody {
  phone: string;
  scene: string;
  code: string;
}

export class SmsService {

  static async sendCode(phone: string, scene: string = 'register'): Promise<SmsSendResult> {
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      const r: SmsSendResult = { ok: false, msg: '手机号格式不正确' };
      return r;
    }
    try {
      const body: SmsSendBody = { phone: phone, scene: scene };
      await ApiClient.post<Object>('/auth/sms/send', body);
      const r: SmsSendResult = { ok: true };
      return r;
    } catch (e) {
      const msg = (e instanceof ApiError || e instanceof Error) ? e.message : '发送失败';
      console.error('[SmsService] sendCode failed:', msg);
      const r: SmsSendResult = { ok: false, msg: msg };
      return r;
    }
  }

  static async verifyCode(phone: string, code: string, scene: string = 'register'): Promise<SmsVerifyResult> {
    try {
      const body: SmsVerifyBody = { phone: phone, scene: scene, code: code };
      const ok = await ApiClient.post<boolean>('/auth/sms/verify', body);
      if (ok) {
        const r: SmsVerifyResult = { ok: true };
        return r;
      }
      const r: SmsVerifyResult = { ok: false, msg: '验证码不正确或已过期' };
      return r;
    } catch (e) {
      const msg = (e instanceof ApiError || e instanceof Error) ? e.message : '校验失败';
      console.error('[SmsService] verifyCode failed:', msg);
      const r: SmsVerifyResult = { ok: false, msg: msg };
      return r;
    }
  }
}
