import { ApiClient } from '../common/ApiClient';

export interface RankingUser {
  userId: string;
  name: string;
  avatar: string | null;
  heartValue: number;
  returnCount: number;
}

interface RankingQuery extends Record<string, string | number | boolean | null | undefined> {
  limit: number;
}

export class RankingService {
  static async list(limit: number = 10): Promise<RankingUser[]> {
    const query: RankingQuery = { limit: limit };
    const list = await ApiClient.get<RankingUser[]>('/user/ranking', query);
    return list || [];
  }
}
