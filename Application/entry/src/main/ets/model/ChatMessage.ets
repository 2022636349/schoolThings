import { cloudDatabase } from '@kit.CloudFoundationKit';

export class ChatMessage extends cloudDatabase.DatabaseObject {
  public msgId: number;
  public sessionId: string;
  public senderId: string;
  public content: string;
  public sendTime: Date | null;
  public messageType: string;       // 'text' | 'image'
  public imageUrl: string | null;   // 当 messageType='image' 时有效

  public naturalbase_ClassName(): string {
    return 'ChatMessage';
  }

  constructor() {
    super();
    this.msgId = 0;
    this.sessionId = '';
    this.senderId = '';
    this.content = '';
    this.sendTime = null;
    this.messageType = 'text';
    this.imageUrl = null;
  }
}
