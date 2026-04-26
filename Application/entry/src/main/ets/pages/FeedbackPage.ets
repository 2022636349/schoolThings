import { router, window } from '@kit.ArkUI';
import { FeedbackService } from '../services/FeedbackService';
import { Feedback } from '../model/Feedback';
import { MeteorOverlay } from '../components/MeteorOverlay';

@Entry
@Component
export struct FeedbackPage {
  @State topHeight: number = 0;
  @State content: string = '';
  @State isSubmitting: boolean = false;
  @State isLoading: boolean = true;
  @State items: Feedback[] = [];

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
    });
    this.loadFeedbacks();
  }

  private async loadFeedbacks(): Promise<void> {
    this.isLoading = true;
    try {
      this.items = await FeedbackService.listMine();
    } finally {
      this.isLoading = false;
    }
  }

  private async handleSubmit(): Promise<void> {
    if (!this.content.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入反馈内容' });
      return;
    }
    this.isSubmitting = true;
    try {
      await FeedbackService.submit(this.content.trim());
      this.getUIContext().getPromptAction().showToast({ message: '反馈已提交，感谢你的建议' });
      this.content = '';
      await this.loadFeedbacks();
    } finally {
      this.isSubmitting = false;
    }
  }

  private replyText(item: Feedback): string {
    const text = item.reply.trim();
    if (text.length > 0) return text;
    return '管理员暂未回复，我们会尽快查看。';
  }

  private feedbackCountText(): string {
    return `${this.content.length}/300`;
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
        .onClick(() => {
          if (AppStorage.get<boolean>('isTabletMode') === true) {
            AppStorage.setOrCreate('tabletRightType', 'none');
            AppStorage.setOrCreate('tabletRightParams', '');
            AppStorage.setOrCreate('tabletPrevRightType', 'none');
            AppStorage.setOrCreate('tabletPrevRightParams', '');
          } else {
            router.back();
          }
        })

        Text('意见反馈')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 10 }) {
            Row() {
              Text('反馈内容')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              Text('提交后可在下方查看回复')
                .fontSize(12)
                .fontColor($r('app.color.text_hint'))
            }
            .width('100%')

            Stack({ alignContent: Alignment.BottomEnd }) {
              TextArea({ placeholder: '例如：发布页面分类不好找，希望增加常用分类；或者某个按钮点击没有反应。', text: this.content })
                .width('100%')
                .height(128)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_hint'))
                .backgroundColor($r('app.color.bg_input_area'))
                .borderRadius(14)
                .padding({ left: 12, right: 12, top: 10, bottom: 28 })
                .onChange((v: string) => {
                  this.content = v.length > 300 ? v.substring(0, 300) : v;
                })

              Text(this.feedbackCountText())
                .fontSize(11)
                .fontColor(this.content.length >= 300 ? '#FF4D4F' : $r('app.color.text_disabled'))
                .margin({ right: 12, bottom: 8 })
            }
            .width('100%')

            Row({ space: 10 }) {
              Text('功能建议、异常体验、内容问题都可以提交')
                .fontSize(12)
                .fontColor($r('app.color.text_hint'))
                .layoutWeight(1)

              Button(this.isSubmitting ? '提交中...' : '提交反馈')
                .height(38)
                .padding({ left: 18, right: 18 })
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(this.content.trim().length === 0 || this.isSubmitting ? '#A9C5E8' : '#4E8FDF')
                .borderRadius(21)
                .enabled(!this.isSubmitting)
                .onClick(() => { this.handleSubmit(); })
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius(14)

          Row() {
            Column({ space: 2 }) {
              Text('反馈记录')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text(this.items.length > 0 ? `共 ${this.items.length} 条` : '提交后的反馈会显示在这里')
                .fontSize(12)
                .fontColor($r('app.color.text_hint'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row({ space: 4 }) {
              Text('刷新')
                .fontSize(13)
                .fontColor('#4E8FDF')
            }
            .height(34)
            .padding({ left: 12, right: 12 })
            .backgroundColor($r('app.color.bg_card'))
            .borderRadius(17)
            .onClick(() => { this.loadFeedbacks(); })
          }
          .width('100%')

          if (this.isLoading) {
            Column() {
              LoadingProgress().width(32).height(32).color('#4E8FDF')
            }
            .width('100%')
            .height(100)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else if (this.items.length === 0) {
            Column({ space: 6 }) {
              Text('暂无反馈记录')
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
              Text('提交后的反馈和管理员回复会显示在这里')
                .fontSize(12)
                .fontColor($r('app.color.text_hint'))
            }
            .width('100%')
            .padding(18)
            .backgroundColor($r('app.color.bg_card'))
            .borderRadius(14)
          } else {
            ForEach(this.items, (item: Feedback) => {
              Row({ space: 10 }) {
                Column() {
                  Text(item.reply ? '✓' : '…')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(item.reply ? '#4CAF50' : '#FF9500')
                }
                .width(30)
                .height(30)
                .borderRadius(15)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(item.reply ? 'rgba(76,175,80,0.12)' : 'rgba(255,149,0,0.12)')

                Column({ space: 10 }) {
                  Row() {
                    Text(item.reply ? '已回复' : '等待回复')
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(item.reply ? '#4CAF50' : '#FF9500')
                    Blank()
                    if (item.createdAt) {
                      Text(item.createdAt.toLocaleString())
                        .fontSize(11)
                        .fontColor($r('app.color.text_disabled'))
                    }
                  }
                  .width('100%')

                  Text(item.content)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .width('100%')

                  Column({ space: 6 }) {
                    Text('管理员回复')
                      .fontSize(12)
                      .fontColor($r('app.color.text_tertiary'))
                    Text(this.replyText(item))
                      .fontSize(13)
                      .fontColor(item.reply ? $r('app.color.text_primary') : $r('app.color.text_hint'))
                      .width('100%')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                  .padding(12)
                  .backgroundColor($r('app.color.bg_secondary'))
                  .borderRadius(12)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.bg_card'))
              .borderRadius(16)
            })
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))

      MeteorOverlay({ suppressInTablet: true })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
