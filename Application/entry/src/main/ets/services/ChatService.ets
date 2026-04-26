import { ApiClient } from '../common/ApiClient';
import { ChatSession } from '../model/ChatSession';
import { ChatMessage } from '../model/ChatMessage';
import { ItemInfo } from '../model/ItemCard';

export interface UnreadSummary {
  count: number;
  latest: string;
}

interface SessionRaw {
  sessionId: string;
  itemId: number;
  initiatorId: string;
  ownerId: string;
  lastMessage: string | null;
  lastTime: number | null;   
  initiatorConfirmed: number;
  ownerConfirmed: number;
  peerName: string | null;
  peerAvatar: string | null;
  itemTitle: string | null;
  itemStatus: string | null;
  itemType: string | null;
}

interface MessageRaw {
  msgId: number;
  sessionId: string;
  senderId: string;
  content: string;
  sendTime: number;         
  messageType: string;      
  imageUrl: string | null;
}

interface ConfirmResp {
  bothConfirmed: boolean;
}

interface ItemCardRawMin {
  itemId: number;
  type: string;
  text: string;
  publishTime: number;
  publishId: string;
  mediaList: Array<ItemCardMedia> | null;
  category: string | null;
  likeCount: number;
  status: string;
  claimedBy: string | null;
  lostTime: number;
}

interface ItemCardMedia {
  type: string;
  url: string;
}

function toSession(r: SessionRaw): ChatSession {
  const s = new ChatSession();
  s.sessionId = r.sessionId;
  s.itemId = r.itemId;
  s.initiatorId = r.initiatorId;
  s.ownerId = r.ownerId;
  s.lastMessage = r.lastMessage;
  s.lastTime = r.lastTime ? new Date(r.lastTime) : null;
  s.initiatorConfirmed = r.initiatorConfirmed || 0;
  s.ownerConfirmed = r.ownerConfirmed || 0;
  s.peerName = r.peerName || '';
  s.peerAvatar = r.peerAvatar || '';
  s.itemTitle = r.itemTitle || '';
  s.itemStatus = r.itemStatus || '';
  s.itemType = r.itemType || '';
  return s;
}

function toMessage(r: MessageRaw): ChatMessage {
  const m = new ChatMessage();
  m.msgId = r.msgId;
  m.sessionId = r.sessionId;
  m.senderId = r.senderId;
  m.content = r.content || '';
  m.sendTime = r.sendTime ? new Date(r.sendTime) : null;
  m.messageType = r.messageType || 'text';
  m.imageUrl = r.imageUrl;
  return m;
}

interface GetOrCreateSessionBody {
  itemId: number;
  ownerId: number;
}

interface SendMessageBody {
  content: string;
  type: string;
  imageUrl?: string;
}

interface ChatItemCardPayload {
  itemId: number;
  title: string;
  type: string;
  publisherName: string;
}

interface MessageListQuery extends Record<string, string | number | boolean | null | undefined> {
  limit: number;
  afterMsgId?: number;
}

interface SessionListQuery extends Record<string, string | number | boolean | null | undefined> {
  _t: number;
}

interface UnreadBody {
  lastReadMsgIds: Record<string, number>;
  hidden?: Record<string, number>;
}

export class ChatService {

  static async getOrCreateSession(
    itemId: number,
    _initiatorId: string,
    ownerId: string
  ): Promise<ChatSession> {
    const body: GetOrCreateSessionBody = { itemId: itemId, ownerId: Number(ownerId) };
    const r = await ApiClient.post<SessionRaw>('/chat/sessions', body);
    return toSession(r);
  }

  static async getSessionsForUser(_userId: string): Promise<ChatSession[]> {
    try {
      const query: SessionListQuery = { _t: Date.now() };
      const list = await ApiClient.get<SessionRaw[]>('/chat/sessions', query);
      if (!list) return [];
      const out: ChatSession[] = [];
      for (const r of list) out.push(toSession(r));
      return out;
    } catch (e) {
      console.error('[ChatService] getSessionsForUser failed:', e);
      return [];
    }
  }

  static async getSession(sessionId: string): Promise<ChatSession | null> {
    try {
      const r = await ApiClient.get<SessionRaw>(`/chat/sessions/${sessionId}`);
      return r ? toSession(r) : null;
    } catch (e) {
      console.error('[ChatService] getSession failed:', e);
      return null;
    }
  }

  static async sendMessage(sessionId: string, _senderId: string, content: string): Promise<void> {
    const body: SendMessageBody = { content: content, type: 'text' };
    await ApiClient.post<Object>(`/chat/sessions/${sessionId}/messages`, body);
  }

  static async sendImageMessage(sessionId: string, _senderId: string, imageUrl: string): Promise<void> {
    const body: SendMessageBody = { content: '', type: 'image', imageUrl: imageUrl };
    await ApiClient.post<Object>(`/chat/sessions/${sessionId}/messages`, body);
  }

  static async sendItemCardMessage(sessionId: string, payload: ChatItemCardPayload): Promise<void> {
    const body: SendMessageBody = {
      content: JSON.stringify(payload),
      type: 'item-card'
    };
    await ApiClient.post<Object>(`/chat/sessions/${sessionId}/messages`, body);
  }

  static async sendSystemMessage(sessionId: string, content: string): Promise<void> {
    const body: SendMessageBody = { content: content, type: 'system' };
    await ApiClient.post<Object>(`/chat/sessions/${sessionId}/messages`, body);
  }

  static async getMessages(sessionId: string, afterMsgId: number = 0): Promise<ChatMessage[]> {
    try {
      const params: MessageListQuery = afterMsgId > 0 ? { limit: 50, afterMsgId: afterMsgId } : { limit: 50 };
      const list = await ApiClient.get<MessageRaw[]>(`/chat/sessions/${sessionId}/messages`, params);
      if (!list) return [];
      const out: ChatMessage[] = [];
      for (const r of list) out.push(toMessage(r));
      return out;
    } catch (e) {
      console.error('[ChatService] getMessages failed:', e);
      return [];
    }
  }

  static async confirmClaimed(sessionId: string, _userId: string): Promise<boolean> {
    const r = await ApiClient.post<ConfirmResp>(`/chat/sessions/${sessionId}/confirm-claim`);
    return !!(r && r.bothConfirmed);
  }

  static async getMaxMsgId(sessionId: string): Promise<number> {
    try {
      const n = await ApiClient.get<number>(`/chat/sessions/${sessionId}/max-msg-id`);
      return n || 0;
    } catch (e) {
      console.error('[ChatService] getMaxMsgId failed:', e);
      return 0;
    }
  }

  static async deleteSession(sessionId: string): Promise<void> {
    await ApiClient.del<Object>(`/chat/sessions/${sessionId}`);
  }

  static async getItemById(itemId: number): Promise<ItemInfo | null> {
    try {
      const raw = await ApiClient.get<ItemCardRawMin>(`/items/${itemId}`);
      if (!raw) return null;
      const info = new ItemInfo();
      info.itemId = raw.itemId;
      info.type = raw.type;
      info.text = raw.text || '';
      info.publishTime = raw.publishTime ? new Date(raw.publishTime) : new Date();
      info.publishId = raw.publishId || '';
      info.resource = JSON.stringify(raw.mediaList || []);
      info.category = raw.category || '其他';
      info.likeCount = raw.likeCount || 0;
      info.status = raw.status || 'active';
      info.claimedBy = raw.claimedBy;
      info.lostTime = raw.lostTime ? new Date(raw.lostTime) : null;
      return info;
    } catch (e) {
      console.error('[ChatService] getItemById failed:', e);
      return null;
    }
  }

  static async checkUnreadSessions(userId: string, _lastReadTime: number): Promise<string> {
    const summary = await ChatService.getUnreadSummary(userId, {}, {});
    return summary.latest || '';
  }

  static async getUnreadSummary(
    _userId: string,
    lastReadMsgIdMap: Record<string, number>,
    hiddenMap: Record<string, number>
  ): Promise<UnreadSummary> {
    try {
      const emptyLastRead: Record<string, number> = {};
      const emptyHidden: Record<string, number> = {};
      const body: UnreadBody = {
        lastReadMsgIds: lastReadMsgIdMap || emptyLastRead,
        hidden: hiddenMap || emptyHidden
      };
      const r = await ApiClient.post<UnreadSummary>('/chat/unread/summary', body);
      if (!r) return { count: 0, latest: '' };
      return { count: r.count || 0, latest: r.latest || '' };
    } catch (e) {
      console.error('[ChatService] getUnreadSummary failed:', e);
      return { count: 0, latest: '' };
    }
  }

  static async getPerSessionUnreadCounts(
    _userId: string,
    lastReadMsgIdMap: Record<string, number>
  ): Promise<Record<string, number>> {
    try {
      const emptyLastRead: Record<string, number> = {};
      const body: UnreadBody = { lastReadMsgIds: lastReadMsgIdMap || emptyLastRead };
      const r = await ApiClient.post<Record<string, number>>('/chat/unread/counts', body);
      const emptyUnreadCounts: Record<string, number> = {};
      return r || emptyUnreadCounts;
    } catch (e) {
      console.error('[ChatService] getPerSessionUnreadCounts failed:', e);
      return {};
    }
  }

  static async markItemClaimed(_session: ChatSession): Promise<void> {
    return;
  }
}
