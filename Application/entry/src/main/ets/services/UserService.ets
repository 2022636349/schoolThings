import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ApiClient } from '../common/ApiClient';
import { Session } from '../common/Session';

export interface PublisherInfo {
  name: string;
  avatar: string;
}

interface PublisherResp {
  userId: string;
  studentNo: string;
  name: string | null;
  avatar: string | null;
}

interface PublisherBatchQuery extends Record<string, string | number | boolean | null | undefined> {
  ids: string;
}

interface AvatarBody {
  url: string;
}

interface ProfileUpdateBody {
  nickname: string;
  phone: string;
}

export class UserService {
  /**
   * 批量按 userId 查询发布者信息（卡片展示用）
   * @param ids userId 数组（已去重）
   */
  static async getPublisherInfoByIds(ids: string[]): Promise<Record<string, PublisherInfo>> {
    const result: Record<string, PublisherInfo> = {};
    if (!ids || ids.length === 0) return result;
    try {
      const csv = ids.join(',');
      const list = await ApiClient.get<PublisherResp[]>('/user/batch', { ids: csv } as PublisherBatchQuery);
      if (!list) return result;
      for (const p of list) {
        result[p.userId] = {
          name: p.name || p.studentNo || p.userId,
          avatar: p.avatar || ''
        };
      }
    } catch (e) {
      console.error('[UserService] getPublisherInfoByIds failed:', e);
    }
    return result;
  }

  static async updateProfile(context: common.UIAbilityContext, nickname: string, phone: string): Promise<void> {
    const body: ProfileUpdateBody = { nickname: nickname, phone: phone };
    await ApiClient.put<string>('/user/profile', body, context);
    Session.updateProfile(context, nickname, null);
  }

  /**
   * 上传头像文件并把 URL 写回后端
   * @returns 头像公开 URL
   */
  static async uploadAvatar(context: common.UIAbilityContext, localUri: string): Promise<string> {
    if (!Session.isLoggedIn(context)) {
      throw new Error('用户未登录');
    }

    // 1. picker URI → 复制到 cacheDir → 读成 base64
    const fileName = `avatar_${Date.now()}.jpg`;
    const cacheFilePath = `${context.cacheDir}/${fileName}`;
    const srcFile = fileIo.openSync(localUri, fileIo.OpenMode.READ_ONLY);
    const dstFile = fileIo.openSync(cacheFilePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    fileIo.copyFileSync(srcFile.fd, dstFile.fd);
    fileIo.closeSync(srcFile);
    fileIo.closeSync(dstFile);

    try {
      const stat = fileIo.statSync(cacheFilePath);
      const size = stat.size;
      const buf = new ArrayBuffer(size);
      const readFile = fileIo.openSync(cacheFilePath, fileIo.OpenMode.READ_ONLY);
      fileIo.readSync(readFile.fd, buf);
      fileIo.closeSync(readFile);

      const base64 = new util.Base64Helper().encodeToStringSync(new Uint8Array(buf));
      const url = await ApiClient.uploadBase64('avatars', fileName, base64, 'image/jpeg', context);

      // 把 URL 写回后端用户信息
      const body: AvatarBody = { url: url };
      await ApiClient.post<string>('/user/avatar', body, context);

      // 本地缓存同步
      Session.updateProfile(context, null, url);
      Session.saveAvatarVersion(context, String(Date.now()));
      return url;
    } finally {
      fileIo.unlink(cacheFilePath).catch(() => {});
    }
  }
}
