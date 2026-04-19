import { ApiClient } from '../common/ApiClient';
import { ClaimRequest } from '../model/ClaimRequest';

interface ClaimRequestRaw {
  id: number;
  itemId: number;
  itemTitle: string | null;
  itemStatus: string | null;
  claimantId: string | null;
  publisherId: string | null;
  description: string;
  status: string;
  createdAt: number;
}

function toClaim(raw: ClaimRequestRaw): ClaimRequest {
  const item = new ClaimRequest();
  item.requestId = raw.id;
  item.itemId = raw.itemId;
  item.itemTitle = raw.itemTitle || '';
  item.itemStatus = raw.itemStatus || 'pending';
  item.applicantId = raw.claimantId || '';
  item.ownerId = raw.publisherId || '';
  item.description = raw.description || '';
  item.status = raw.status || 'pending';
  item.createTime = raw.createdAt > 0 ? new Date(raw.createdAt) : null;
  return item;
}

interface CreateClaimRequestBody {
  itemId: number;
  description: string;
}

export class ClaimService {
  static async create(itemId: number, description: string): Promise<void> {
    const body: CreateClaimRequestBody = {
      itemId: itemId,
      description: description
    };
    await ApiClient.post<Object>('/claim-requests', body);
  }

  static async listMine(): Promise<ClaimRequest[]> {
    const list = await ApiClient.get<ClaimRequestRaw[]>('/claim-requests/mine');
    if (!list) return [];
    const result: ClaimRequest[] = [];
    for (const raw of list) result.push(toClaim(raw));
    return result;
  }
}
