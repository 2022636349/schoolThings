export class Dispute {
  public disputeId: number = 0;
  public itemId: number = 0;
  public targetTitle: string = '';
  public userId: string = '';
  public description: string = '';
  public imageUrls: string = '[]';
  public status: string = 'pending';
  public resolution: string = '';
  public createTime: Date | null = null;
  public updateTime: Date | null = null;
}
