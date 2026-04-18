/**
 * 大厅页面卡片数据模型
 * 单独文件以避免 HallPage <-> HallItemCard 循环依赖
 * 注：所有字段使用原始类型（无 union），以兼容 @Prop 深拷贝
 */
export class HallItemData {
  itemId: number = 0;
  type: string = '';
  text: string = '';
  publishTime: string = '';
  publishId: string = '';
  publisherName: string = '';
  publisherAvatar: string = '';
  mediaList: string = '';
  category: string = '';
  likeCount: number = 0;
  status: string = '';
  claimedBy: string = '';
  lostTime: number = 0;
}
