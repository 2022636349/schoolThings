import { ITEM_CATEGORIES } from '../model/ItemCategory';
import { MediaItem } from '../services/PostService';

/**
 * 发布物品表单组件
 * 字段：图片 + 名称 + 描述 + 分类 + 丢失时间 + 地点 + 联系方式 + 类型(lost/found)
 */
@Component
export struct PostForm {
  @Link title: string;
  @Link description: string;
  @Link category: string;
  @Link lostTime: number;        // 时间戳（ms），0 表示未设置
  @Link location: string;
  @Link contact: string;
  @Link type: string;            // 'lost' 或 'found'
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

  build() {
    Column({ space: 16 }) {
      // 图片上传区域
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
              .fontColor('#999')
            Text('点击上传图片，最多3张')
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 8 })
          }
          .width('100%')
          .height(200)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed })
          .justifyContent(FlexAlign.Center)
        }
        if (this.mediaList.length > 0) {
          Text(`已选择 ${this.mediaList.length}/3 张，点击重新选择`)
            .fontSize(12).fontColor('#999').margin({ top: 6 })
        }
      }
      .onClick(() => { this.onImagePick(); })

      // 标题输入
      Column({ space: 8 }) {
        Text('物品名称 *').fontSize(14).fontWeight(FontWeight.Bold)
        TextInput({ placeholder: '请输入物品名称', text: this.title })
          .width('100%').height(48).fontSize(14)
          .onChange((value: string) => { this.title = value })
      }
      .alignItems(HorizontalAlign.Start)

      // 描述输入
      Column({ space: 8 }) {
        Text('物品描述 *').fontSize(14).fontWeight(FontWeight.Bold)
        TextArea({ placeholder: '请详细描述物品特征、颜色、品牌等', text: this.description })
          .width('100%').height(100).fontSize(14)
          .onChange((value: string) => { this.description = value })
      }
      .alignItems(HorizontalAlign.Start)

      // 分类选择
      Column({ space: 8 }) {
        Text('物品分类 *').fontSize(14).fontWeight(FontWeight.Bold)
        Row() {
          Text(this.category || '选择分类').fontSize(14).fontColor(this.category ? '#000' : '#999').layoutWeight(1)
          Text('▼').fontSize(12).fontColor('#999')
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
            Text(cat).fontSize(14).padding(8)
              .width('100%')
              .onClick(() => {
                this.category = cat;
                this.showCategoryPicker = false;
              })
          })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
      }

      // 类型选择
      Column({ space: 8 }) {
        Text('发布类型 *').fontSize(14).fontWeight(FontWeight.Bold)
        Row() {
          Row({ space: 4 }) {
            Radio({ value: 'lost', group: 'type' })
              .checked(this.type === 'lost')
              .onChange(() => { this.type = 'lost' })
            Text('失物招领').fontSize(14)
          }
          .layoutWeight(1)

          Row({ space: 4 }) {
            Radio({ value: 'found', group: 'type' })
              .checked(this.type === 'found')
              .onChange(() => { this.type = 'found' })
            Text('寻物启事').fontSize(14)
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      // 丢失时间选择（仅失物招领时显示）
      if (this.type === 'lost') {
        Column({ space: 8 }) {
          Text('丢失时间 *').fontSize(14).fontWeight(FontWeight.Bold)
          Row() {
            Text(this.getDateString(this.lostTime)).fontSize(14).fontColor(this.lostTime > 0 ? '#000' : '#999').layoutWeight(1)
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
                .backgroundColor('#F5F5F5').fontColor('#666')
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
          .padding(12).backgroundColor('#F5F5F5').borderRadius(8)
        }
      }

      // 地点输入
      Column({ space: 8 }) {
        Text('地点 *').fontSize(14).fontWeight(FontWeight.Bold)
        TextInput({ placeholder: '请输入丢失或发现地点', text: this.location })
          .width('100%').height(48).fontSize(14)
          .onChange((value: string) => { this.location = value })
      }
      .alignItems(HorizontalAlign.Start)

      // 联系方式输入
      Column({ space: 8 }) {
        Text('联系方式 *').fontSize(14).fontWeight(FontWeight.Bold)
        TextInput({ placeholder: '请输入手机号或微信号', text: this.contact })
          .width('100%').height(48).fontSize(14)
          .onChange((value: string) => { this.contact = value })
      }
      .alignItems(HorizontalAlign.Start)

      // 提交按钮
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
