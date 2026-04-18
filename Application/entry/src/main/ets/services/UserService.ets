import { cloudDatabase } from '@kit.CloudFoundationKit';
import { common } from '@kit.AbilityKit';
import { UserInfo } from '../model/User';
import { AuthService } from './AuthService';
import { UploadService } from './UploadService';

const ZONE_NAME = 'User';

export interface PublisherInfo {
  name: string;
  avatar: string;
}

export class UserService {
  /**
   * 批量获取用户信息（Name + Avatar），用于卡片展示发布者信息
   * @param ids 需要查询的用户 ID 数组（去重后传入）
   * @returns Record<id, PublisherInfo>
   */
  static async getPublisherInfoByIds(ids: string[]): Promise<Record<string, PublisherInfo>> {
    const result: Record<string, PublisherInfo> = {};
    if (ids.length === 0) return result;
    try {
      const db = cloudDatabase.zone(ZONE_NAME);
      const query = new cloudDatabase.DatabaseQuery(UserInfo);
      query.in('ID', ids);
      const users = (await db.query(query)) as UserInfo[];
      for (const user of users) {
        result[user.ID] = {
          name: user.Name || user.ID,
          avatar: user.Avatar ?? ''
        };
      }
    } catch (error) {
      console.error('[UserService] 批量获取用户信息失败:', error);
    }
    return result;
  }

  /**
   * 上传头像图片并将下载链接写入 UserInfo.Avatar 字段
   * @param context UIAbilityContext
   * @param localUri picker 返回的图片 URI
   * @returns 头像下载链接
   */
  static async uploadAvatar(
    context: common.UIAbilityContext,
    localUri: string
  ): Promise<string> {
    const session = await AuthService.getSession(context);
    const userId = session?.id;
    if (!userId) throw new Error('用户未登录');

    // 文件名含时间戳，每次上传都是新路径 → 新 URL → Image 不会命中旧缓存
    const cloudPath = `avatars/${userId}_${Date.now()}.jpg`;
    const url = await UploadService.uploadFile(context, localUri, cloudPath);

    const db = cloudDatabase.zone(ZONE_NAME);
    const query = new cloudDatabase.DatabaseQuery(UserInfo).equalTo('ID', userId);
    const users = (await db.query(query)) as UserInfo[];
    if (users && users.length > 0) {
      const user = users[0];
      user.Avatar = url;
      await db.upsert(user);
    }
    return url;
  }
}
