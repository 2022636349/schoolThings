import { cloudDatabase } from '@kit.CloudFoundationKit';

/**
 * 冒领异议记录
 * imageUrls 是 JSON 字符串数组，例如 '["url1","url2"]'
 * status: pending | handled
 */
export class Dispute extends cloudDatabase.DatabaseObject {
  public disputeId: number;
  public itemId: number;
  public userId: string;
  public description: string;
  public imageUrls: string;
  public status: string;
  public createTime: Date | null;

  public naturalbase_ClassName(): string {
    return 'Dispute';
  }

  constructor() {
    super();
    this.disputeId = 0;
    this.itemId = 0;
    this.userId = '';
    this.description = '';
    this.imageUrls = '[]';
    this.status = 'pending';
    this.createTime = null;
  }
}
