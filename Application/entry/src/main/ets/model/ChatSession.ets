import { cloudDatabase } from '@kit.CloudFoundationKit';

export class ChatSession extends cloudDatabase.DatabaseObject {
  public sessionId: string;
  public itemId: number;
  public initiatorId: string;
  public ownerId: string;
  public lastMessage: string | null;
  public lastTime: Date | null;
  public initiatorConfirmed: number;
  public ownerConfirmed: number;

  public naturalbase_ClassName(): string {
    return 'ChatSession';
  }

  constructor() {
    super();
    this.sessionId = '';
    this.itemId = 0;
    this.initiatorId = '';
    this.ownerId = '';
    this.lastMessage = null;
    this.lastTime = null;
    this.initiatorConfirmed = 0;
    this.ownerConfirmed = 0;
  }
}
