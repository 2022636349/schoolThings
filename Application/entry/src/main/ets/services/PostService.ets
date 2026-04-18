import { cloudDatabase } from '@kit.CloudFoundationKit';
import { common } from '@kit.AbilityKit';
import { ItemInfo } from '../model/ItemCard';
import { UserInfo } from '../model/User';
import { AuthService } from './AuthService';
import { UploadService } from './UploadService';

export interface MediaItem {
  type: 'image' | 'video';
  url: string;
}

const ZONE_NAME = 'User';

export class PostService {
  // 查询当前最大 itemId，返回 max+1；表为空时返回 1
  private static async generateNextItemId(): Promise<number> {
    try {
      const db = cloudDatabase.zone(ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(ItemInfo);
      query.orderByDesc('itemId');
      query.limit(1);
      const result = (await db.query(query)) as ItemInfo[];
      if (result && result.length > 0) {
        return result[0].itemId + 1;
      }
      return 1;
    } catch (error) {
      console.error('[PostService] generateNextItemId 失败', error);
      return 1;
    }
  }

  // 批量上传媒体列表
  private static async uploadMediaList(
    context: common.UIAbilityContext,
    mediaList: MediaItem[],
    itemId: number
  ): Promise<MediaItem[]> {
    const uploaded: MediaItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const media = mediaList[i];
      const ext = media.type === 'video' ? 'mp4' : 'jpg';
      const cloudPath = `items/${itemId}/${i}.${ext}`;
      await UploadService.uploadFile(context, media.url, cloudPath);
      uploaded.push({ type: media.type, url: cloudPath });
    }
    return uploaded;
  }

  // 对外发布方法
  static async publish(
    context: common.UIAbilityContext,
    type: string,
    description: string,
    location: string,
    mediaList: MediaItem[]
  ): Promise<void> {
    const session = await AuthService.getSession(context);
    const publishId = session?.id ?? '';

    const itemId = await PostService.generateNextItemId();

    let uploadedMedia: MediaItem[] = [];
    if (mediaList.length > 0) {
      uploadedMedia = await PostService.uploadMediaList(context, mediaList, itemId);
    }

    const db = cloudDatabase.zone(ZONE_NAME);
    const newItem = new ItemInfo();
    newItem.itemId = itemId;
    newItem.type = type;
    newItem.text = `${description}\n地点：${location}`;
    newItem.publishTime = new Date();
    newItem.publishId = publishId;
    newItem.resource = JSON.stringify(uploadedMedia);
    await db.upsert(newItem);

    // 发布成功后递增用户 Published 计数
    if (publishId) {
      try {
        const userQuery = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', publishId);
        const users = (await db.query(userQuery)) as UserInfo[];
        if (users && users.length > 0) {
          const user = users[0];
          user.Published = (user.Published || 0) + 1;
          await db.upsert(user);
        }
      } catch (e) {
        console.error('[PostService] 更新发布计数失败:', e);
      }
    }
  }
}
