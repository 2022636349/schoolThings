import router from '@ohos.router';
import { TopNavBar } from '../components/TopNavBar';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../services/AuthService';
import { UserService } from '../services/UserService';
import picker from '@ohos.file.picker';

interface MenuItemConfig {
  icon: string | Resource;
  label: string | Resource;
  action: () => void;
  isRed?: boolean;
}

interface StatCardConfig {
  value: string;
  label: string;
  accent: string;
  bg: string;
}

@Entry
@Component
export struct PersonalPage {
  @State studentId: string = '---';
  @State name: string = '未登录';
  @State published: number = 0;
  @State claimed: number = 0;
  @State heartValue: number = 0;
  @State fraudCount: number = 0;
  @State phone: string = '';
  @State avatarUrl: string = '';
  @State isUploadingAvatar: boolean = false;
  @State isRefreshing: boolean = false;
  @Prop topHeight: number = 0;

  aboutToAppear(): void {
    this.loadProfile();
  }

  onPageShow(): void {

    this.loadProfile();
  }

  async loadProfile(): Promise<void> {
    const session = await AuthService.getSession(getContext(this) as common.UIAbilityContext);
    if (session) {
      this.studentId = session.studentNo || session.id;
      this.name = session.name;
      this.published = session.published;
      this.claimed = session.claimed;
      this.heartValue = session.heartValue;
      this.fraudCount = session.fraudCount;
      this.phone = session.phoneMasked || '';
      this.avatarUrl = session.avatar ?? '';
    }
  }

  async doRefresh(): Promise<void> {
    await this.loadProfile();
    this.isRefreshing = false;
  }

  async pickAndUploadAvatar(): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);
      if (!result.photoUris || result.photoUris.length === 0) return;

      this.isUploadingAvatar = true;
      const ctx = getContext(this) as common.UIAbilityContext;
      await UserService.uploadAvatar(ctx, result.photoUris[0]);
      await this.loadProfile();
      this.getUIContext().getPromptAction().showToast({ message: '头像更新成功' });
      this.isRefreshing = true;
      this.isRefreshing = false;
    } catch (error) {
      console.error('[PersonalPage] 头像上传失败:', error);
      this.getUIContext().getPromptAction().showToast({ message: '头像上传失败，请重试' });
    } finally {
      this.isUploadingAvatar = false;
    }
  }

  build() {
    Column() {
      TopNavBar({ title: '个人中心' })
        .padding({ top: this.topHeight })

      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 16 }) {

            Column({ space: 18 }) {
              Row({ space: 16 }) {

                Stack({ alignContent: Alignment.BottomEnd }) {
                  if (this.avatarUrl) {
                    Image(this.avatarUrl)
                      .width(64).height(64).borderRadius(32)
                      .objectFit(ImageFit.Cover).backgroundColor($r('app.color.bg_avatar_placeholder'))
                  } else {
                    Stack() {
                      Circle().width(64).height(64).fill('#007DFF').opacity(0.1)
                      Text(this.name?.charAt(0) || 'U')
                        .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#007DFF')
                    }.width(64).height(64).borderRadius(32)
                  }

                  if (this.isUploadingAvatar) {
                    Stack() {
                      Circle().width(22).height(22).fill('#FFFFFF')
                      LoadingProgress().width(16).height(16).color('#007DFF')
                    }.width(22).height(22).borderRadius(11)
                    .shadow({ radius: 4, color: 'rgba(0,0,0,0.15)', offsetY: 1 })
                  } else {
                    Stack() {
                      Circle().width(22).height(22).fill('#007DFF')
                      Text('+').fontSize(14).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
                    }.width(22).height(22).borderRadius(11)
                    .shadow({ radius: 4, color: 'rgba(0,0,0,0.15)', offsetY: 1 })
                  }
                }
                .width(64).height(64)
                .onClick(() => {
                  if (!this.isUploadingAvatar) { this.pickAndUploadAvatar(); }
                })

                Column({ space: 4 }) {
                  Text(this.name)
                    .fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_secondary'))
                  Text(`学号：${this.studentId}`)
                    .fontSize(14).fontColor($r('app.color.text_caption'))
                  if (this.phone) {
                    Text(`手机号：${this.phone}`)
                      .fontSize(13).fontColor($r('app.color.text_caption'))
                  }
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%')

              Row({ space: 10 }) {
                this.StatCard({
                  value: this.published.toString(),
                  label: '发布信息',
                  accent: '#4E8FDF',
                  bg: 'rgba(78,143,223,0.10)'
                })
                this.StatCard({
                  value: this.claimed.toString(),
                  label: '已认领',
                  accent: '#4CAF50',
                  bg: 'rgba(76,175,80,0.10)'
                })
                this.StatCard({
                  value: this.heartValue.toString(),
                  label: '热心值',
                  accent: '#FF6B9D',
                  bg: 'rgba(255,107,157,0.10)'
                })
                this.StatCard({
                  value: this.fraudCount.toString(),
                  label: '异常次数',
                  accent: this.fraudCount > 0 ? '#FF9500' : '#9E9E9E',
                  bg: this.fraudCount > 0 ? 'rgba(255,149,0,0.10)' : 'rgba(158,158,158,0.10)'
                })
              }
              .width('100%')
            }
            .width('100%').padding(20)
            .backgroundColor($r('app.color.bg_card')).borderRadius(16)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })

            Column() {
              this.OptimizedMenuItem({
                icon: $r('app.media.send'),
                label: '我的发布',
                action: (): void => {
                  if (AppStorage.get<boolean>('isTabletMode') === true) {
                    AppStorage.setOrCreate('tabletPrevRightType', 'none');
                    AppStorage.setOrCreate('tabletPrevRightParams', '');
                    AppStorage.setOrCreate('tabletRightParams', '');
                    AppStorage.setOrCreate('tabletRightType', 'myPosts');
                  } else {
                    router.pushUrl({ url: 'pages/MyPostsPage' });
                  }
                }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56, right: 56 })
              this.OptimizedMenuItem({
                icon: $r('app.media.like'),
                label: '我的点赞',
                action: (): void => {
                  if (AppStorage.get<boolean>('isTabletMode') === true) {
                    AppStorage.setOrCreate('tabletPrevRightType', 'none');
                    AppStorage.setOrCreate('tabletPrevRightParams', '');
                    AppStorage.setOrCreate('tabletRightParams', '');
                    AppStorage.setOrCreate('tabletRightType', 'myLiked');
                  } else {
                    router.pushUrl({ url: 'pages/MyLikedPage' });
                  }
                }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56, right: 56 })
              this.OptimizedMenuItem({
                icon: $r('app.media.abnormal'),
                label: '我的异议',
                action: (): void => {
                  if (AppStorage.get<boolean>('isTabletMode') === true) {
                    AppStorage.setOrCreate('tabletPrevRightType', 'none');
                    AppStorage.setOrCreate('tabletPrevRightParams', '');
                    AppStorage.setOrCreate('tabletRightParams', '');
                    AppStorage.setOrCreate('tabletRightType', 'myReports');
                  } else {
                    router.pushUrl({ url: 'pages/MyReportsPage' });
                  }
                }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56, right: 56 })
              this.OptimizedMenuItem({
                icon: $r('app.media.accept'),
                label: '意见反馈',
                action: (): void => {
                  if (AppStorage.get<boolean>('isTabletMode') === true) {
                    AppStorage.setOrCreate('tabletPrevRightType', 'none');
                    AppStorage.setOrCreate('tabletPrevRightParams', '');
                    AppStorage.setOrCreate('tabletRightParams', '');
                    AppStorage.setOrCreate('tabletRightType', 'feedback');
                  } else {
                    router.pushUrl({ url: 'pages/FeedbackPage' });
                  }
                }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56, right: 56 })
              this.OptimizedMenuItem({
                icon: $r('app.media.setting'),
                label: '设置',
                action: (): void => {
                  if (AppStorage.get<boolean>('isTabletMode') === true) {
                    AppStorage.setOrCreate('tabletPrevRightType', 'none');
                    AppStorage.setOrCreate('tabletPrevRightParams', '');
                    AppStorage.setOrCreate('tabletRightParams', '');
                    AppStorage.setOrCreate('tabletRightType', 'settings');
                  } else {
                    router.pushUrl({ url: 'pages/SettingsPage' });

                  }
                }
              })
            }
            .width('100%').backgroundColor($r('app.color.bg_card')).borderRadius(16)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
            .padding({ top: 8, bottom: 8 })

          }
          .width('100%').padding(16)
        }
      }
      .layoutWeight(1)
      .onRefreshing(() => { this.doRefresh() })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  StatCard(config: StatCardConfig) {
    Column({ space: 6 }) {
      Text(config.value)
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor(config.accent)
      Text(config.label)
        .fontSize(12).fontColor($r('app.color.text_caption'))
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(config.bg)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  OptimizedMenuItem(config: MenuItemConfig) {
    Row({ space: 16 }) {
      Image(config.icon)
        .width(22).height(22)
        .fillColor(config.isRed ? '#FF4D4F' : '#007DFF')

      Text(config.label)
        .fontSize(16).fontWeight(FontWeight.Medium)
        .fontColor(config.isRed ? '#FF4D4F' : $r('app.color.text_primary'))
        .layoutWeight(1)

      Image($r('app.media.arrow_right'))
        .width(18).height(18).fillColor('#CCCCCC')
    }
    .width('100%').height(56)
    .padding({ left: 20, right: 20 })
    .onClick(config.action)
  }
}
