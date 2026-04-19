import { router, window } from '@kit.ArkUI';
import { AnnouncementService, AnnouncementItem } from '../services/AnnouncementService';

interface AnnouncementDetailParams {
  id: number;
}

@Entry
@Component
export struct AnnouncementDetailPage {
  @State topHeight: number = 0;
  @State title: string = '';
  @State cover: string = '';
  @State content: string = '';
  @State createTime: number = 0;
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State announcementId: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
    });
    const params = router.getParams() as AnnouncementDetailParams;
    if (params && params.id) {
      this.announcementId = params.id;
      this.loadDetail(params.id);
    } else {
      this.isLoading = false;
    }
  }

  private async loadDetail(id: number): Promise<void> {
    this.isLoading = !this.isRefreshing;
    try {
      const item = await AnnouncementService.detail(id);
      if (item) {
        this.title = item.title || '';
        this.cover = item.cover || '';
        this.content = item.content || '';
        this.createTime = item.createdAt || 0;
      }
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  private async onRefresh(): Promise<void> {
    if (!this.announcementId) {
      this.isRefreshing = false;
      return;
    }
    this.isRefreshing = true;
    await this.loadDetail(this.announcementId);
  }

  private getTimeText(): string {
    if (!this.createTime) return '';
    return new Date(this.createTime).toLocaleString();
  }

  private getDisplayContent(): string {
    const raw = this.content || '';
    if (!raw.trim()) return '暂无内容';
    return raw.replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/p>/gi, '\n\n')
      .replace(/<[^>]+>/g, '')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  build() {
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

        Text('公告详情')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#4E8FDF')
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column({ space: 12 }) {
              Text(this.title)
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              if (this.cover) {
                Image(this.cover)
                  .width('100%')
                  .height(180)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(12)
              }
              if (this.createTime > 0) {
                Text(this.getTimeText())
                  .fontSize(12).fontColor($r('app.color.text_hint'))
                  .width('100%')
              }
              Text(this.getDisplayContent())
                .fontSize(15)
                .lineHeight(26)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            }
            .width('100%')
            .padding(16)
          }
          .scrollBar(BarState.Off)
        }
        .layoutWeight(1)
        .onRefreshing(() => { this.onRefresh(); })
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
