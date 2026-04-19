import { ApiClient } from '../common/ApiClient';
import { SmsService } from './SmsService';

interface ResetPasswordBody {
  phone: string;
  code: string;
  newPassword: string;
}

export class PasswordResetService {
  static async sendCode(phone: string): Promise<void> {
    const res = await SmsService.sendCode(phone, 'reset_password');
    if (!res.ok) {
      throw new Error(res.msg || '验证码发送失败');
    }
  }

  static async reset(phone: string, code: string, newPassword: string): Promise<void> {
    const body: ResetPasswordBody = {
      phone: phone,
      code: code,
      newPassword: newPassword
    };
    await ApiClient.post<Object>('/auth/password/reset', body);
  }
}
