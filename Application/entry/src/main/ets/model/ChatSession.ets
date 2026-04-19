// 会话（与后端 ChatSessionVO 对齐的前端纯数据模型）
export class ChatSession {
  public sessionId: string = '';
  public itemId: number = 0;
  public initiatorId: string = '';
  public ownerId: string = '';
  public lastMessage: string | null = null;
  public lastTime: Date | null = null;
  public initiatorConfirmed: number = 0;
  public ownerConfirmed: number = 0;

  // 可选的展示字段（后端会带回来以便列表展示对端信息）
  public peerName: string = '';
  public peerAvatar: string = '';
  public itemTitle: string = '';
  public itemStatus: string = '';
  public itemType: string = '';
}
