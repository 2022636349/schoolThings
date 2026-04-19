/**
 * 首页公告轮播（后端管理）
 */
export class Announcement {
  public announcementId: number = 0;
  public title: string = '';
  public imageUrl: string | null = null;
  public linkUrl: string | null = null;
  public orderIndex: number = 0;
  public enabled: number = 1;        // 0/1
  public createTime: Date | null = null;
}
