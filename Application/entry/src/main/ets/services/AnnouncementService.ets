import { ApiClient } from '../common/ApiClient';

export interface AnnouncementItem {
  id: number;
  title: string;
  content: string;
  cover: string | null;
  priority: number;
  createdAt: number;
}

interface AnnouncementQuery extends Record<string, string | number | boolean | null | undefined> {
  limit: number;
}

export class AnnouncementService {
  static async list(limit: number = 5): Promise<AnnouncementItem[]> {
    const query: AnnouncementQuery = { limit: limit };
    const list = await ApiClient.get<AnnouncementItem[]>('/announcements', query);
    return list || [];
  }

  static async detail(id: number): Promise<AnnouncementItem | null> {
    const item = await ApiClient.get<AnnouncementItem>(`/announcements/${id}`);
    return item || null;
  }
}
