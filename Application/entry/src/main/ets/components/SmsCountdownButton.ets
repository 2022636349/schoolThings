/**
 * 短信验证码按钮 + 60s 倒计时
 * 使用：SmsCountdownButton({ canSend: this.phoneValid, onSend: () => Promise<boolean> })
 *   - onSend 返回 true 才启动倒计时；返回 false / 抛错则不倒计时
 */
@Component
export struct SmsCountdownButton {
  /** 外部是否允许发送（如手机号已填写合法） */
  @Prop canSend: boolean = false;
  /** 倒计时总秒数 */
  countdownSeconds: number = 60;
  /** 点击发送，返回 Promise<boolean>：true 才进入倒计时 */
  onSend: () => Promise<boolean> = async () => false;

  @State remaining: number = 0;
  @State sending: boolean = false;
  private timer: number = -1;

  aboutToDisappear(): void {
    if (this.timer !== -1) clearInterval(this.timer);
  }

  private startCountdown(): void {
    this.remaining = this.countdownSeconds;
    if (this.timer !== -1) clearInterval(this.timer);
    this.timer = setInterval(() => {
      this.remaining -= 1;
      if (this.remaining <= 0) {
        this.remaining = 0;
        clearInterval(this.timer);
        this.timer = -1;
      }
    }, 1000);
  }

  private async handleClick(): Promise<void> {
    if (this.sending || this.remaining > 0 || !this.canSend) return;
    this.sending = true;
    try {
      const ok = await this.onSend();
      if (ok) this.startCountdown();
    } finally {
      this.sending = false;
    }
  }

  build() {
    Button(
      this.sending
        ? '发送中...'
        : (this.remaining > 0 ? `${this.remaining}s 后重试` : '获取验证码')
    )
      .height(46).fontSize(13).fontColor('#FFFFFF')
      .backgroundColor(this.canSend && this.remaining === 0 && !this.sending ? '#4E8FDF' : '#A0BFDF')
      .borderRadius(10)
      .padding({ left: 14, right: 14 })
      .enabled(this.canSend && this.remaining === 0 && !this.sending)
      .onClick(() => { this.handleClick(); })
  }
}
