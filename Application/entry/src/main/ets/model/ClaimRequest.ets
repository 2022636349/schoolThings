import { cloudDatabase } from '@kit.CloudFoundationKit';

/**
 * 认领/归还申请
 * 双方各自确认后完成。
 * status: pending | approved | completed | rejected
 */
export class ClaimRequest extends cloudDatabase.DatabaseObject {
  public requestId: number;
  public itemId: number;
  public applicantId: string;
  public ownerId: string;
  public description: string;
  public applicantConfirmed: number;  // 0/1
  public ownerConfirmed: number;      // 0/1
  public status: string;
  public sessionId: string;
  public createTime: Date | null;

  public naturalbase_ClassName(): string {
    return 'ClaimRequest';
  }

  constructor() {
    super();
    this.requestId = 0;
    this.itemId = 0;
    this.applicantId = '';
    this.ownerId = '';
    this.description = '';
    this.applicantConfirmed = 0;
    this.ownerConfirmed = 0;
    this.status = 'pending';
    this.sessionId = '';
    this.createTime = null;
  }
}
