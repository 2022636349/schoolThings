import { cloudDatabase } from "@kit.CloudFoundationKit";
import { ItemInfo } from "../model/ItemCard";
import { UserInfo } from "../model/User";
import { ItemLike } from "../model/ItemLike";
import { UserService } from "./UserService";
import { UploadService } from "./UploadService";

export interface MediaItem {
  type: 'image' | 'video';
  url: string;
}

class ScoredItem {
  item: ItemInfo;
  score: number;
  constructor(item: ItemInfo, score: number) {
    this.item = item;
    this.score = score;
  }
}

export interface ItemCard {
  itemId: number;
  type: string;
  text: string;
  publishTime: string;
  publishId: string;
  publisherName: string;
  publisherAvatar: string;
  mediaList: MediaItem[];
  // Phase 3 扩展字段
  category: string;
  likeCount: number;
  status: string;
  claimedBy: string | null;
  lostTime: number;
}

export function formatTime(date: Date): string {
  const now = new Date();
  const diff = Math.floor((now.getTime() - date.getTime()) / 1000 / 60);
  if (diff < 60) {
    return `${diff} 分钟前`;
  } else if (diff < 60 * 24) {
    return `${Math.floor(diff / 60)} 小时前`;
  } else {
    return `${Math.floor(diff / 60 / 24)} 天前`;
  }
}

export class ItemService {
  private static readonly ZONE_NAME = 'User';
  private static readonly pageSize: number = 10;
  private static isLoading: boolean = false;
  private static pageStates: Record<string, number> = {
    'all': -1, 'lost': -1, 'found': -1, 'claimed': -1
  };
  private static noMoreData: Record<string, boolean> = {
    'all': false, 'lost': false, 'found': false, 'claimed': false
  };

  // 将 ItemInfo[] 转换为 ItemCard[]，附带发布者 Name 和 Avatar
  private static async enrichItems(items: ItemInfo[]): Promise<ItemCard[]> {
    // 收集唯一 publishId（手动去重，兼容 ArkTS）
    const seen: Record<string, boolean> = {};
    const uniqueIds: string[] = [];
    for (const item of items) {
      if (item.publishId && !seen[item.publishId]) {
        seen[item.publishId] = true;
        uniqueIds.push(item.publishId);
      }
    }

    const publisherMap = await UserService.getPublisherInfoByIds(uniqueIds);

    const cards: ItemCard[] = [];
    for (const info of items) {
      let mediaList: MediaItem[] = [];
      try {
        const rawMedia = JSON.parse(info.resource) as MediaItem[];
        const resolvedMedia: MediaItem[] = [];
        for (const m of rawMedia) {
          let url = m.url;
          if (url && !url.startsWith('http')) {
            url = await UploadService.getDownloadURL(url);
          }
          resolvedMedia.push({ type: m.type, url });
        }
        mediaList = resolvedMedia;
      } catch (e) {
        mediaList = [];
      }
      const publisher = publisherMap[info.publishId];
      cards.push({
        itemId: info.itemId,
        type: info.type,
        text: info.text,
        publishTime: formatTime(info.publishTime),
        publishId: info.publishId,
        publisherName: publisher?.name || info.publishId || '匿名用户',
        publisherAvatar: publisher?.avatar || '',
        mediaList: mediaList,
        // Phase 3 字段
        category: info.category || '其他',
        likeCount: info.likeCount || 0,
        status: info.status || 'active',
        claimedBy: info.claimedBy || null,
        lostTime: info.lostTime ? (info.lostTime as Date).getTime() : 0
      } as ItemCard);
    }
    return cards;
  }

  static async getCardInfoListByType(type: string): Promise<ItemCard[]> {
    if (ItemService.isLoading || ItemService.noMoreData[type]) {
      return [];
    }
    ItemService.isLoading = true;

    try {
      const db = cloudDatabase.zone(ItemService.ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(ItemInfo);

      query.orderByDesc('itemId');
      query.limit(ItemService.pageSize);

      if (type !== 'all') {
        query.equalTo('type', type);
      }

      if (ItemService.pageStates[type] !== -1) {
        query.lessThan('itemId', ItemService.pageStates[type]);
      }

      const snapshot = await db.query(query);
      const items = snapshot as ItemInfo[];

      if (!items || items.length === 0) {
        ItemService.noMoreData[type] = true;
        return [];
      }

      if (items.length < ItemService.pageSize) {
        ItemService.noMoreData[type] = true;
      }

      ItemService.pageStates[type] = items[items.length - 1].itemId;

      return await ItemService.enrichItems(items);

    } catch (error) {
      console.error('[ItemService] 获取数据失败:', error);
      return [];
    } finally {
      ItemService.isLoading = false;
    }
  }

  static resetPaginationByType(type: string): void {
    ItemService.isLoading = false;
    ItemService.noMoreData[type] = false;
    ItemService.pageStates[type] = -1;
  }

  static resetAllPagination(): void {
    ItemService.isLoading = false;
    ItemService.noMoreData = { 'all': false, 'lost': false, 'found': false, 'claimed': false };
    ItemService.pageStates = { 'all': -1, 'lost': -1, 'found': -1, 'claimed': -1 };
  }

  static async deleteItem(itemId: number, currentUserId: string): Promise<void> {
    const db = cloudDatabase.zone(ItemService.ZONE_NAME);

    // 1. 查询并校验归属
    const query = new cloudDatabase.DatabaseQuery(ItemInfo).equalTo('itemId', itemId);
    const items = (await db.query(query)) as ItemInfo[];
    if (!items || items.length === 0) {
      throw new Error('物品不存在');
    }
    const item = items[0];
    if (item.publishId !== currentUserId) {
      throw new Error('无权删除他人物品');
    }

    // 2. 删除物品记录
    await db.delete(item);
  }

  static async searchByKeyword(keyword: string): Promise<ItemCard[]> {
    try {
      const db = cloudDatabase.zone(ItemService.ZONE_NAME);

      // 生成 token：完整关键词 + 每个非空字符
      const tokenSet: Record<string, boolean> = {};
      tokenSet[keyword] = true;
      for (let i = 0; i < keyword.length; i++) {
        const ch = keyword[i];
        if (ch.trim().length > 0) {
          tokenSet[ch] = true;
        }
      }
      const tokens = Object.keys(tokenSet);

      // 逐个 token 查询，合并去重
      const seenIds: Record<string, boolean> = {};
      const allItems: ItemInfo[] = [];
      for (const token of tokens) {
        const query = new cloudDatabase.DatabaseQuery(ItemInfo);
        query.contains('text', token);
        query.orderByDesc('itemId');
        const snapshot = await db.query(query);
        const items = snapshot as ItemInfo[];
        for (const item of items) {
          const key = item.itemId.toString();
          if (!seenIds[key]) {
            seenIds[key] = true;
            allItems.push(item);
          }
        }
      }

      if (allItems.length === 0) return [];

      // 相关度评分：text 中包含关键词各字符的数量，完整匹配额外加分
      const scored: ScoredItem[] = [];
      for (const item of allItems) {
        let score = 0;
        for (let i = 0; i < keyword.length; i++) {
          if (item.text.includes(keyword[i])) score++;
        }
        if (item.text.includes(keyword)) score += keyword.length * 2;
        scored.push(new ScoredItem(item, score));
      }
      scored.sort((a: ScoredItem, b: ScoredItem) => b.score - a.score || b.item.itemId - a.item.itemId);

      const sortedItems: ItemInfo[] = [];
      for (const s of scored) {
        sortedItems.push(s.item);
      }
      return await ItemService.enrichItems(sortedItems);
    } catch (error) {
      console.error('[ItemService] 搜索失败:', error);
      return [];
    }
  }

  /**
   * 按分类查询物品（支持分页）
   * @param category 分类名（空字符串表示全部）
   * @param limit 每页数量
   * @param lastItemId 上一页最后一条的 itemId（用于分页，0 表示从头开始）
   */
  static async queryByCategory(category: string, limit: number = 20, lastItemId: number = 0): Promise<ItemInfo[]> {
    try {
      const db = cloudDatabase.zone(ItemService.ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(ItemInfo);
      if (category && category.length > 0) {
        query.equalTo('category', category);
      }
      query.orderByDesc('itemId');
      if (lastItemId > 0) {
        query.lessThan('itemId', lastItemId);
      }
      query.limit(limit);
      const snapshot = await db.query(query);
      return (snapshot as ItemInfo[]) || [];
    } catch (error) {
      console.error('[ItemService] 分类查询失败:', error);
      return [];
    }
  }

  /**
   * 切换物品点赞状态
   * 若已点赞则删除，未点赞则创建
   * @returns true 表示现在是点赞状态，false 表示取消点赞
   */
  static async toggleLike(itemId: number, userId: string): Promise<boolean> {
    try {
      const db = cloudDatabase.zone(ItemService.ZONE_NAME);
      const likeId = `${itemId}_${userId}`;

      // 先查询是否已存在
      const query = new cloudDatabase.DatabaseQuery(ItemLike).equalTo('likeId', likeId);
      const snapshot = await db.query(query);
      const existing = (snapshot as ItemLike[]) || [];

      if (existing.length > 0) {
        // 已点赞，删除
        await db.delete(existing[0]);
        // 同时减少 ItemInfo.likeCount
        const itemQuery = new cloudDatabase.DatabaseQuery(ItemInfo).equalTo('itemId', itemId);
        const items = (await db.query(itemQuery)) as ItemInfo[];
        if (items && items.length > 0) {
          const item = items[0];
          item.likeCount = Math.max(0, (item.likeCount || 0) - 1);
          await db.upsert(item);
        }
        return false;
      } else {
        // 未点赞，创建
        const like = new ItemLike();
        like.likeId = likeId;
        like.itemId = itemId;
        like.userId = userId;
        like.createTime = new Date();
        await db.upsert(like);
        // 同时增加 ItemInfo.likeCount
        const itemQuery = new cloudDatabase.DatabaseQuery(ItemInfo).equalTo('itemId', itemId);
        const items = (await db.query(itemQuery)) as ItemInfo[];
        if (items && items.length > 0) {
          const item = items[0];
          item.likeCount = (item.likeCount || 0) + 1;
          await db.upsert(item);
        }
        return true;
      }
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : 'toggleLike 失败';
      console.error('[ItemService] toggleLike 失败:', errMsg);
      throw new Error('点赞操作失败: ' + errMsg);
    }
  }

  /**
   * 检查当前用户是否已点赞某物品
   */
  static async hasLiked(itemId: number, userId: string): Promise<boolean> {
    try {
      const db = cloudDatabase.zone(ItemService.ZONE_NAME);
      const likeId = `${itemId}_${userId}`;
      const query = new cloudDatabase.DatabaseQuery(ItemLike).equalTo('likeId', likeId);
      const snapshot = await db.query(query);
      const existing = (snapshot as ItemLike[]) || [];
      return existing.length > 0;
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : '查询失败';
      console.error('[ItemService] hasLiked 查询失败:', errMsg);
      return false;
    }
  }
}
