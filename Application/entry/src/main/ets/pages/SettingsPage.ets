import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../services/AuthService';
import { UserService } from '../services/UserService';

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

@CustomDialog
struct EditProfileDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: EditProfileDialog() });
  @State nickname: string = '';
  @State phone: string = '';
  onSubmit: (nickname: string, phone: string) => void = () => {};

  build() {
    Column({ space: 16 }) {
      Text('编辑资料')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .width('100%').textAlign(TextAlign.Center)

      TextInput({ placeholder: '昵称', text: this.nickname })
        .fontSize(15).height(48)
        .backgroundColor($r('app.color.bg_secondary')).borderRadius(10)
        .onChange((v: string) => { this.nickname = v; })

      TextInput({ placeholder: '手机号', text: this.phone })
        .type(InputType.PhoneNumber)
        .fontSize(15).height(48)
        .backgroundColor($r('app.color.bg_secondary')).borderRadius(10)
        .onChange((v: string) => { this.phone = v; })

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1).height(46)
          .fontSize(15).fontColor($r('app.color.text_tertiary'))
          .backgroundColor($r('app.color.bg_input')).borderRadius(23)
          .onClick(() => { this.controller.close(); })

        Button('保存')
          .layoutWeight(1).height(46)
          .fontSize(15).fontColor('#FFFFFF')
          .backgroundColor('#4E8FDF').borderRadius(23)
          .onClick(() => { this.onSubmit(this.nickname, this.phone); })
      }
      .width('100%')
    }
    .padding(24)
    .borderRadius(20)
    .backgroundColor($r('app.color.bg_card'))
    .width('85%')
  }
}

interface MenuItemConfig {
  icon: string | Resource;
  label: string | Resource;
  action: () => void;
  isRed?: boolean;
}

@Entry
@Component
export struct SettingsPage {
  @State name: string = '';
  @State phone: string = '';
  @State editProfileNickname: string = '';
  @State editProfilePhone: string = '';
  @State topHeight: number = 0;

  private editProfileController: CustomDialogController = new CustomDialogController({
    builder: EditProfileDialog({
      nickname: this.editProfileNickname,
      phone: this.editProfilePhone,
      onSubmit: (nickname: string, phone: string) => {
        this.doUpdateProfile(nickname, phone);
      }
    }),
    alignment: DialogAlignment.Center,
    cornerRadius: 20
  });

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
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
    });
    this.loadProfile();
  }

  async loadProfile(): Promise<void> {
    const session = await AuthService.getSession(getContext(this) as common.UIAbilityContext);
    if (session) {
      this.name = session.name || '';
      this.phone = session.phoneMasked || '';
      this.editProfileNickname = this.name;
      this.editProfilePhone = this.phone;
    }
  }

  async doUpdateProfile(nickname: string, phone: string): Promise<void> {
    const nextNickname = nickname.trim();
    const nextPhone = phone.trim();
    if (!nextNickname) {
      promptAction.showToast({ message: '昵称不能为空' });
      return;
    }
    if (nextPhone && !/^1[3-9]\d{9}$/.test(nextPhone)) {
      promptAction.showToast({ message: '手机号格式不正确' });
      return;
    }
    try {
      await UserService.updateProfile(getContext(this) as common.UIAbilityContext, nextNickname, nextPhone);
      this.editProfileController.close();
      this.name = nextNickname;
      this.phone = nextPhone;
      this.editProfileNickname = nextNickname;
      this.editProfilePhone = nextPhone;
      promptAction.showToast({ message: '资料更新成功' });
    } catch (e) {
      promptAction.showToast({ message: '资料更新失败，请稍后重试' });
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
      message: '校园失物招领\n版本 1.0.0\n\n致力于帮助同学们快速找回失物，让校园更温暖、更有爱。\n\n隐私政策：当前版本为占位说明，后续将补充正式链接。\n用户协议：当前版本为占位说明，后续将补充正式链接。\n\n如有问题请联系管理员。',
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
      // 顶部导航
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.icon_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary')).justifyContent(FlexAlign.Center)
        .onClick(() => { router.back(); })

        Text('设置')
          .fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topHeight + 10, bottom: 14 })
      .backgroundColor($r('app.color.bg_card'))
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })

      Scroll() {
        Column({ space: 16 }) {

          // ─── 账号与安全 ───
          Column() {
            Text('账号与安全')
              .fontSize(13).fontColor($r('app.color.text_caption'))
              .width('100%').padding({ left: 20, top: 12, bottom: 8 })

            Column() {
              this.OptimizedMenuItem({
                icon: $r('app.media.ic_public_edit'),
                label: '编辑资料',
                action: (): void => {
                  this.editProfileNickname = this.name;
                  this.editProfilePhone = this.phone;
                  this.editProfileController.open();
                }
              })
              Divider().color($r('app.color.divider')).opacity(0.5).margin({ left: 56, right: 56 })
              this.OptimizedMenuItem({
                icon: $r('app.media.key'),
                label: '修改密码',
                action: (): void => { this.changePwdController.open(); }
              })
            }
            .width('100%').backgroundColor($r('app.color.bg_card')).borderRadius(16)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')

          // ─── 其他 ───
          Column() {
            Text('其他')
              .fontSize(13).fontColor($r('app.color.text_caption'))
              .width('100%').padding({ left: 20, top: 4, bottom: 8 })

            Column() {
              this.OptimizedMenuItem({
                icon: $r('app.media.bill'),
                label: '关于我们',
                action: (): void => { this.showAboutUs(); }
              })
            }
            .width('100%').backgroundColor($r('app.color.bg_card')).borderRadius(16)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')

          // ─── 退出登录（独立区块，红色） ───
          Column() {
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
          .margin({ top: 8 })

        }
        .width('100%').padding(16)
      }
      .layoutWeight(1)
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
