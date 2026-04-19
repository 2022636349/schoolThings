import { ApiClient } from '../common/ApiClient';

export interface MediaItem {
  type: string;  // 'image' | 'video'
  url: string;
}

export interface ItemCard {
  itemId: number;
  type: string;            // lost / found / claimed
  text: string;
  publishTime: string;     // "X 分钟前"
  publishId: string;
  publisherName: string;
  publisherAvatar: string;
  mediaList: MediaItem[];

  // Phase 3 扩展
  category: string;
  likeCount: number;
  status: string;
  claimedBy: string | null;
  lostTime: number;
}

/** 后端返回的原始卡片数据 */
export interface ItemCardRaw {
  itemId: number;
  type: string;
  text: string;
  title: string | null;
  description: string | null;
  location: string | null;
  publishTime: number;
  publishId: string;
  publisherName: string | null;
  publisherAvatar: string | null;
  mediaList: MediaItem[] | null;
  category: string | null;
  likeCount: number;
  status: string;
  claimedBy: string | null;
  lostTime: number;
}

interface ItemPageRaw {
  list: ItemCardRaw[];
  lastId: number | null;
  hasMore: boolean;
}

interface LikeToggleResp {
  liked: boolean;
}

export function formatTime(date: Date): string {
  const now = new Date();
  const diff = Math.floor((now.getTime() - date.getTime()) / 1000 / 60);
  if (diff < 1) return '刚刚';
  if (diff < 60) return `${diff} 分钟前`;
  if (diff < 60 * 24) return `${Math.floor(diff / 60)} 小时前`;
  return `${Math.floor(diff / 60 / 24)} 天前`;
}

function toCard(raw: ItemCardRaw): ItemCard {
  return {
    itemId: raw.itemId,
    type: raw.type,
    text: raw.text || '',
    publishTime: raw.publishTime ? formatTime(new Date(raw.publishTime)) : '',
    publishId: raw.publishId || '',
    publisherName: raw.publisherName || raw.publishId || '匿名用户',
    publisherAvatar: raw.publisherAvatar || '',
    mediaList: raw.mediaList || [],
    category: raw.category || '其他',
    likeCount: raw.likeCount || 0,
    status: raw.status || 'active',
    claimedBy: raw.claimedBy || null,
    lostTime: raw.lostTime || 0
  } as ItemCard;
}

type ItemListType = 'all' | 'lost' | 'found' | 'claimed';

interface ItemListQuery extends Record<string, string | number | boolean | null | undefined> {
  type: string;
  limit: number;
  lastId?: number;
}

interface ItemSearchQuery extends Record<string, string | number | boolean | null | undefined> {
  keyword: string;
  limit: number;
}

interface ItemCategoryQuery extends Record<string, string | number | boolean | null | undefined> {
  limit: number;
  category?: string;
  lastId?: number;
}

interface ItemMineQuery extends Record<string, string | number | boolean | null | undefined> {
  limit: number;
  lastId?: number;
}

interface UpdateItemBody {
  type: string;
  title: string;
  description: string;
  category: string;
  location: string;
  contact: string;
  lostTime: number;
  mediaList: MediaItem[];
}

interface UpdateStatusBody {
  status: string;
}

export class ItemService {
  // 按类型分页状态：后端返回 lastId，前端把它缓存在这里，实现 "无限滚动" 语义
  private static readonly pageSize: number = 10;
  private static isLoading: boolean = false;
  private static pageStates: Record<ItemListType, number> = {
    'all': 0, 'lost': 0, 'found': 0, 'claimed': 0
  };
  private static noMoreData: Record<ItemListType, boolean> = {
    'all': false, 'lost': false, 'found': false, 'claimed': false
  };

  static async getCardInfoListByType(type: string): Promise<ItemCard[]> {
    const itemType = type as ItemListType;
    if (ItemService.isLoading || ItemService.noMoreData[itemType]) {
      return [];
    }
    ItemService.isLoading = true;
    try {
      const lastId = ItemService.pageStates[itemType];
      const params: ItemListQuery = lastId && lastId > 0
        ? { type: type, limit: ItemService.pageSize, lastId: lastId }
        : { type: type, limit: ItemService.pageSize };
      const page = await ApiClient.get<ItemPageRaw>('/items', params);
      if (!page || !page.list || page.list.length === 0) {
        ItemService.noMoreData[itemType] = true;
        return [];
      }
      if (!page.hasMore) ItemService.noMoreData[itemType] = true;
      if (page.lastId && page.lastId > 0) ItemService.pageStates[itemType] = page.lastId;

      const cards: ItemCard[] = [];
      for (const r of page.list) cards.push(toCard(r));
      return cards;
    } catch (e) {
      console.error('[ItemService] getCardInfoListByType failed:', e);
      return [];
    } finally {
      ItemService.isLoading = false;
    }
  }

  static resetPaginationByType(type: string): void {
    const itemType = type as ItemListType;
    ItemService.isLoading = false;
    ItemService.noMoreData[itemType] = false;
    ItemService.pageStates[itemType] = 0;
  }

  static resetAllPagination(): void {
    ItemService.isLoading = false;
    ItemService.noMoreData = { 'all': false, 'lost': false, 'found': false, 'claimed': false };
    ItemService.pageStates = { 'all': 0, 'lost': 0, 'found': 0, 'claimed': 0 };
  }

  static async updateItem(itemId: number, body: UpdateItemBody): Promise<void> {
    await ApiClient.put<Object>(`/items/${itemId}`, body);
  }

  static async updateStatus(itemId: number, status: string): Promise<void> {
    const body: UpdateStatusBody = { status: status };
    await ApiClient.post<Object>(`/items/${itemId}/status`, body);
  }

  static async deleteItem(itemId: number, _currentUserId: string): Promise<void> {
    await ApiClient.del<Object>(`/items/${itemId}`);
  }

  static async searchByKeyword(keyword: string): Promise<ItemCard[]> {
    try {
      const list = await ApiClient.get<ItemCardRaw[]>('/items/search', { keyword: keyword, limit: 30 } as ItemSearchQuery);
      if (!list) return [];
      const cards: ItemCard[] = [];
      for (const r of list) cards.push(toCard(r));
      return cards;
    } catch (e) {
      console.error('[ItemService] searchByKeyword failed:', e);
      return [];
    }
  }

  /**
   * 按分类分页查询
   */
  static async queryByCategory(category: string, limit: number = 20, lastItemId: number = 0): Promise<ItemCard[]> {
    try {
      const params: ItemCategoryQuery = (category && category.length > 0)
        ? (lastItemId > 0 ? { limit: limit, category: category, lastId: lastItemId } : { limit: limit, category: category })
        : (lastItemId > 0 ? { limit: limit, lastId: lastItemId } : { limit: limit });
      const page = await ApiClient.get<ItemPageRaw>('/items/category', params);
      if (!page || !page.list) return [];
      const cards: ItemCard[] = [];
      for (const r of page.list) cards.push(toCard(r));
      return cards;
    } catch (e) {
      console.error('[ItemService] queryByCategory failed:', e);
      return [];
    }
  }

  static async listHot(limit: number = 5): Promise<ItemCard[]> {
    try {
      const list = await ApiClient.get<ItemCardRaw[]>('/items/hot', { keyword: '', limit: limit } as ItemSearchQuery);
      if (!list) return [];
      const cards: ItemCard[] = [];
      for (const r of list) cards.push(toCard(r));
      return cards;
    } catch (e) {
      console.error('[ItemService] listHot failed:', e);
      return [];
    }
  }

  static async toggleLike(itemId: number, _userId: string): Promise<boolean> {
    const resp = await ApiClient.post<LikeToggleResp>(`/items/${itemId}/like`);
    return !!(resp && resp.liked);
  }

  static async hasLiked(itemId: number, _userId: string): Promise<boolean> {
    try {
      const liked = await ApiClient.get<boolean>(`/items/${itemId}/liked`);
      return !!liked;
    } catch (e) {
      console.error('[ItemService] hasLiked failed:', e);
      return false;
    }
  }

  static async listLiked(limit: number = 50): Promise<ItemCard[]> {
    try {
      const list = await ApiClient.get<ItemCardRaw[]>('/items/liked', { keyword: '', limit: limit } as ItemSearchQuery);
      if (!list) return [];
      const cards: ItemCard[] = [];
      for (const r of list) cards.push(toCard(r));
      return cards;
    } catch (e) {
      console.error('[ItemService] listLiked failed:', e);
      return [];
    }
  }

  /** 我发布的全部物品（不分页，一次拿回） */
  static async listMine(): Promise<ItemCard[]> {
    try {
      const all: ItemCard[] = [];
      let lastId = 0;
      const pageSize = 30;
      while (true) {
        const params: ItemMineQuery = lastId > 0 ? { limit: pageSize, lastId: lastId } : { limit: pageSize };
        const page = await ApiClient.get<ItemPageRaw>('/items/mine', params);
        if (!page || !page.list || page.list.length === 0) break;
        for (const r of page.list) all.push(toCard(r));
        if (!page.hasMore || !page.lastId) break;
        lastId = page.lastId;
      }
      return all;
    } catch (e) {
      console.error('[ItemService] listMine failed:', e);
      return [];
    }
  }

  /** 物品详情 */
  static async detail(itemId: number): Promise<ItemCard | null> {
    try {
      const r = await ApiClient.get<ItemCardRaw>(`/items/${itemId}`);
      return r ? toCard(r) : null;
    } catch (e) {
      console.error('[ItemService] detail failed:', e);
      return null;
    }
  }
}
