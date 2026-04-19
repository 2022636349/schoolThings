import { promptAction, router, window } from '@kit.ArkUI';
import { PasswordResetService } from '../services/PasswordResetService';
import { SmsCountdownButton } from '../components/SmsCountdownButton';

@Entry
@Component
export struct ResetPasswordPage {
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State errorMessage: string = '';
  @State isSubmitting: boolean = false;
  @State topHeight: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
    });
  }

  private isPhoneValid(): boolean {
    return /^1[3-9]\d{9}$/.test(this.phone);
  }

  private async handleSendCode(): Promise<boolean> {
    this.errorMessage = '';
    if (!this.isPhoneValid()) {
      this.errorMessage = '请先输入正确手机号';
      return false;
    }
    try {
      await PasswordResetService.sendCode(this.phone.trim());
      promptAction.showToast({ message: '验证码已发送' });
      return true;
    } catch (e) {
      this.errorMessage = e instanceof Error ? e.message : '验证码发送失败';
      return false;
    }
  }

  private async handleSubmit(): Promise<void> {
    this.errorMessage = '';
    if (!this.isPhoneValid()) {
      this.errorMessage = '手机号格式不正确';
      return;
    }
    if (!/^\d{6}$/.test(this.code.trim())) {
      this.errorMessage = '验证码应为 6 位数字';
      return;
    }
    if (this.password.length < 6) {
      this.errorMessage = '密码至少 6 位';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次密码不一致';
      return;
    }
    this.isSubmitting = true;
    try {
      await PasswordResetService.reset(this.phone.trim(), this.code.trim(), this.password);
      promptAction.showToast({ message: '密码重置成功，请重新登录' });
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (e) {
      this.errorMessage = e instanceof Error ? e.message : '重置失败';
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.text_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => { router.back() })

        Text('忘记密码')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      Column({ space: 14 }) {
        TextInput({ placeholder: '手机号', text: this.phone })
          .width('100%').height(48)
          .type(InputType.PhoneNumber)
          .backgroundColor($r('app.color.bg_input_area'))
          .onChange((v: string) => { this.phone = v; })

        Row({ space: 10 }) {
          TextInput({ placeholder: '验证码', text: this.code })
            .layoutWeight(1).height(48)
            .type(InputType.Number)
            .backgroundColor($r('app.color.bg_input_area'))
            .onChange((v: string) => { this.code = v; })
          SmsCountdownButton({
            canSend: this.isPhoneValid() && !this.isSubmitting,
            onSend: () => this.handleSendCode()
          })
        }

        TextInput({ placeholder: '新密码', text: this.password })
          .width('100%').height(48)
          .type(InputType.Password)
          .backgroundColor($r('app.color.bg_input_area'))
          .onChange((v: string) => { this.password = v; })

        TextInput({ placeholder: '确认新密码', text: this.confirmPassword })
          .width('100%').height(48)
          .type(InputType.Password)
          .backgroundColor($r('app.color.bg_input_area'))
          .onChange((v: string) => { this.confirmPassword = v; })

        if (this.errorMessage) {
          Text(this.errorMessage).fontSize(13).fontColor('#FF4D4F')
        }

        Button(this.isSubmitting ? '提交中...' : '重置密码')
          .width('100%').height(48)
          .fontColor('#FFFFFF')
          .backgroundColor('#4E8FDF')
          .enabled(!this.isSubmitting)
          .onClick(() => { this.handleSubmit(); })

        Text('返回登录')
          .fontSize(14)
          .fontColor('#4E8FDF')
          .onClick(() => { router.replaceUrl({ url: 'pages/LoginPage' }); })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
