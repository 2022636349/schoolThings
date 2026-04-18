/**
 * 申请认领 / 申请归还 对话框
 * 用户填写说明后点确认，触发 onConfirm 回调
 */
import { promptAction } from '@kit.ArkUI';

@Component
export struct ClaimRequestDialog {
  @State description: string = '';
  @State isSubmitting: boolean = false;
  title: string = '申请认领';
  onConfirm: (desc: string) => Promise<void> = async () => {};
  onCancel: () => void = () => {};

  async handleConfirm(): Promise<void> {
    if (!this.description.trim()) {
      promptAction.showToast({ message: '请填写说明' });
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
      Text(this.title)
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Column({ space: 8 }) {
        Text('说明 *').fontSize(13).fontColor($r('app.color.text_tertiary'))
        TextArea({ placeholder: '请简要说明您的信息及为什么符合条件', text: this.description })
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
          .backgroundColor(this.isSubmitting ? '#A0BFDF' : '#4E8FDF')
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
