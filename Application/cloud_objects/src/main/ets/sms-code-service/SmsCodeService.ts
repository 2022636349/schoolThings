/*
 * 客户端调用占位。真正逻辑在 CloudProgram/cloudfunctions/smscodeservice/handler.js
 * 通过 importObject(SmsCodeService) 代理后，调用方法 = cloudFunction.call({ method, params })。
 */
import type { CloudObjectLikely } from '../ImportObject';

/** sendCode 返回结构 */
export interface SmsSendResult {
  ok: boolean;
  /** 云函数未接通真实短信通道时，会把明文验证码放在这里便于调试（生产请返回空） */
  debugCode?: string;
  /** 失败原因描述 */
  msg?: string;
  /** 频控剩余秒数 */
  retryAfter?: number;
}

/** verifyCode 返回结构 */
export interface SmsVerifyResult {
  ok: boolean;
  msg?: string;
}

export class SmsCodeService implements CloudObjectLikely {
  name = 'sms-code-service';

  // 发送 6 位短信验证码。phone 为 11 位手机号字符串
  async sendCode(phone: string): Promise<SmsSendResult> {
    return Promise.reject(new Error('Method not implemented.'));
  }

  // 校验验证码。成功则消耗一次 token
  async verifyCode(phone: string, code: string): Promise<SmsVerifyResult> {
    return Promise.reject(new Error('Method not implemented.'));
  }
}
