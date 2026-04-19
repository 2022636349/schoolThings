/**
 * 冒领异议记录（前端纯数据模型）
 * imageUrls 是 JSON 字符串数组，例如 '["url1","url2"]'
 * status: pending | handled
 */
export class Dispute {
  public disputeId: number = 0;
  public itemId: number = 0;
  public userId: string = '';
  public description: string = '';
  public imageUrls: string = '[]';
  public status: string = 'pending';
  public createTime: Date | null = null;
}
