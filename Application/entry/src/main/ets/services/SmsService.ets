import { importObject, SmsCodeService, SmsSendResult, SmsVerifyResult } from 'cloud_objects';

/**
 * 客户端短信验证码封装
 * - 优先调用云函数 SmsCodeService（sendCode / verifyCode）
 * - 云函数不可达时回退「本地调试模式」：内存存 6 位随机码 + toast 回显
 *   Phase 2 调试期即可完整跑通注册流程；云函数部署后自动走云端
 */

interface LocalCodeEntry {
  code: string;
  sendAt: number;
  expireAt: number;
  attempts: number;
}

const LOCAL_TTL_MS: number = 10 * 60 * 1000;
const LOCAL_SEND_INTERVAL_MS: number = 60 * 1000;
const LOCAL_MAX_ATTEMPTS: number = 5;

export class SmsService {
  // 使用 Map 代替 Record，ArkTS 支持 Map.delete() 但不支持 delete 运算符
  private static localStore: Map<string, LocalCodeEntry> = new Map();
  private static cloudOk: boolean = true;

  /**
   * 发送验证码
   * @returns ok=true 表示成功；debugCode 非空说明处于调试模式，上层 toast 显示
   */
  static async sendCode(phone: string): Promise<SmsSendResult> {
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      const r: SmsSendResult = { ok: false, msg: '手机号格式不正确' };
      return r;
    }

    if (SmsService.cloudOk) {
      try {
        const svc = importObject(SmsCodeService);
        const res = await svc.sendCode(phone) as SmsSendResult;
        if (res && typeof res.ok === 'boolean') return res;
        throw new Error('cloud response invalid');
      } catch (e) {
        console.warn('[SmsService] 云函数不可达，进入本地调试模式:', e);
        SmsService.cloudOk = false;
      }
    }

    return SmsService.localSend(phone);
  }

  /** 校验验证码 */
  static async verifyCode(phone: string, code: string): Promise<SmsVerifyResult> {
    if (SmsService.cloudOk) {
      try {
        const svc = importObject(SmsCodeService);
        const res = await svc.verifyCode(phone, code) as SmsVerifyResult;
        if (res && typeof res.ok === 'boolean') return res;
        throw new Error('cloud response invalid');
      } catch (e) {
        console.warn('[SmsService] verifyCode 走本地兜底:', e);
        SmsService.cloudOk = false;
      }
    }
    return SmsService.localVerify(phone, code);
  }

  // ──────────── 本地兜底 ────────────
  private static localSend(phone: string): SmsSendResult {
    SmsService.gcLocal();
    const entry = SmsService.localStore.get(phone);
    const nowMs = Date.now();
    if (entry && nowMs - entry.sendAt < LOCAL_SEND_INTERVAL_MS) {
      const remain = Math.ceil((LOCAL_SEND_INTERVAL_MS - (nowMs - entry.sendAt)) / 1000);
      const r: SmsSendResult = { ok: false, msg: '发送过于频繁', retryAfter: remain };
      return r;
    }
    const code = SmsService.gen6();
    const newEntry: LocalCodeEntry = {
      code,
      sendAt: nowMs,
      expireAt: nowMs + LOCAL_TTL_MS,
      attempts: 0
    };
    SmsService.localStore.set(phone, newEntry);
    const r: SmsSendResult = { ok: true, debugCode: code };
    return r;
  }

  private static localVerify(phone: string, code: string): SmsVerifyResult {
    SmsService.gcLocal();
    const entry = SmsService.localStore.get(phone);
    if (!entry) {
      const r: SmsVerifyResult = { ok: false, msg: '验证码已过期或未发送' };
      return r;
    }
    entry.attempts += 1;
    if (entry.attempts > LOCAL_MAX_ATTEMPTS) {
      SmsService.localStore.delete(phone);
      const r: SmsVerifyResult = { ok: false, msg: '错误次数过多，请重新获取' };
      return r;
    }
    if (entry.code !== String(code).trim()) {
      const r: SmsVerifyResult = { ok: false, msg: '验证码不正确' };
      return r;
    }
    SmsService.localStore.delete(phone);
    const r: SmsVerifyResult = { ok: true };
    return r;
  }

  private static gcLocal(): void {
    const nowMs = Date.now();
    // 遍历 Map 清过期条目，ArkTS 不支持 for...of Map.entries()，用 forEach
    SmsService.localStore.forEach((_entry: LocalCodeEntry, key: string) => {
      const e = SmsService.localStore.get(key);
      if (e && e.expireAt < nowMs) {
        SmsService.localStore.delete(key);
      }
    });
  }

  private static gen6(): string {
    return '' + (Math.floor(Math.random() * 900000) + 100000);
  }
}
