import { router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import picker from '@ohos.file.picker';
import { PostService, MediaItem } from '../services/PostService';
import { PostForm } from '../components/PostForm';
import { MeteorOverlay } from '../components/MeteorOverlay';

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
export struct PostPage {
  @Prop paramsJson: string = '';
  @State itemId: number = 0;
  @State isEditMode: boolean = false;
  @State title: string = '';
  @State description: string = '';
  @State category: string = '';
  @State lostTime: number = 0;
  @State location: string = '';
  @State contact: string = '';
  @State type: string = 'found';
  @State imageUrl: string = '';
  @State mediaList: MediaItem[] = [];
  @State isSubmitting: boolean = false;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  private closeSelf(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletRightType', 'none');
      AppStorage.setOrCreate('tabletRightParams', '');
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
    } else {
      router.back();
    }
  }

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    let params: EditPostParams | null = null;
    if (this.paramsJson && this.paramsJson.length > 0) {
      try {
        params = JSON.parse(this.paramsJson) as EditPostParams;
      } catch (e) {
        params = null;
      }
    } else {
      params = router.getParams() as EditPostParams;
    }
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
      this.getUIContext().getPromptAction().showToast({ message: '选择图片失败' });
    }
  }

  private async handleSubmit(): Promise<void> {

    if (!this.title.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入物品名称' });
      return;
    }
    if (!this.description.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入物品描述' });
      return;
    }
    if (!this.category) {
      this.getUIContext().getPromptAction().showToast({ message: '请选择物品分类' });
      return;
    }
    if ((this.type === 'lost' || this.type === 'found') && this.lostTime <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.type === 'found' ? '请选择捡到时间' : '请选择丢失时间' });
      return;
    }
    if (!this.location.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入地点' });
      return;
    }
    if (!this.contact.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入联系方式' });
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
      this.getUIContext().getPromptAction().showToast({ message: this.isEditMode ? '更新成功' : '发布成功' });
      AppStorage.setOrCreate('myPostsRefresh', Date.now());
      AppStorage.setOrCreate('homeNeedRefresh', true);
      this.closeSelf();
    } catch (error) {
      const message = error instanceof Error ? error.message : '发布失败';
      this.getUIContext().getPromptAction().showToast({ message });
    } finally {
      this.isSubmitting = false;
    }
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
        .onClick(() => { this.closeSelf() })

        Text(this.isEditMode ? '编辑物品' : '发布物品')
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: this.topHeight + 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_card'))

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

      MeteorOverlay({ suppressInTablet: true })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
