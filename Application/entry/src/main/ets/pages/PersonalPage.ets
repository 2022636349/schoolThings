import router from '@ohos.router';
import { TopNavBar } from '../components/TopNavBar';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../services/AuthService';
import { UserService } from '../services/UserService';
import picker from '@ohos.file.picker';

// ────── 修改密码弹窗 ──────
@CustomDialog
struct ChangePasswordDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: ChangePasswordDialog() });
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State confirmPwd: string = '';
  onSubmit: (oldPwd: string, newPwd: string, confirmPwd: string) => void = () => {};

  build() {
    Column({ space: 16 }) {
      Text('修改密码')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .width('100%').textAlign(TextAlign.Center)

      TextInput({ placeholder: '当前密码' })
        .type(InputType.Password)
        .fontSize(15).height(48)
        .backgroundColor($r('app.color.bg_secondary')).borderRadius(10)
        .onChange((v: string) => { this.oldPwd = v; })

      TextInput({ placeholder: '新密码（至少 6 位）' })
        .type(InputType.Password)
        .fontSize(15).height(48)
        .backgroundColor($r('app.color.bg_secondary')).borderRadius(10)
        .onChange((v: string) => { this.newPwd = v; })

      TextInput({ placeholder: '确认新密码' })
        .type(InputType.Password)
        .fontSize(15).height(48)
        .backgroundColor($r('app.color.bg_secondary')).borderRadius(10)
        .onChange((v: string) => { this.confirmPwd = v; })

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1).height(46)
          .fontSize(15).fontColor($r('app.color.text_tertiary'))
          .backgroundColor($r('app.color.bg_input')).borderRadius(23)
          .onClick(() => { this.controller.close(); })

        Button('确认修改')
          .layoutWeight(1).height(46)
          .fontSize(15).fontColor('#FFFFFF')
          .backgroundColor('#4E8FDF').borderRadius(23)
          .onClick(() => { this.onSubmit(this.oldPwd, this.newPwd, this.confirmPwd); })
      }
      .width('100%')
    }
    .padding(24)
    .borderRadius(20)
    .backgroundColor($r('app.color.bg_card'))
    .width('85%')
  }
}

// ────── 主页面 ──────
interface MenuItemConfig {
  icon: string | Resource;
  label: string | Resource;
  action: () => void;
  isRed?: boolean;
}

@Entry
@Component
export struct PersonalPage {
  @State studentId: string = '---';
  @State name: string = '未登录';
  @State published: number = 0;
  @State claimed: number = 0;
  @State avatarUrl: string = '';
  @State isUploadingAvatar: boolean = false;
  @State isRefreshing: boolean = false;
  @Prop topHeight: number = 0;

  private changePwdController: CustomDialogController = new CustomDialogController({
    builder: ChangePasswordDialog({
      onSubmit: (oldPwd: string, newPwd: string, confirmPwd: string) => {
        this.doChangePassword(oldPwd, newPwd, confirmPwd);
      }
    }),
    alignment: DialogAlignment.Center,
    cornerRadius: 20
  });

  aboutToAppear(): void {
    this.loadProfile();
  }

  async loadProfile(): Promise<void> {
    const session = await AuthService.getSession(getContext(this) as common.UIAbilityContext);
    if (session) {
      this.studentId = session.id;
      this.name = session.name;
      this.published = session.published;
      this.claimed = session.claimed;
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
      const url = await UserService.uploadAvatar(ctx, result.photoUris[0]);
      this.avatarUrl = url;
      promptAction.showToast({ message: '头像更新成功' });
      // 触发下拉刷新动画，完成后自动收起
      this.isRefreshing = true;
      await this.loadProfile();
      this.isRefreshing = false;
    } catch (error) {
      console.error('[PersonalPage] 头像上传失败:', error);
      promptAction.showToast({ message: '头像上传失败，请重试' });
    } finally {
      this.isUploadingAvatar = false;
    }
  }

  async doChangePassword(oldPwd: string, newPwd: string, confirmPwd: string): Promise<void> {
    if (!oldPwd || !newPwd || !confirmPwd) {
      promptAction.showToast({ message: '请填写完整信息' });
      return;
    }
    if (newPwd !== confirmPwd) {
      promptAction.showToast({ message: '两次密码不一致' });
      return;
    }
    if (newPwd.length < 6) {
      promptAction.showToast({ message: '新密码至少 6 位' });
      return;
    }
    try {
      const success = await AuthService.changePassword(
        getContext(this) as common.UIAbilityContext,
        oldPwd,
        newPwd
      );
      if (success) {
        this.changePwdController.close();
        promptAction.showToast({ message: '密码修改成功' });
      } else {
        promptAction.showToast({ message: '当前密码错误，请重试' });
      }
    } catch (e) {
      promptAction.showToast({ message: '修改失败，请稍后重试' });
    }
  }

  showAboutUs(): void {
    AlertDialog.show({
      title: '关于我们',
      message: '校园失物招领\n版本 1.0.0\n\n致力于帮助同学们快速找回失物，让校园更温暖、更有爱。\n\n如有问题请联系管理员。',
      confirm: {
        value: '我知道了',
        action: () => {}
      },
      alignment: DialogAlignment.Center
    });
  }

  showLogoutConfirm(): void {
    AlertDialog.show({
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '退出',
        fontColor: '#FF4D4F',
        action: () => { this.logout(); }
      },
      alignment: DialogAlignment.Center
    });
  }

  async logout(): Promise<void> {
    try {
      AuthService.clearSession(getContext(this) as common.UIAbilityContext);
      promptAction.showToast({ message: '已退出登录' });
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (error) {
      console.error('退出登录失败:', JSON.stringify(error));
    }
  }

  build() {
    Column() {
      TopNavBar({ title: '个人中心' })
        .padding({ top: this.topHeight })

      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 16 }) {

            // 用户卡片
            Column({ space: 16 }) {
              Row({ space: 16 }) {

                // 头像区域（可点击上传）
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

                // 用户信息
                Column({ space: 4 }) {
                  Text(this.name)
                    .fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_secondary'))
                  Text(`学号：${this.studentId}`)
                    .fontSize(14).fontColor($r('app.color.text_caption'))
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%')

              Divider().color($r('app.color.divider')).opacity(0.5)

              // 发布 / 认领统计
              Row() {
                Column({ space: 6 }) {
                  Text(this.published.toString())
                    .fontSize(26).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_secondary'))
                  Text('发布信息').fontSize(12).fontColor($r('app.color.text_caption'))
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                Column().width(1).height(40).backgroundColor('#E5E5E5').opacity(0.5)

                Column({ space: 6 }) {
                  Text(this.claimed.toString())
                    .fontSize(26).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_secondary'))
                  Text('已认领项目').fontSize(12).fontColor($r('app.color.text_caption'))
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              }
              .width('100%').padding({ left: 12, right: 12 })
            }
            .width('100%').padding(20)
            .backgroundColor($r('app.color.bg_card')).borderRadius(16)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })

            // 功能菜单
            Column() {
              this.OptimizedMenuItem({
                icon: $r('app.media.send'),
                label: '我的发布',
                action: (): void => {
                  if (AppStorage.get<boolean>('isTabletMode') === true) {
                    AppStorage.setOrCreate('tabletPrevRightType', 'personal');
                    AppStorage.setOrCreate('tabletRightType', 'myPosts');
                  } else {
                    router.pushUrl({ url: 'pages/MyPostsPage' });
                  }
                }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56 ,right:56})
              this.OptimizedMenuItem({
                icon: $r('app.media.key'),
                label: '修改密码',
                action: (): void => { this.changePwdController.open(); }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56,right:56 })
              this.OptimizedMenuItem({
                icon: $r('app.media.bill'),
                label: '关于我们',
                action: (): void => { this.showAboutUs(); }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56 ,right:56})
              this.OptimizedMenuItem({
                icon: $r('app.media.logout'),
                label: '退出登录',
                action: (): void => { this.showLogoutConfirm(); },
                isRed: true
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
