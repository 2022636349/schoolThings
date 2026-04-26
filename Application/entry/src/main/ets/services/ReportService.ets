import { ApiClient } from '../common/ApiClient';
import { Dispute } from '../model/Dispute';

interface CreateReportBody {
  targetType: string;
  targetId: number;
  description: string;
}

interface ReportRaw {
  id: number;
  targetType: string;
  targetId: number;
  reporterId: string;
  targetTitle: string;
  description: string;
  status: string;
  resolution: string;
  result?: string;
  createdAt: number;
  updatedAt: number;
}

function toDispute(raw: ReportRaw): Dispute {
  const item = new Dispute();
  item.disputeId = raw.id;
  item.itemId = raw.targetId;
  item.userId = raw.reporterId || '';
  item.targetTitle = raw.targetTitle || '';
  item.description = raw.description || '';
  item.status = raw.status || 'pending';
  item.resolution = raw.resolution || raw.result || '';
  item.createTime = raw.createdAt > 0 ? new Date(raw.createdAt) : null;
  item.updateTime = raw.updatedAt > 0 ? new Date(raw.updatedAt) : null;
  return item;
}

export class ReportService {
  static async reportItem(itemId: number, description: string): Promise<void> {
    const body: CreateReportBody = {
      targetType: 'item',
      targetId: itemId,
      description: description
    };
    await ApiClient.post<Object>('/reports', body);
  }

  static async listMine(): Promise<Dispute[]> {
    const list = await ApiClient.get<ReportRaw[]>('/reports/mine');
    if (!list) return [];
    const result: Dispute[] = [];
    for (const raw of list) result.push(toDispute(raw));
    return result;
  }
}
