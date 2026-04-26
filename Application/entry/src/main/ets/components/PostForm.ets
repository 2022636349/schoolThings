import { ITEM_CATEGORIES } from '../model/ItemCategory';
import { MediaItem } from '../services/PostService';

@Component
export struct PostForm {
  @Link title: string;
  @Link description: string;
  @Link category: string;
  @Link lostTime: number;
  @Link location: string;
  @Link contact: string;
  @Link type: string;
  @Link imageUrl: string;
  @Link mediaList: MediaItem[];
  @State isSubmitting: boolean = false;
  @State showDatePicker: boolean = false;
  @State showCategoryPicker: boolean = false;
  @State draftLostTime: number = 0;

  onSubmit: () => void = (): void => {};
  onImagePick: () => void = (): void => {};

  private getDateString(timestamp: number): string {
    if (timestamp <= 0) return '未设置';
    const d = new Date(timestamp);
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  private getTimeLabel(): string {
    return this.type === 'found' ? '捡到时间 *' : '丢失时间 *';
  }

  private getLocationPlaceholder(): string {
    return this.type === 'found' ? '请输入捡到地点' : '请输入丢失地点';
  }

  build() {
    Column({ space: 16 }) {

      Column() {
        if (this.mediaList.length === 1) {
          Image(this.mediaList[0].url)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
        } else if (this.mediaList.length === 2) {
          Row({ space: 4 }) {
            Image(this.mediaList[0].url).layoutWeight(1).height(160).objectFit(ImageFit.Cover)
            Image(this.mediaList[1].url).layoutWeight(1).height(160).objectFit(ImageFit.Cover)
          }
          .width('100%').borderRadius(8).clip(true)
        } else if (this.mediaList.length >= 3) {
          Row({ space: 4 }) {
            Image(this.mediaList[0].url).layoutWeight(1).height(180).objectFit(ImageFit.Cover)
            Column({ space: 4 }) {
              Image(this.mediaList[1].url).width('100%').height(88).objectFit(ImageFit.Cover)
              Image(this.mediaList[2].url).width('100%').height(88).objectFit(ImageFit.Cover)
            }.layoutWeight(1).height(180)
          }
          .width('100%').height(180).borderRadius(8).clip(true)
        } else {
          Column() {
            Text('+')
              .fontSize(40)
              .fontColor($r('app.color.text_caption'))
            Text('点击上传图片，最多3张')
              .fontSize(14)
              .fontColor($r('app.color.text_caption'))
              .margin({ top: 8 })
          }
          .width('100%')
          .height(200)
          .backgroundColor($r('app.color.bg_input_area'))
          .borderRadius(8)
          .border({ width: 1, color: $r('app.color.border_dashed'), style: BorderStyle.Dashed })
          .justifyContent(FlexAlign.Center)
        }
        if (this.mediaList.length > 0) {
          Text(`已选择 ${this.mediaList.length}/3 张，点击重新选择`)
            .fontSize(12).fontColor($r('app.color.text_caption')).margin({ top: 6 })
        }
      }
      .onClick(() => { this.onImagePick(); })

      Column({ space: 8 }) {
        Text('物品名称 *').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        TextInput({ placeholder: '请输入物品名称', text: this.title })
          .width('100%').height(48).fontSize(14)
          .backgroundColor($r('app.color.bg_input_area'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_caption'))
          .onChange((value: string) => { this.title = value })
      }
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('物品描述 *').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        TextArea({ placeholder: '请详细描述物品特征、颜色、品牌等', text: this.description })
          .width('100%').height(100).fontSize(14)
          .backgroundColor($r('app.color.bg_input_area'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_caption'))
          .onChange((value: string) => { this.description = value })
      }
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('物品分类 *').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Row() {
          Text(this.category || '选择分类')
            .fontSize(14)
            .fontColor(this.category ? $r('app.color.text_primary') : $r('app.color.text_caption'))
            .layoutWeight(1)
          Text('▼').fontSize(12).fontColor($r('app.color.text_caption'))
        }
        .width('100%').height(48).padding(12)
        .backgroundColor($r('app.color.bg_input_area'))
        .borderRadius(10)
        .border({ width: 1, color: $r('app.color.border') })
        .onClick(() => { this.showCategoryPicker = true })
      }
      .alignItems(HorizontalAlign.Start)

      if (this.showCategoryPicker) {
        Column({ space: 8 }) {
          ForEach(ITEM_CATEGORIES, (cat: string) => {
            Text(cat)
              .fontSize(14)
              .fontColor(this.category === cat ? '#4E8FDF' : $r('app.color.text_primary'))
              .padding(8)
              .width('100%')
              .backgroundColor(this.category === cat ? $r('app.color.bg_secondary') : Color.Transparent)
              .borderRadius(6)
              .onClick(() => {
                this.category = cat;
                this.showCategoryPicker = false;
              })
          })
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.bg_card'))
        .border({ width: 1, color: $r('app.color.border') })
        .borderRadius(8)
      }

      Column({ space: 8 }) {
        Text('发布类型 *').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Row() {
          Row({ space: 4 }) {
            Radio({ value: 'found', group: 'type' })
              .checked(this.type === 'found')
              .onChange(() => { this.type = 'found' })
            Text('失物招领').fontSize(14).fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)

          Row({ space: 4 }) {
            Radio({ value: 'lost', group: 'type' })
              .checked(this.type === 'lost')
              .onChange(() => { this.type = 'lost' })
            Text('寻物启事').fontSize(14).fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text(this.getTimeLabel()).fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Row() {
          Text(this.getDateString(this.lostTime))
            .fontSize(14)
            .fontColor(this.lostTime > 0 ? $r('app.color.text_primary') : $r('app.color.text_caption'))
            .layoutWeight(1)
          Text('📅').fontSize(14)
        }
        .width('100%').height(48).padding(12)
        .backgroundColor($r('app.color.bg_input_area'))
        .borderRadius(10)
        .border({ width: 1, color: $r('app.color.border') })
        .onClick(() => {
          this.draftLostTime = this.lostTime > 0 ? this.lostTime : Date.now();
          this.showDatePicker = true;
        })
      }
      .alignItems(HorizontalAlign.Start)

      if (this.showDatePicker) {
        Column({ space: 8 }) {
          DatePicker({
            selected: this.draftLostTime > 0 ? new Date(this.draftLostTime) : new Date()
          })
            .onChange((result: DatePickerResult) => {
              const year = result.year ?? new Date().getFullYear();
              const month = result.month ?? new Date().getMonth();
              const day = result.day ?? new Date().getDate();
              const selectedDate = new Date(year, month, day);
              const now = Date.now();
              this.draftLostTime = Math.min(selectedDate.getTime(), now);
            })
          Row({ space: 12 }) {
            Button('取消')
              .layoutWeight(1).height(40)
              .backgroundColor($r('app.color.bg_secondary')).fontColor($r('app.color.text_secondary'))
              .onClick(() => { this.showDatePicker = false; })
            Button('确定')
              .layoutWeight(1).height(40)
              .backgroundColor('#4E8FDF').fontColor('#FFFFFF')
              .onClick(() => {
                this.lostTime = Math.min(this.draftLostTime > 0 ? this.draftLostTime : Date.now(), Date.now());
                this.showDatePicker = false;
              })
          }
        }
        .padding(12)
        .backgroundColor($r('app.color.bg_card'))
        .border({ width: 1, color: $r('app.color.border') })
        .borderRadius(8)
      }

      Column({ space: 8 }) {
        Text('地点 *').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        TextInput({ placeholder: this.getLocationPlaceholder(), text: this.location })
          .width('100%').height(48).fontSize(14)
          .backgroundColor($r('app.color.bg_input_area'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_caption'))
          .onChange((value: string) => { this.location = value })
      }
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('联系方式 *').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        TextInput({ placeholder: '请输入手机号或微信号', text: this.contact })
          .width('100%').height(48).fontSize(14)
          .backgroundColor($r('app.color.bg_input_area'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_caption'))
          .onChange((value: string) => { this.contact = value })
      }
      .alignItems(HorizontalAlign.Start)

      Button(this.isSubmitting ? '提交中...' : '发布')
        .width('100%').height(50)
        .fontSize(16).fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(this.isSubmitting ? '#A0BFDF' : '#4E8FDF')
        .borderRadius(25)
        .enabled(!this.isSubmitting)
        .onClick(() => { this.onSubmit(); })
    }
    .width('100%')
    .padding(16)
  }
}
