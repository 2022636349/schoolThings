import { router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../services/AuthService';
import { SmsService } from '../services/SmsService';
import { SmsCountdownButton } from '../components/SmsCountdownButton';
import { MeteorOverlay } from '../components/MeteorOverlay';

@Entry
@Component
struct RegisterPage {
  @State studentId: string = '';
  @State userName: string = '';
  @State phone: string = '';
  @State smsCode: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    }).catch(() => {
      console.log('getLastWindow err')
    })
  }

  private isPhoneValid(): boolean {
    return /^1[3-9]\d{9}$/.test(this.phone);
  }

  private async handleSendCode(): Promise<boolean> {
    this.errorMessage = '';
    if (!this.isPhoneValid()) {
      this.errorMessage = '请先填写正确的 11 位手机号';
      return false;
    }

    if (!this.studentId.trim()) {
      this.errorMessage = '请先填写学号';
      return false;
    }
    try {
      const taken = await AuthService.isStudentIdTaken(this.studentId.trim());
      if (taken) {
        this.errorMessage = '该学号已被注册';
        this.getUIContext().getPromptAction().showToast({ message: '该学号已被注册' });
        return false;
      }
    } catch (e) {
      this.errorMessage = '学号查询失败，请检查网络';
      return false;
    }

    try {
      const res = await SmsService.sendCode(this.phone);
      if (!res.ok) {
        this.errorMessage = res.msg || '发送失败';
        return false;
      }
      if (res.debugCode) {
        this.getUIContext().getPromptAction().showToast({
          message: `调试模式：验证码 ${res.debugCode}`,
          duration: 4000
        });
      } else {
        this.getUIContext().getPromptAction().showToast({ message: '验证码已发送，请注意查收' });
      }
      return true;
    } catch (e) {
      this.errorMessage = '短信服务调用失败';
      return false;
    }
  }

  private async handleSubmit(): Promise<void> {
    this.errorMessage = '';
    const sid = this.studentId.trim();
    const name = this.userName.trim();
    const phone = this.phone.trim();
    const code = this.smsCode.trim();

    if (!sid || !name || !phone || !code || !this.password || !this.confirmPassword) {
      this.errorMessage = '请完整填写所有字段';
      return;
    }
    if (!this.isPhoneValid()) {
      this.errorMessage = '手机号格式不正确';
      return;
    }
    if (!/^\d{6}$/.test(code)) {
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

    this.isLoading = true;
    try {
      const taken = await AuthService.isStudentIdTaken(sid);
      if (taken) {
        this.errorMessage = '该学号已被注册';
        return;
      }

      const verifyRes = await SmsService.verifyCode(phone, code);
      if (!verifyRes.ok) {
        this.errorMessage = verifyRes.msg || '验证码校验失败';
        return;
      }

      await AuthService.register(sid, this.password, name, phone);

      this.getUIContext().getPromptAction().showToast({ message: '注册成功，已自动登录' });
      AuthService.saveSession(getContext(this) as common.UIAbilityContext, sid, this.password);
      router.replaceUrl({ url: 'pages/HomePage' });
    } catch (e) {
      this.errorMessage = (e as Error)?.message || '注册失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      Column() {
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.text_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => { router.back() })

        Text('注册账号')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Image($r('app.media.startIcon'))
              .width(72).height(72)
              .margin({ top: 20 })
            Text('加入校园失物招领')
              .fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text('让校园更温暖，让失物有归途')
              .fontSize(13).fontColor($r('app.color.text_hint'))
          }
          .width('100%').alignItems(HorizontalAlign.Center)
          .margin({ bottom: 8 })

          Column({ space: 14 }) {
            this.buildField('学号', '请输入学号', this.studentId, (v: string) => { this.studentId = v; })
            this.buildField('姓名', '请输入真实姓名', this.userName, (v: string) => { this.userName = v; })
            this.buildField('手机号', '11 位手机号', this.phone, (v: string) => { this.phone = v; }, true)

            Column({ space: 8 }) {
              Text('验证码').fontSize(13).fontColor($r('app.color.text_tertiary'))
              Row({ space: 10 }) {
                TextInput({ placeholder: '6 位验证码', text: this.smsCode })
                  .layoutWeight(1).height(46).fontSize(14)
                  .type(InputType.Number)
                  .maxLength(6)
                  .backgroundColor($r('app.color.bg_input_area'))
                  .borderRadius(10).padding({ left: 12, right: 12 })
                  .border({ width: 1, color: $r('app.color.border') })
                  .onChange((v: string) => { this.smsCode = v; })

                SmsCountdownButton({
                  canSend: this.isPhoneValid() && !!this.studentId.trim() && !this.isLoading,
                  onSend: () => this.handleSendCode()
                })
              }
            }
            .alignItems(HorizontalAlign.Start)

            this.buildField('密码', '至少 6 位', this.password, (v: string) => { this.password = v; }, false, true)
            this.buildField('确认密码', '再次输入密码', this.confirmPassword, (v: string) => { this.confirmPassword = v; }, false, true)
          }
          .width('100%')
          .padding(18)
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius(16)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(13).fontColor('#FF4D4F')
          }

          Button(this.isLoading ? '注册中...' : '注册')
            .width('100%').height(50)
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#A0BFDF' : '#4E8FDF')
            .borderRadius(25)
            .enabled(!this.isLoading)
            .onClick(() => { this.handleSubmit(); })

          Row({ space: 4 }) {
            Text('已有账号？').fontSize(13).fontColor($r('app.color.text_hint'))
            Text('立即登录')
              .fontSize(13).fontColor('#4E8FDF').fontWeight(FontWeight.Medium)
              .onClick(() => { router.back() })
          }
          .margin({ top: 6, bottom: this.bottomHeight + 30 })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 8 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      MeteorOverlay()
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildField(
    label: string,
    placeholder: string,
    value: string,
    onChange: (v: string) => void,
    isPhone: boolean = false,
    isPwd: boolean = false
  ) {
    Column({ space: 8 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_tertiary'))
      TextInput({ placeholder: placeholder, text: value })
        .width('100%').height(46).fontSize(14)
        .type(isPwd ? InputType.Password : (isPhone ? InputType.PhoneNumber : InputType.Normal))
        .backgroundColor($r('app.color.bg_input_area'))
        .borderRadius(10).padding({ left: 12, right: 12 })
        .border({ width: 1, color: $r('app.color.border') })
        .onChange(onChange)
    }
    .alignItems(HorizontalAlign.Start)
  }
}
