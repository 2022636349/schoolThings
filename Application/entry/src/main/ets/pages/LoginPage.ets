import { promptAction, router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  private videoController: VideoController = new VideoController();

  async aboutToAppear() {
    await AuthService.initAnonymousLogin();
  }

  async handleLogin(): Promise<void> {
    if (this.username.trim() === '' || this.password.trim() === '') {
      this.errorMessage = '账号或密码不能为空！';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const isSuccess = await AuthService.login(this.username, this.password);
      if (isSuccess) {
        promptAction.showToast({ message: '登录成功' });
        // 注意：建议此处 saveSession 只保存必要信息，避免持久化明文密码
        AuthService.saveSession(getContext(this) as common.UIAbilityContext, this.username, this.username);
        router.replaceUrl({ url: 'pages/HomePage' });
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '登录失败，请稍后重试';
      promptAction.showToast({ message: this.errorMessage });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      // 1. 底层：视频背景（请确保视频文件已放入 resources/rawfile 目录下）
      Video({
        src: $rawfile('campus_bg.mp4'), // 替换为你实际的横屏视频文件名
        controller: this.videoController
      })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover) // 核心：自动居中裁剪，横屏视频适配竖屏
        .autoPlay(true)
        .loop(true)
        .controls(false)
        .muted(true)
        .onAppear(() => {
          this.videoController.start();
        })

      // 2. 中间层：半透明遮罩，提升表单可读性
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(0, 0, 0, 0.25)') // 25%透明度的黑色遮罩

      // 3. 顶层：登录表单
      Scroll() {
        Column() {
          // 顶部 Logo 与 标题
          Column() {
            Image($r('app.media.startIcon'))
              .width(90)
              .height(90)
              .margin({ top: 60, bottom: 20 })
              // 如果图标有白边，可以尝试增加阴影或反色处理以适应深色背景
              .shadow({ radius: 10, color: 'rgba(0,0,0,0.1)' })

            Text('校园失物招领')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White) // 改为白色以适应视频背景
              .margin({ bottom: 40 })
              .textShadow({ radius: 2, color: Color.Black, offsetX: 1, offsetY: 1 })
          }
          .width('100%')

          // 输入区域
          Column({ space: 16 }) {
            TextInput({ placeholder: '请输入学号', text: this.username })
              .width('85%')
              .height(55)
              .backgroundColor('rgba(255, 255, 255, 0.9)') // 输入框稍带透明度
              .onChange(value => this.username = value)

            TextInput({ placeholder: '请输入密码', text: this.password })
              .type(InputType.Password)
              .width('85%')
              .height(55)
              .backgroundColor('rgba(255, 255, 255, 0.9)')
              .onChange(value => this.password = value)
          }

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontColor('#FF6B6B')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ top: 15, bottom: 5 })
              .backgroundColor('rgba(0,0,0,0.4)')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(4)
          }

          // 登录按钮
          Button(this.isLoading ? '登录中...' : '登录')
            .width('85%')
            .height(55)
            .margin({ top: 30 })
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .enabled(!this.isLoading)
            .opacity(this.isLoading ? 0.6 : 1)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#007DFF', 0.0], ['#00A3FF', 1.0]]
            })
            .onClick(() => { this.handleLogin(); })

          Text('忘记密码？')
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ top: 14 })
            .textShadow({ radius: 1, color: Color.Black })
            .onClick(() => {
              this.errorMessage = '';
              router.pushUrl({ url: 'pages/ResetPasswordPage' });
            })

          // 注册引导
          Text('没有账号？立即注册')
            .fontSize(15)
            .fontColor(Color.White)
            .margin({ top: 25 })
            .textShadow({ radius: 1, color: Color.Black })
            .onClick(() => {
              this.errorMessage = '';
              router.pushUrl({ url: 'pages/RegisterPage' });
            })
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
  }
}