// 物品点赞记录（前端纯数据模型，后端以联合唯一索引保障唯一性）
export class ItemLike {
  public likeId: string = '';
  public itemId: number = 0;
  public userId: string = '';
  public createTime: Date | null = null;
}
