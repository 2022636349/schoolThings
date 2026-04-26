export class Dispute {
  public disputeId: number = 0;
  public itemId: number = 0;
  public userId: string = '';
  public description: string = '';
  public imageUrls: string = '[]';
  public status: string = 'pending';
  public createTime: Date | null = null;
}
