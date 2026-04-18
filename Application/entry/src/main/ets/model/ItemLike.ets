import { cloudDatabase } from '@kit.CloudFoundationKit';

/**
 * 物品点赞记录（防重复点赞）
 * likeId 使用 `${itemId}_${userId}` 保证唯一
 */
export class ItemLike extends cloudDatabase.DatabaseObject {
  public likeId: string;
  public itemId: number;
  public userId: string;
  public createTime: Date | null;

  public naturalbase_ClassName(): string {
    return 'ItemLike';
  }

  constructor() {
    super();
    this.likeId = '';
    this.itemId = 0;
    this.userId = '';
    this.createTime = null;
  }
}
