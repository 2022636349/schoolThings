/**
 * 认领/归还申请（前端纯数据模型）
 * status: pending | approved | completed | rejected
 */
export class ClaimRequest {
  public requestId: number = 0;
  public itemId: number = 0;
  public itemTitle: string = '';
  public itemStatus: string = 'pending';
  public applicantId: string = '';
  public ownerId: string = '';
  public description: string = '';
  public applicantConfirmed: number = 0;  // 0/1
  public ownerConfirmed: number = 0;      // 0/1
  public status: string = 'pending';
  public sessionId: string = '';
  public createTime: Date | null = null;
}
