export class ItemInfo {
  public itemId: number = 0;
  public type: string = 'lost';            
  public text: string = '';
  public publishTime: Date = new Date();
  public publishId: string = '';
  public resource: string = '[]';          

  public category: string = '其他';
  public likeCount: number = 0;
  public status: string = 'active';        
  public claimedBy: string | null = null;
  public claimTime: Date | null = null;
  public lostTime: Date | null = null;
  public warningStartTime: Date | null = null;
}
