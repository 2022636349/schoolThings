@Component
export struct TopNavBar {
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  onBackClick?: () => void;
  onActionClick?: () => void;
  @Prop actionText: string = '';

  build() {
    Row() {
      if (this.showBack) {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .margin({ left: 16, right: 16 })
          .onClick(() => {
            if (this.onBackClick) {
              this.onBackClick();
            }
          })
      }

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
        .margin({ left: this.showBack ? '30%' : 16 })

      if (this.actionText) {
        Text(this.actionText)
          .fontSize(16)
          .fontColor('#007DFF')
          .margin({ right: 16 })
          .onClick(() => {
            if (this.onActionClick) {
              this.onActionClick();
            }
          })
      }
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.bg_page'))
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
