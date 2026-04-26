import { ApiClient } from '../common/ApiClient';
import { Feedback } from '../model/Feedback';

interface FeedbackBody {
  content: string;
}

interface FeedbackRaw {
  id: number;
  content: string;
  reply: string;
  createdAt: number;
}

function toFeedback(raw: FeedbackRaw): Feedback {
  const item = new Feedback();
  item.id = raw.id;
  item.content = raw.content || '';
  item.reply = raw.reply || '';
  item.createdAt = raw.createdAt > 0 ? new Date(raw.createdAt) : null;
  return item;
}

export class FeedbackService {
  static async submit(content: string): Promise<void> {
    const body: FeedbackBody = { content: content };
    await ApiClient.post<Object>('/feedback', body);
  }

  static async listMine(): Promise<Feedback[]> {
    const list = await ApiClient.get<FeedbackRaw[]>('/feedback/mine');
    if (!list) return [];
    const result: Feedback[] = [];
    for (const raw of list) result.push(toFeedback(raw));
    return result;
  }
}
