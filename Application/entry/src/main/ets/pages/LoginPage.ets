import { router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { common } from '@kit.AbilityKit';
import { MeteorOverlay } from '../components/MeteorOverlay';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  private videoController: VideoController = new VideoController();

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
        this.getUIContext().getPromptAction().showToast({ message: '登录成功' });
        AuthService.saveSession(getContext(this) as common.UIAbilityContext, this.username, this.username);
        router.replaceUrl({ url: 'pages/HomePage' })
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '登录失败，请稍后重试';
      this.getUIContext().getPromptAction().showToast({ message: this.errorMessage });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      Stack() {
      Video({
        src: $rawfile('campus_bg.mp4'),
        controller: this.videoController
      })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .autoPlay(true)
        .loop(true)
        .controls(false)
        .muted(true)
        .onAppear(() => {
          this.videoController.start();
        })

      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(0, 0, 0, 0.15)')

      Scroll() {
        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(90)
              .height(90)
              .margin({ top: 60, bottom: 20 })

            Text('校园失物招领')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ bottom: 40 })
              .textShadow({ radius: 2, color: Color.Black, offsetX: 1, offsetY: 1 })
          }
          .width('100%')

          Column({ space: 16 }) {
            TextInput({ placeholder: '请输入学号', text: this.username })
              .width('85%')
              .height(55)
              .backgroundColor('rgba(255, 255, 255, 0.9)')
              .onChange(value => this.username = value)
              .fontColor(Color.Black)
              .placeholderColor(Color.Gray)

            TextInput({ placeholder: '请输入密码', text: this.password })
              .type(InputType.Password)
              .width('85%')
              .height(55)
              .backgroundColor('rgba(255, 255, 255, 0.9)')
              .onChange(value => this.password = value)
              .fontColor(Color.Black)
              .placeholderColor(Color.Gray)
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

      MeteorOverlay()
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
