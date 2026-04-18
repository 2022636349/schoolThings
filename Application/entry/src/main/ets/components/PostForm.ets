import { ITEM_CATEGORIES } from '../model/ItemCategory';

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
  @State isSubmitting: boolean = false;
  @State showDatePicker: boolean = false;
  @State showCategoryPicker: boolean = false;

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
        if (this.imageUrl) {
          Image(this.imageUrl)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
        } else {
          Column() {
            Text('+')
              .fontSize(40)
              .fontColor('#999')
            Text('点击上传图片')
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

      // 丢失时间选择（仅 type='lost' 时显示）
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
          .onClick(() => { this.showDatePicker = true })
        }
        .alignItems(HorizontalAlign.Start)

        if (this.showDatePicker) {
          DatePicker({
            selected: this.lostTime > 0 ? new Date(this.lostTime) : new Date()
          })
            .onChange((result: DatePickerResult) => {
              const year = result.year ?? new Date().getFullYear();
              const month = result.month ?? new Date().getMonth();
              const day = result.day ?? new Date().getDate();
              const selectedDate = new Date(year, month, day);
              this.lostTime = selectedDate.getTime();
              this.showDatePicker = false;
            })
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

      // 类型选择
      Column({ space: 8 }) {
        Text('类型 *').fontSize(14).fontWeight(FontWeight.Bold)
        Row() {
          Row({ space: 4 }) {
            Radio({ value: 'lost', group: 'type' })
              .checked(this.type === 'lost')
              .onChange(() => { this.type = 'lost' })
            Text('丢失').fontSize(14)
          }
          .layoutWeight(1)

          Row({ space: 4 }) {
            Radio({ value: 'found', group: 'type' })
              .checked(this.type === 'found')
              .onChange(() => { this.type = 'found' })
            Text('招领').fontSize(14)
          }
          .layoutWeight(1)
        }
        .width('100%')
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
