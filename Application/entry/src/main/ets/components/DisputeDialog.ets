@Component
export struct DisputeDialog {
  @State description: string = '';
  @State isSubmitting: boolean = false;
  onConfirm: (desc: string) => Promise<void> = async () => {};
  onCancel: () => void = () => {};

  async handleConfirm(): Promise<void> {
    if (!this.description.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写异议内容' });
      return;
    }
    this.isSubmitting = true;
    try {
      await this.onConfirm(this.description.trim());
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('提交异议')
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text('如您认为该物品认领有误，请填写理由说明')
        .fontSize(13).fontColor($r('app.color.text_hint'))
        .width('100%')

      Column({ space: 8 }) {
        Text('异议说明 *').fontSize(13).fontColor($r('app.color.text_tertiary'))
        TextArea({ placeholder: '请详细说明异议原因', text: this.description })
          .width('100%').height(120).fontSize(14)
          .onChange((v: string) => { this.description = v })
      }
      .alignItems(HorizontalAlign.Start)

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1).height(44)
          .fontSize(14).fontColor('#4E8FDF')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .enabled(!this.isSubmitting)
          .onClick(() => { this.onCancel() })

        Button(this.isSubmitting ? '提交中...' : '确认')
          .layoutWeight(1).height(44)
          .fontSize(14).fontColor('#FFFFFF')
          .backgroundColor(this.isSubmitting ? '#A0BFDF' : '#FF9500')
          .borderRadius(8)
          .enabled(!this.isSubmitting)
          .onClick(() => { this.handleConfirm() })
      }
    }
    .width('100%').padding(20)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
  }
}
