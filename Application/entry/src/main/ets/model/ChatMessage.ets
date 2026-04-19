// 消息（与后端 ChatMessageVO 对齐的前端纯数据模型）
export class ChatMessage {
  public msgId: number = 0;
  public sessionId: string = '';
  public senderId: string = '';
  public content: string = '';
  public sendTime: Date | null = null;
  public messageType: string = 'text';       // text / image / item-card / system
  public imageUrl: string | null = null;
}
