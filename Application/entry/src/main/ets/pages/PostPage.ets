import { router, promptAction, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import picker from '@ohos.file.picker';
import { PostService, MediaItem } from '../services/PostService';
import { PostForm } from '../components/PostForm';

/**
 * 发布物品页面（Phase 3 集成新的 PostForm）
 * 字段：图片 + 名称 + 描述 + 分类 + 丢失时间 + 地点 + 联系方式 + 类型
 */
interface EditPostParams {
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

@Entry
@Component
struct PostPage {
  @State itemId: number = 0;
  @State isEditMode: boolean = false;
  @State title: string = '';
  @State description: string = '';
  @State category: string = '';
  @State lostTime: number = 0;
  @State location: string = '';
  @State contact: string = '';
  @State type: string = 'lost';
  @State imageUrl: string = '';
  @State mediaList: MediaItem[] = [];
  @State isSubmitting: boolean = false;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    const params = router.getParams() as EditPostParams;
    if (params && params.itemId) {
      this.isEditMode = true;
      this.itemId = params.itemId;
      this.type = params.type || 'lost';
      this.description = params.text || '';
      this.category = params.category || '';
      this.lostTime = params.lostTime || 0;
      try {
        const media = JSON.parse(params.mediaList || '[]') as MediaItem[];
        this.mediaList = media;
        this.imageUrl = media.length > 0 ? media[0].url : '';
      } catch (e) {
        this.mediaList = [];
      }
    }
  }

  private async handleImagePick(): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 3;
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);
      if (result.photoUris && result.photoUris.length > 0) {
        this.imageUrl = result.photoUris[0];
        const selected = result.photoUris.slice(0, 3);
        const nextMedia: MediaItem[] = [];
        for (const uri of selected) {
          nextMedia.push({ type: 'image', url: uri });
        }
        this.mediaList = nextMedia;
      }
    } catch (error) {
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  private async handleSubmit(): Promise<void> {
    // 验证必填字段
    if (!this.title.trim()) {
      promptAction.showToast({ message: '请输入物品名称' });
      return;
    }
    if (!this.description.trim()) {
      promptAction.showToast({ message: '请输入物品描述' });
      return;
    }
    if (!this.category) {
      promptAction.showToast({ message: '请选择物品分类' });
      return;
    }
    if (this.type === 'lost' && this.lostTime <= 0) {
      promptAction.showToast({ message: '请选择丢失时间' });
      return;
    }
    if (!this.location.trim()) {
      promptAction.showToast({ message: '请输入地点' });
      return;
    }
    if (!this.contact.trim()) {
      promptAction.showToast({ message: '请输入联系方式' });
      return;
    }

    this.isSubmitting = true;
    try {
      if (this.isEditMode && this.itemId > 0) {
        await PostService.update(
          getContext(this) as common.UIAbilityContext,
          this.itemId,
          this.type,
          this.title.trim(),
          this.description.trim(),
          this.location.trim(),
          this.category,
          this.contact.trim(),
          this.lostTime,
          this.mediaList
        );
      } else {
        await PostService.publishFull(
          getContext(this) as common.UIAbilityContext,
          this.type,
          this.title.trim(),
          this.description.trim(),
          this.location.trim(),
          this.category,
          this.contact.trim(),
          this.lostTime,
          this.mediaList
        );
      }
      promptAction.showToast({ message: this.isEditMode ? '更新成功' : '发布成功' });
      AppStorage.setOrCreate('myPostsRefresh', Date.now());
      AppStorage.setOrCreate('homeNeedRefresh', true);
      router.back();
    } catch (error) {
      const message = error instanceof Error ? error.message : '发布失败';
      promptAction.showToast({ message });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.text_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => { router.back() })

        Text(this.isEditMode ? '编辑物品' : '发布物品')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

      // PostForm 组件
      Scroll() {
        PostForm({
          title: $title,
          description: $description,
          category: $category,
          lostTime: $lostTime,
          location: $location,
          contact: $contact,
          type: $type,
          imageUrl: $imageUrl,
          mediaList: $mediaList,
          onImagePick: () => { this.handleImagePick() },
          onSubmit: () => { this.handleSubmit() }
        })
        .padding({ bottom: this.bottomHeight + 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
