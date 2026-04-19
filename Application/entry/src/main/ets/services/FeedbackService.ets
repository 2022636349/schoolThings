import { ApiClient } from '../common/ApiClient';

interface FeedbackBody {
  content: string;
}

export class FeedbackService {
  static async submit(content: string): Promise<void> {
    const body: FeedbackBody = { content: content };
    await ApiClient.post<Object>('/feedback', body);
  }
}
