import { cloudDatabase } from '@kit.CloudFoundationKit';

/**
 * 首页公告轮播
 * 由管理员在 AGC 控制台手动录入
 */
export class Announcement extends cloudDatabase.DatabaseObject {
  public announcementId: number;
  public title: string;
  public imageUrl: string | null;
  public linkUrl: string | null;
  public orderIndex: number;
  public enabled: number;            // 0/1
  public createTime: Date | null;

  public naturalbase_ClassName(): string {
    return 'Announcement';
  }

  constructor() {
    super();
    this.announcementId = 0;
    this.title = '';
    this.imageUrl = null;
    this.linkUrl = null;
    this.orderIndex = 0;
    this.enabled = 1;
    this.createTime = null;
  }
}
