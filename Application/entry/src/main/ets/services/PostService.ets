import { common } from '@kit.AbilityKit';
import { ApiClient } from '../common/ApiClient';
import { UploadService } from './UploadService';

export interface MediaItem {
  type: string;  // 'image' | 'video'
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
  /**
   * 发布新物品：
   * 1) 先把 mediaList 里的本地 URI 逐个上传后台 → 拿到公开 URL
   * 2) 再调用 POST /items 写入数据库
   */
  static async publish(
    context: common.UIAbilityContext,
    type: string,
    description: string,
    location: string,
    mediaList: MediaItem[]
  ): Promise<void> {
    // 1. 上传媒体
    const uploaded: MediaItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const m = mediaList[i];
      const ext = m.type === 'video' ? 'mp4' : 'jpg';
      const cloudPath = `items/${i}.${ext}`;
      const url = await UploadService.uploadFile(context, m.url, cloudPath);
      uploaded.push({ type: m.type, url: url });
    }

    // 2. 调后端创建
    const body: CreateItemReqBody = {
      type: type,
      description: description,
      location: location,
      mediaList: uploaded
    };
    await ApiClient.post<Object>('/items', body, context);
  }

  /**
   * 带分类 / 时间 / 标题的完整发布
   */
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
