import { ApiClient } from '../common/ApiClient';
import { ItemCard } from './ItemService';
import { ItemCardRaw } from './ItemService';

interface WarningQuery extends Record<string, string | number | boolean | null | undefined> {
  limit: number;
}

function toWarningCard(raw: ItemCardRaw): ItemCard {
  return {
    itemId: raw.itemId,
    type: raw.type,
    text: raw.text || '',
    publishTime: raw.publishTime ? '' : '',
    publishId: raw.publishId || '',
    publisherName: raw.publisherName || raw.publishId || '匿名用户',
    publisherAvatar: raw.publisherAvatar || '',
    mediaList: raw.mediaList || [],
    category: raw.category || '其他',
    likeCount: raw.likeCount || 0,
    status: raw.status || 'warning',
    claimedBy: raw.claimedBy || null,
    lostTime: raw.lostTime || 0
  } as ItemCard;
}

export class WarningService {
  static async list(limit: number = 20): Promise<ItemCard[]> {
    const query: WarningQuery = { limit: limit };
    const list = await ApiClient.get<ItemCardRaw[]>('/items/warning', query);
    if (!list) return [];
    const result: ItemCard[] = [];
    for (const raw of list) result.push(toWarningCard(raw));
    return result;
  }
}
