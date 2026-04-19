import { promptAction, router, window } from '@kit.ArkUI';
import { FeedbackService } from '../services/FeedbackService';

@Entry
@Component
export struct FeedbackPage {
  @State topHeight: number = 0;
  @State content: string = '';
  @State isSubmitting: boolean = false;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
    });
  }

  private async handleSubmit(): Promise<void> {
    if (!this.content.trim()) {
      promptAction.showToast({ message: '请输入反馈内容' });
      return;
    }
    this.isSubmitting = true;
    try {
      await FeedbackService.submit(this.content.trim());
      promptAction.showToast({ message: '反馈已提交，感谢你的建议' });
      router.back();
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

        Text('意见反馈')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      Column({ space: 10 }) {
        Text('欢迎告诉我们你在使用中遇到的问题或建议')
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
          .width('100%')

        TextArea({ placeholder: '请输入你的反馈内容', text: this.content })
          .width('100%')
          .height(180)
          .fontSize(14)
          .backgroundColor($r('app.color.bg_input_area'))
          .borderRadius(12)
          .onChange((v: string) => { this.content = v; })

        Button(this.isSubmitting ? '提交中...' : '提交反馈')
          .width('100%').height(48)
          .fontColor('#FFFFFF')
          .backgroundColor('#4E8FDF')
          .enabled(!this.isSubmitting)
          .onClick(() => { this.handleSubmit(); })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
