export class ChatSession {
  public sessionId: string = '';
  public itemId: number = 0;
  public initiatorId: string = '';
  public ownerId: string = '';
  public lastMessage: string | null = null;
  public lastTime: Date | null = null;
  public initiatorConfirmed: number = 0;
  public ownerConfirmed: number = 0;

  public peerName: string = '';
  public peerAvatar: string = '';
  public itemTitle: string = '';
  public itemStatus: string = '';
  public itemType: string = '';
}
