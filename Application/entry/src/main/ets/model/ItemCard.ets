import { cloudDatabase } from '@kit.CloudFoundationKit';

export class ItemInfo extends cloudDatabase.DatabaseObject {
  // 原有字段
  public itemId: number;
  public type: string;            // 'lost' | 'find' | 'claimed'（兼容旧数据；claimed 为遗留值）
  public text: string;
  public publishTime: Date;
  public publishId: string;
  public resource: string;

  // 新增字段（schemaVersion 15）
  public category: string;        // 物品分类：数码/证件/卡类/衣物/钥匙/书籍/其他
  public likeCount: number;       // 点赞累计数
  public status: string;          // 生命周期：active/pending/claimed/warning/offline
  public claimedBy: string | null;// 认领人学号
  public claimTime: Date | null;  // 认领完成时间
  public lostTime: Date | null;   // 丢失/拾取时间
  public warningStartTime: Date | null; // 进入处理预警时间

  public naturalbase_ClassName(): string {
    return 'ItemInfo';
  }

  constructor() {
    super();
    this.itemId = 1;
    this.type = 'lost';
    this.text = '';
    this.publishTime = new Date();
    this.publishId = '';
    this.resource = '[]';

    this.category = '其他';
    this.likeCount = 0;
    this.status = 'active';
    this.claimedBy = null;
    this.claimTime = null;
    this.lostTime = null;
    this.warningStartTime = null;
  }
}
