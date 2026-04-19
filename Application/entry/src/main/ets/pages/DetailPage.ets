import { router, promptAction, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { ItemService, MediaItem } from '../services/ItemService';
import { ClaimRequestDialog } from '../components/ClaimRequestDialog';
import { DisputeDialog } from '../components/DisputeDialog';
import { ClaimService } from '../services/ClaimService';
import { ReportService } from '../services/ReportService';
import { deriveStatus, getStatusLabel, getStatusColor, getStatusBg } from '../model/ItemCategory';

interface DetailParams {
  itemId: number;
  type: string;
  text: string;
  publishTime: string;
  publishId: string;
  publisherName: string;
  publisherAvatar: string;
  mediaList: string;
  category: string;
  likeCount: number;
  status: string;
  claimedBy: string | null;
  lostTime: number;
}

interface HallLikeSyncPayload {
  itemId: number;
  isLiked: boolean;
  likeCount: number;
}

@Entry
@Component
export struct DetailPage {
  @Prop @Watch('onParamsJsonChange') paramsJson: string = '';
  @State params: DetailParams = {
    itemId: 0,
    type: '',
    text: '',
    publishTime: '',
    publishId: '',
    publisherName: '',
    publisherAvatar: '',
    mediaList: '[]',
    category: '',
    likeCount: 0,
    status: 'active',
    claimedBy: '',
    lostTime: 0
  };
  @State mediaList: MediaItem[] = [];
  @State currentUserId: string = '';
  @State isLiked: boolean = false;
  @State likeCount: number = 0;
  @State isContacting: boolean = false;
  @State isDeleting: boolean = false;
  @State showClaimDialog: boolean = false;
  @State showDisputeDialog: boolean = false;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  onParamsJsonChange(): void {
    if (this.paramsJson) {
      this.loadFromJson(this.paramsJson);
    }
  }

  private loadFromJson(json: string): void {
    try {
      const p = JSON.parse(json) as DetailParams;
      this.params = p;
      this.mediaList = JSON.parse(p.mediaList) as MediaItem[];
      this.likeCount = p.likeCount || 0;
    } catch (e) {
      this.mediaList = [];
    }
    this.isContacting = false;
    this.isDeleting = false;
    this.showClaimDialog = false;
    this.showDisputeDialog = false;
  }

  aboutToAppear(): void {
    if (this.paramsJson) {
      this.loadFromJson(this.paramsJson);
    } else {
      const p = router.getParams() as DetailParams;
      if (p) {
        this.params = p;
        this.likeCount = p.likeCount || 0;
        try {
          this.mediaList = JSON.parse(p.mediaList) as MediaItem[];
        } catch (e) {
          this.mediaList = [];
        }
      }
    }
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    AuthService.getSession(getContext(this) as common.UIAbilityContext).then((session) => {
      if (session) {
        this.currentUserId = session.id;
        this.checkLikeStatus();
      }
    });
  }

  private async checkLikeStatus(): Promise<void> {
    if (!this.currentUserId || !this.params.itemId) return;
    try {
      this.isLiked = await ItemService.hasLiked(this.params.itemId, this.currentUserId);
    } catch (e) {
      console.warn('[DetailPage] 检查点赞状态失败:', e);
    }
  }

  private async handleToggleLike(): Promise<void> {
    if (!this.currentUserId || !this.params.itemId) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }
    try {
      const newLikeStatus = await ItemService.toggleLike(this.params.itemId, this.currentUserId);
      this.isLiked = newLikeStatus;
      this.likeCount = newLikeStatus ? this.likeCount + 1 : Math.max(0, this.likeCount - 1);
      this.params.likeCount = this.likeCount;
      const syncPayload: HallLikeSyncPayload = {
        itemId: this.params.itemId,
        isLiked: this.isLiked,
        likeCount: this.likeCount
      };
      AppStorage.setOrCreate('hallLikeSync', JSON.stringify(syncPayload));
      promptAction.showToast({ message: newLikeStatus ? '已点赞' : '已取消点赞' });
    } catch (error) {
      promptAction.showToast({ message: '操作失败' });
    }
  }

  deleteItem(): void {
    AlertDialog.show({
      title: '确认删除',
      message: '删除后将无法恢复',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4D4F',
        action: () => { this.doDelete(); }
      },
      alignment: DialogAlignment.Center
    });
  }

  async doDelete(): Promise<void> {
    if (this.isDeleting) return;
    this.isDeleting = true;
    try {
      await ItemService.deleteItem(this.params.itemId, this.currentUserId);
      AppStorage.setOrCreate('myPostsRefresh', Date.now());
      AppStorage.setOrCreate('homeNeedRefresh', true);
      promptAction.showToast({ message: '删除成功' });
      this.goBack();
    } catch (error) {
      const msg = error instanceof Error ? error.message : '删除失败';
      promptAction.showToast({ message: msg });
    } finally {
      this.isDeleting = false;
    }
  }

  async handleClaimRequest(description: string): Promise<void> {
    try {
      await ClaimService.create(this.params.itemId, description);
      promptAction.showToast({ message: '申请已提交，等待物品拥有者确认' });
      this.showClaimDialog = false;
    } catch (error) {
      const msg = error instanceof Error ? error.message : '提交失败';
      promptAction.showToast({ message: msg });
    }
  }

  async handleDispute(description: string): Promise<void> {
    try {
      await ReportService.reportItem(this.params.itemId, description);
      promptAction.showToast({ message: '异议已提交，管理员将尽快处理' });
      this.showDisputeDialog = false;
    } catch (error) {
      const msg = error instanceof Error ? error.message : '提交失败';
      promptAction.showToast({ message: msg });
    }
  }

  goBack(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      const prev = AppStorage.get<string>('tabletPrevRightType') || 'none';
      const prevParams = AppStorage.get<string>('tabletPrevRightParams') || '';
      AppStorage.setOrCreate('tabletRightParams', prevParams);
      AppStorage.setOrCreate('tabletRightType', prev);
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
    } else {
      router.back();
    }
  }

  async contactOwner(): Promise<void> {
    if (this.isContacting) return;
    this.isContacting = true;
    try {
      const session = await ChatService.getOrCreateSession(
        this.params.itemId,
        this.currentUserId,
        this.params.publishId
      );
      await ChatService.sendItemCardMessage(session.sessionId, {
        itemId: this.params.itemId,
        title: this.params.text.split('\n')[0] || this.params.text || '物品卡片',
        type: this.params.type,
        publisherName: this.params.publisherName || '匿名用户'
      });
      const cp: Record<string, Object> = {};
      cp['sessionId'] = session.sessionId;
      cp['itemId'] = this.params.itemId;
      cp['itemText'] = this.params.text;
      cp['itemType'] = this.params.type;
      cp['ownerId'] = this.params.publishId;
      cp['otherUserId'] = this.params.publishId;
      cp['otherUserName'] = this.params.publisherName;
      cp['otherUserAvatar'] = this.params.publisherAvatar;
      cp['isInitiator'] = 'true';
      if (AppStorage.get<boolean>('isTabletMode') === true) {
        AppStorage.setOrCreate('tabletPrevRightType', 'detail');
        AppStorage.setOrCreate('tabletPrevRightParams', this.paramsJson || JSON.stringify(this.params));
        AppStorage.setOrCreate('tabletRightType', 'chat');
        AppStorage.setOrCreate('tabletRightParams', JSON.stringify(cp));
      } else {
        router.pushUrl({ url: 'pages/ChatPage', params: cp });
      }
    } catch (error) {
      console.error('[DetailPage] 创建会话失败:', error);
      promptAction.showToast({ message: '操作失败' });
    } finally {
      this.isContacting = false;
    }
  }

  private getDisplayStatus() {
    return deriveStatus(this.params.type, this.params.status);
  }

  private getLostTimeString(): string {
    if (!this.params.lostTime || this.params.lostTime <= 0) return '';
    const d = new Date(this.params.lostTime);
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  onMediaClick(index: number): void {
    router.pushUrl({
      url: 'pages/MediaPreview',
      params: { mediaList: this.mediaList, currentIndex: index }
    });
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航
        Row() {
          Row() {
            Image($r('sys.media.ohos_ic_public_arrow_left'))
              .width(22).height(22).fillColor('#FFFFFF')
          }
          .width(40).height(40).borderRadius(20)
          .backgroundColor('rgba(0,0,0,0.25)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.goBack() })

          Text('物品详情')
            .fontSize(17).fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .layoutWeight(1).textAlign(TextAlign.Center)

          Row().width(40).height(40)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 10, bottom: 12 })
        .position({ x: 0, y: 0 }).zIndex(10)

        // 可滚动内容
        Scroll() {
          Column({ space: 0 }) {
            // 媒体轮播
            if (this.mediaList.length > 0) {
              Swiper() {
                ForEach(this.mediaList, (media: MediaItem, index: number) => {
                  if (media.type === 'image') {
                    Image(media.url)
                      .width('100%').height(320).objectFit(ImageFit.Cover)
                      .onClick(() => { this.onMediaClick(index) })
                  } else {
                    Stack() {
                      Image('').width('100%').height(320).backgroundColor('#111')
                      Column() {
                        Text('▶').fontSize(48).fontColor('#FFF')
                      }
                      .width('100%').height(320).justifyContent(FlexAlign.Center)
                    }
                    .width('100%').height(320).onClick(() => { this.onMediaClick(index) })
                  }
                })
              }
              .width('100%').height(320)
              .indicator(this.mediaList.length > 1)
              .loop(this.mediaList.length > 1)
              .autoPlay(false)
            } else {
              Column() {
                Text('📷').fontSize(40)
                Text('暂无图片').fontSize(14).fontColor($r('app.color.text_disabled')).margin({ top: 8 })
              }
              .width('100%').height(200)
              .backgroundColor($r('app.color.bg_image_placeholder'))
              .justifyContent(FlexAlign.Center)
            }

            // 信息卡片
            Column({ space: 0 }) {
              // 发布者和点赞
              Row({ space: 12 }) {
                if (this.params.publisherAvatar) {
                  Image(this.params.publisherAvatar)
                    .width(44).height(44).borderRadius(22)
                    .objectFit(ImageFit.Cover)
                } else {
                  Stack() {
                    Circle().width(44).height(44).fill('#4E8FDF').opacity(0.12)
                    Text(this.params.publisherName?.charAt(0) || '?')
                      .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#4E8FDF')
                  }.width(44).height(44).borderRadius(22)
                }

                Column({ space: 6 }) {
                  Text(this.params.publisherName || '匿名用户')
                    .fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                  Row({ space: 8 }) {
                    Text(getStatusLabel(this.params.type, this.getDisplayStatus()))
                      .fontSize(11).fontColor(getStatusColor(this.getDisplayStatus()))
                      .backgroundColor(getStatusBg(this.getDisplayStatus()))
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
                    if (this.params.publishTime) {
                      Text(this.params.publishTime)
                        .fontSize(12).fontColor($r('app.color.text_hint'))
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)

                // 点赞按钮
                Row({ space: 2 }) {
                  Text(this.isLiked ? '❤️' : '🤍').fontSize(16)
                  Text(this.likeCount.toString()).fontSize(12).fontColor($r('app.color.text_hint'))
                }
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(this.isLiked ? 'rgba(255,0,0,0.1)' : '#F5F5F5')
                .borderRadius(6)
                .onClick(() => { this.handleToggleLike() })
              }
              .width('100%').padding({ left: 16, right: 16, top: 20, bottom: 16 })

              Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })

              // 分类和丢失时间
              if (this.params.category || this.params.lostTime) {
                Row({ space: 16 }) {
                  if (this.params.category) {
                    Column({ space: 4 }) {
                      Text('分类').fontSize(12).fontColor($r('app.color.text_hint'))
                      Text(this.params.category).fontSize(14).fontColor($r('app.color.text_primary'))
                    }
                    .alignItems(HorizontalAlign.Start)
                  }
                  if (this.params.lostTime && this.params.lostTime > 0) {
                    Column({ space: 4 }) {
                      Text('丢失时间').fontSize(12).fontColor($r('app.color.text_hint'))
                      Text(this.getLostTimeString()).fontSize(14).fontColor($r('app.color.text_primary'))
                    }
                    .alignItems(HorizontalAlign.Start)
                  }
                }
                .width('100%').padding({ left: 16, right: 16, top: 16, bottom: 12 })

                Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
              }

              // 描述
              Column({ space: 8 }) {
                Text('物品描述').fontSize(13).fontColor($r('app.color.text_hint')).fontWeight(FontWeight.Medium)
                Text(this.params.text || '（暂无描述）')
                  .fontSize(16).fontColor($r('app.color.text_primary'))
                  .lineHeight(26).width('100%')
              }
              .width('100%').padding({ left: 16, right: 16, top: 16, bottom: 24 })

              // 已认领提示
              if (this.params.status === 'claimed' && this.params.claimedBy) {
                Row() {
                  Text('✓ 已被 ' + (this.params.claimedBy || '用户') + ' 认领')
                    .fontSize(14).fontColor('#4CAF50').fontWeight(FontWeight.Medium)
                }
                .width('100%').padding(12)
                .backgroundColor('#E8F5E9')
                .borderRadius(8)
                .margin({ left: 16, right: 16, bottom: 16 })
              }
            }
            .width('100%').backgroundColor($r('app.color.bg_card'))

            Row().height(this.bottomHeight + 80)
          }
          .width('100%')
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)

        // 底部按钮
        Column() {
          if (this.currentUserId === this.params.publishId) {
            Row({ space: 12 }) {
              Text('您发布的物品').fontSize(15).fontColor($r('app.color.text_hint')).layoutWeight(1)
              Button('编辑')
                .height(40).fontSize(15).fontColor('#FFFFFF')
                .backgroundColor('#4E8FDF')
                .borderRadius(20).padding({ left: 20, right: 20 })
                .onClick(() => {
                  const editParams: Record<string, Object> = {};
                  editParams['itemId'] = this.params.itemId;
                  editParams['type'] = this.params.type;
                  editParams['text'] = this.params.text;
                  editParams['publishTime'] = this.params.publishTime;
                  editParams['publishId'] = this.params.publishId;
                  editParams['publisherName'] = this.params.publisherName;
                  editParams['publisherAvatar'] = this.params.publisherAvatar;
                  editParams['mediaList'] = JSON.stringify(this.mediaList);
                  editParams['category'] = this.params.category;
                  editParams['likeCount'] = this.params.likeCount;
                  editParams['status'] = this.params.status;
                  editParams['claimedBy'] = this.params.claimedBy || '';
                  editParams['lostTime'] = this.params.lostTime;
                  router.pushUrl({ url: 'pages/PostPage', params: editParams });
                })
              Button(this.isDeleting ? '删除中...' : '删除')
                .height(40).fontSize(15).fontColor('#FFFFFF')
                .backgroundColor(this.isDeleting ? '#FFAAAA' : '#FF4D4F')
                .borderRadius(20).padding({ left: 20, right: 20 })
                .enabled(!this.isDeleting).onClick(() => { this.deleteItem() })
            }
            .width('100%').height(50).alignItems(VerticalAlign.Center)
          } else if (this.params.status === 'claimed') {
            Row({ space: 12 }) {
              if (this.currentUserId === this.params.publishId) {
                Button('恢复招领中').layoutWeight(1).height(44)
                  .fontSize(14).fontColor('#FFFFFF')
                  .backgroundColor('#FF9500').borderRadius(8)
                  .onClick(async () => {
                    await ItemService.updateStatus(this.params.itemId, 'active');
                    this.params.status = 'active';
                    AppStorage.setOrCreate('myPostsRefresh', Date.now());
                    AppStorage.setOrCreate('homeNeedRefresh', true);
                    promptAction.showToast({ message: '已恢复为进行中' });
                  })
              }
              Button('联系TA').layoutWeight(1).height(44)
                .fontSize(14).fontColor('#FFFFFF')
                .backgroundColor('#4E8FDF').borderRadius(8)
                .onClick(() => { this.contactOwner() })

              Button('提交异议').layoutWeight(1).height(44)
                .fontSize(14).fontColor('#FFFFFF')
                .backgroundColor('#FF9500').borderRadius(8)
                .onClick(() => { this.showDisputeDialog = true })
            }
            .width('100%')
          } else {
            Row({ space: 12 }) {
              Button('联系TA').layoutWeight(1).height(44)
                .fontSize(14).fontColor('#FFFFFF')
                .backgroundColor('#4E8FDF').borderRadius(8)
                .onClick(() => { this.contactOwner() })

              if (this.currentUserId === this.params.publishId) {
                Button('标记已认领')
                  .layoutWeight(1).height(44)
                  .fontSize(14).fontColor('#FFFFFF')
                  .backgroundColor('#07C160').borderRadius(8)
                  .onClick(async () => {
                    await ItemService.updateStatus(this.params.itemId, 'claimed');
                    this.params.status = 'claimed';
                    this.params.claimedBy = this.currentUserId;
                    AppStorage.setOrCreate('myPostsRefresh', Date.now());
                    AppStorage.setOrCreate('homeNeedRefresh', true);
                    promptAction.showToast({ message: '已标记为已认领' });
                  })
              } else {
                Button(this.params.type === 'lost' ? '申请认领' : '申请归还')
                  .layoutWeight(1).height(44)
                  .fontSize(14).fontColor('#FFFFFF')
                  .backgroundColor('#07C160').borderRadius(8)
                  .onClick(() => { this.showClaimDialog = true })
              }
            }
            .width('100%')
          }
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: this.bottomHeight + 12 })
        .backgroundColor($r('app.color.bg_card'))
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: -2 })
      }
      .width('100%').height('100%')
      .backgroundColor($r('app.color.bg_page'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 对话框遮罩
      if (this.showClaimDialog || this.showDisputeDialog) {
        Column() {
          Column().width('100%').layoutWeight(1).onClick(() => {
            this.showClaimDialog = false;
            this.showDisputeDialog = false;
          })

          if (this.showClaimDialog) {
            ClaimRequestDialog({
              title: this.params.type === 'lost' ? '申请认领' : '申请归还',
              onConfirm: (desc: string) => this.handleClaimRequest(desc),
              onCancel: () => { this.showClaimDialog = false }
            })
          }

          if (this.showDisputeDialog) {
            DisputeDialog({
              onConfirm: (desc: string) => this.handleDispute(desc),
              onCancel: () => { this.showDisputeDialog = false }
            })
          }

          Row().height(this.bottomHeight)
        }
        .width('100%').height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%').height('100%')
  }
}
