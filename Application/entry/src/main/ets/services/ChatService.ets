import { cloudDatabase } from '@kit.CloudFoundationKit';
import { ChatSession } from '../model/ChatSession';
import { ChatMessage } from '../model/ChatMessage';
import { ItemInfo } from '../model/ItemCard';
import { UserInfo } from '../model/User';

const ZONE_NAME = 'User';

export interface UnreadSummary {
  count: number;
  latest: string;
}

export class ChatService {
  /**
   * 获取或创建聊天会话，sessionId = `${itemId}_${initiatorId}`
   */
  static async getOrCreateSession(
    itemId: number,
    initiatorId: string,
    ownerId: string
  ): Promise<ChatSession> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const sessionId = `${itemId}_${initiatorId}`;
    const query = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('sessionId', sessionId);
    const results = (await db.query(query)) as ChatSession[];
    if (results && results.length > 0) {
      return results[0];
    }
    const session = new ChatSession();
    session.sessionId = sessionId;
    session.itemId = itemId;
    session.initiatorId = initiatorId;
    session.ownerId = ownerId;
    session.lastMessage = null;
    session.lastTime = null;
    session.initiatorConfirmed = 0;
    session.ownerConfirmed = 0;
    await db.upsert(session);
    return session;
  }

  /**
   * 获取用户参与的所有会话（作为发起者或物品主人），按最后消息时间降序
   */
  static async getSessionsForUser(userId: string): Promise<ChatSession[]> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const q1 = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('initiatorId', userId);
    const q2 = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('ownerId', userId);
    const r1 = (await db.query(q1)) as ChatSession[];
    const r2 = (await db.query(q2)) as ChatSession[];
    const map: Record<string, ChatSession> = {};
    for (const s of r1) {
      map[s.sessionId] = s;
    }
    for (const s of r2) {
      map[s.sessionId] = s;
    }
    const all = Object.values(map) as ChatSession[];
    all.sort((a: ChatSession, b: ChatSession) => {
      const ta = a.lastTime ? a.lastTime.getTime() : 0;
      const tb = b.lastTime ? b.lastTime.getTime() : 0;
      return tb - ta;
    });
    return all;
  }

  /**
   * 发送消息，同步更新会话的 lastMessage / lastTime
   */
  static async sendMessage(
    sessionId: string,
    senderId: string,
    content: string
  ): Promise<void> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const maxQuery = new cloudDatabase.DatabaseQuery(ChatMessage).orderByDesc('msgId').limit(1);
    const maxResults = (await db.query(maxQuery)) as ChatMessage[];
    const newMsgId = (maxResults && maxResults.length > 0) ? maxResults[0].msgId + 1 : 1;

    const msg = new ChatMessage();
    msg.msgId = newMsgId;
    msg.sessionId = sessionId;
    msg.senderId = senderId;
    msg.content = content;
    msg.sendTime = new Date();
    await db.upsert(msg);

    const sq = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('sessionId', sessionId);
    const sessions = (await db.query(sq)) as ChatSession[];
    if (sessions && sessions.length > 0) {
      const session = sessions[0];
      session.lastMessage = content.length > 30 ? content.substring(0, 30) + '...' : content;
      session.lastTime = new Date();
      await db.upsert(session);
    }
  }

  /**
   * 获取会话消息（最多 50 条，按时间从旧到新）
   */
  static async getMessages(sessionId: string): Promise<ChatMessage[]> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const query = new cloudDatabase.DatabaseQuery(ChatMessage)
      .equalTo('sessionId', sessionId)
      .orderByDesc('msgId')
      .limit(50);
    const results = (await db.query(query)) as ChatMessage[];
    if (!results || results.length === 0) return [];
    return results.reverse();
  }

  /**
   * 通过 sessionId 获取会话
   */
  static async getSession(sessionId: string): Promise<ChatSession | null> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const sq = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('sessionId', sessionId);
    const sessions = (await db.query(sq)) as ChatSession[];
    return (sessions && sessions.length > 0) ? sessions[0] : null;
  }

  /**
   * 确认认领，返回是否双方均已确认
   */
  static async confirmClaimed(sessionId: string, userId: string): Promise<boolean> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const sq = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('sessionId', sessionId);
    const sessions = (await db.query(sq)) as ChatSession[];
    if (!sessions || sessions.length === 0) return false;
    const session = sessions[0];
    if (userId === session.initiatorId) {
      session.initiatorConfirmed = 1;
    } else if (userId === session.ownerId) {
      session.ownerConfirmed = 1;
    }
    await db.upsert(session);
    return session.initiatorConfirmed === 1 && session.ownerConfirmed === 1;
  }

  /**
   * 通过 itemId 获取物品信息
   */
  static async getItemById(itemId: number): Promise<ItemInfo | null> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const q = new cloudDatabase.DatabaseQuery(ItemInfo).equalTo('itemId', itemId);
    const items = (await db.query(q)) as ItemInfo[];
    return (items && items.length > 0) ? items[0] : null;
  }

  /**
   * 检查是否有未读消息（他人发送且在 lastReadTime 之后）
   * 返回最新一条未读消息内容，无未读返回空字符串
   */
  static async checkUnreadSessions(userId: string, lastReadTime: number): Promise<string> {
    try {
      const sessions = await ChatService.getSessionsForUser(userId);
      const db = cloudDatabase.zone(ZONE_NAME);
      for (const session of sessions) {
        if (session.lastTime && session.lastTime.getTime() > lastReadTime) {
          const msgQuery = new cloudDatabase.DatabaseQuery(ChatMessage)
            .equalTo('sessionId', session.sessionId)
            .orderByDesc('msgId')
            .limit(1);
          const msgs = (await db.query(msgQuery)) as ChatMessage[];
          if (msgs && msgs.length > 0 && msgs[0].senderId !== userId) {
            return msgs[0].content;
          }
        }
      }
      return '';
    } catch (error) {
      console.error('[ChatService] checkUnread failed:', error);
      return '';
    }
  }

  /**
   * 获取未读汇总（总数 + 最新一条未读消息内容），用于卡片/通知
   * lastReadMsgIdMap: sessionId → 用户最后读到的 msgId（改用 msgId 避免时钟差问题）
   * hiddenMap: sessionId → 单方面删除时间戳；删除后 session.lastTime <= hiddenTime 时排除
   */
  static async getUnreadSummary(
    userId: string,
    lastReadMsgIdMap: Record<string, number>,
    hiddenMap: Record<string, number>
  ): Promise<UnreadSummary> {
    let totalCount = 0;
    let latestContent = '';
    let latestMsgId = 0;
    try {
      const sessions = await ChatService.getSessionsForUser(userId);
      const db = cloudDatabase.zone(ZONE_NAME);
      const tasks: Promise<void>[] = [];
      for (const session of sessions) {
        const sid = session.sessionId;
        // 被单方面删除且之后无新消息 → 跳过
        const hideTime = hiddenMap[sid] || 0;
        const lt = session.lastTime ? session.lastTime.getTime() : 0;
        if (hideTime > 0 && lt <= hideTime) continue;

        const lastReadMsgId = lastReadMsgIdMap[sid] || 0;
        // 不用 greaterThan（SDK 兼容性不确定），在客户端过滤
        const q = new cloudDatabase.DatabaseQuery(ChatMessage)
          .equalTo('sessionId', sid)
          .orderByDesc('msgId')
          .limit(50);
        tasks.push(
          (db.query(q) as Promise<ChatMessage[]>).then((msgs: ChatMessage[]) => {
            for (const m of msgs) {
              if (m.senderId !== userId && m.msgId > lastReadMsgId) {
                totalCount++;
                if (m.msgId > latestMsgId) {
                  latestMsgId = m.msgId;
                  latestContent = m.content;
                }
              }
            }
          }).catch(() => { /* ignore */ })
        );
      }
      await Promise.all(tasks);
    } catch (e) {
      console.error('[ChatService] getUnreadSummary failed:', e);
    }
    return { count: totalCount, latest: latestContent };
  }

  /**
   * 查询某会话当前最大的 msgId（用于将该会话标记为已读）
   */
  static async getMaxMsgId(sessionId: string): Promise<number> {
    try {
      const db = cloudDatabase.zone(ZONE_NAME);
      const q = new cloudDatabase.DatabaseQuery(ChatMessage)
        .equalTo('sessionId', sessionId)
        .orderByDesc('msgId')
        .limit(1);
      const msgs = (await db.query(q)) as ChatMessage[];
      return (msgs && msgs.length > 0) ? msgs[0].msgId : 0;
    } catch (e) {
      console.error('[ChatService] getMaxMsgId failed:', e);
      return 0;
    }
  }

  /**
   * 统计每个会话的未读消息数（对方发送且 msgId > lastReadMsgId[sessionId]）
   * lastReadMsgIdMap: { sessionId -> 最后读到的 msgId }
   * 返回: { sessionId -> 未读数 }
   */
  static async getPerSessionUnreadCounts(
    userId: string,
    lastReadMsgIdMap: Record<string, number>
  ): Promise<Record<string, number>> {
    const result: Record<string, number> = {};
    try {
      const sessions = await ChatService.getSessionsForUser(userId);
      const db = cloudDatabase.zone(ZONE_NAME);
      const tasks: Promise<void>[] = [];
      for (const session of sessions) {
        const sid = session.sessionId;
        const lastReadMsgId = lastReadMsgIdMap[sid] || 0;
        const q = new cloudDatabase.DatabaseQuery(ChatMessage)
          .equalTo('sessionId', sid)
          .greaterThan('msgId', lastReadMsgId)
          .limit(50);
        tasks.push(
          (db.query(q) as Promise<ChatMessage[]>).then((msgs: ChatMessage[]) => {
            let count = 0;
            for (const m of msgs) {
              if (m.senderId !== userId) count++;
            }
            result[sid] = count;
          }).catch(() => { result[sid] = 0; })
        );
      }
      await Promise.all(tasks);
    } catch (e) {
      console.error('[ChatService] getPerSessionUnreadCounts failed:', e);
    }
    return result;
  }

  /**
   * 删除会话：先删所有 ChatMessage，再删 ChatSession
   */
  static async deleteSession(sessionId: string): Promise<void> {
    const db = cloudDatabase.zone(ZONE_NAME);
    // 1. 删该会话下的全部消息
    const mq = new cloudDatabase.DatabaseQuery(ChatMessage).equalTo('sessionId', sessionId);
    const msgs = (await db.query(mq)) as ChatMessage[];
    if (msgs && msgs.length > 0) {
      await db.delete(msgs);
    }
    // 2. 删会话本身
    const sq = new cloudDatabase.DatabaseQuery(ChatSession).equalTo('sessionId', sessionId);
    const sessions = (await db.query(sq)) as ChatSession[];
    if (sessions && sessions.length > 0) {
      await db.delete(sessions);
    }
  }

  /**
   * 双方均确认后，将物品标记为 claimed，双方 Claimed 字段各 +1
   */
  static async markItemClaimed(session: ChatSession): Promise<void> {
    const db = cloudDatabase.zone(ZONE_NAME);
    const iq = new cloudDatabase.DatabaseQuery(ItemInfo).equalTo('itemId', session.itemId);
    const items = (await db.query(iq)) as ItemInfo[];
    if (items && items.length > 0 && items[0].type !== 'claimed') {
      const item = items[0];
      item.type = 'claimed';
      await db.upsert(item);
    }
    const ids: string[] = [session.initiatorId, session.ownerId];
    const uq = new cloudDatabase.DatabaseQuery(UserInfo);
    uq.in('ID', ids);
    const users = (await db.query(uq)) as UserInfo[];
    for (const user of users) {
      user.Claimed = (user.Claimed || 0) + 1;
      await db.upsert(user);
    }
  }
}
