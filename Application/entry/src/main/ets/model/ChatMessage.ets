export class ChatMessage {
  public msgId: number = 0;
  public sessionId: string = '';
  public senderId: string = '';
  public content: string = '';
  public sendTime: Date | null = null;
  public messageType: string = 'text';       
  public imageUrl: string | null = null;
}
