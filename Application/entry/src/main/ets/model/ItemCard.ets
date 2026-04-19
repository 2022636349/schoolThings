// 物品基础字段（与后端 Item 对齐的前端纯数据模型）
// 注意：mediaList 现在是单独的结构，backend 会通过 mediaList 字段一并返回；
// 旧 resource 字段保留以便兼容老代码片段。

export class ItemInfo {
  public itemId: number = 0;
  public type: string = 'lost';            // 'lost' | 'found' | 'claimed'
  public text: string = '';
  public publishTime: Date = new Date();
  public publishId: string = '';
  public resource: string = '[]';          // 兼容老代码：JSON.stringify(mediaList)

  public category: string = '其他';
  public likeCount: number = 0;
  public status: string = 'active';        // active / pending / claimed / warning / offline
  public claimedBy: string | null = null;
  public claimTime: Date | null = null;
  public lostTime: Date | null = null;
  public warningStartTime: Date | null = null;
}
