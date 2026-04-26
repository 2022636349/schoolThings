import { common } from '@kit.AbilityKit';
import { ApiClient } from '../common/ApiClient';
import { UploadService } from './UploadService';

export interface MediaItem {
  type: string;  
  url: string;
}

interface CreateItemReqBody {
  type: string;
  title?: string;
  description: string;
  category?: string;
  location?: string;
  contact?: string;
  lostTime?: number;
  mediaList?: MediaItem[];
}

export class PostService {

  static async publish(
    context: common.UIAbilityContext,
    type: string,
    description: string,
    location: string,
    mediaList: MediaItem[]
  ): Promise<void> {

    const uploaded: MediaItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const m = mediaList[i];
      const ext = m.type === 'video' ? 'mp4' : 'jpg';
      const cloudPath = `items/${i}.${ext}`;
      const url = await UploadService.uploadFile(context, m.url, cloudPath);
      uploaded.push({ type: m.type, url: url });
    }

    const body: CreateItemReqBody = {
      type: type,
      description: description,
      location: location,
      mediaList: uploaded
    };
    await ApiClient.post<Object>('/items', body, context);
  }

  static async publishFull(
    context: common.UIAbilityContext,
    type: string,
    title: string,
    description: string,
    location: string,
    category: string,
    contact: string,
    lostTime: number,
    mediaList: MediaItem[]
  ): Promise<void> {
    const uploaded: MediaItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const m = mediaList[i];
      const ext = m.type === 'video' ? 'mp4' : 'jpg';
      const cloudPath = `items/${i}.${ext}`;
      const url = await UploadService.uploadFile(context, m.url, cloudPath);
      uploaded.push({ type: m.type, url: url });
    }
    const body: CreateItemReqBody = {
      type: type,
      title: title,
      description: description,
      category: category,
      location: location,
      contact: contact,
      lostTime: lostTime,
      mediaList: uploaded
    };
    await ApiClient.post<Object>('/items', body, context);
  }

  static async update(
    context: common.UIAbilityContext,
    itemId: number,
    type: string,
    title: string,
    description: string,
    location: string,
    category: string,
    contact: string,
    lostTime: number,
    mediaList: MediaItem[]
  ): Promise<void> {
    const uploaded: MediaItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const m = mediaList[i];
      if (m.url.startsWith('http://') || m.url.startsWith('https://')) {
        uploaded.push({ type: m.type, url: m.url });
        continue;
      }
      const ext = m.type === 'video' ? 'mp4' : 'jpg';
      const cloudPath = `items/${itemId}/${i}.${ext}`;
      const url = await UploadService.uploadFile(context, m.url, cloudPath);
      uploaded.push({ type: m.type, url: url });
    }
    const body: CreateItemReqBody = {
      type: type,
      title: title,
      description: description,
      category: category,
      location: location,
      contact: contact,
      lostTime: lostTime,
      mediaList: uploaded
    };
    await ApiClient.put<Object>(`/items/${itemId}`, body, context);
  }
}
