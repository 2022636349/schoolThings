import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ApiClient } from '../common/ApiClient';

interface UploadUrlQuery extends Record<string, string | number | boolean | null | undefined> {
  path: string;
}


export class UploadService {
  /**
   * 上传文件到后端
   * @param context  UIAbilityContext
   * @param localUri picker / cacheDir 返回的 URI 或路径
   * @param cloudPath 逻辑上的目标路径（如 "avatars/avatar.jpg" 或 "items/123/0.jpg"）
   *                  仅取前缀目录用作 MinIO 分组，文件名会被服务端替换为 uuid 避免冲突
   */
  static async uploadFile(
    context: common.UIAbilityContext,
    localUri: string,
    cloudPath: string
  ): Promise<string> {
    const lastSlash = cloudPath.lastIndexOf('/');
    const prefix = lastSlash > 0 ? cloudPath.substring(0, lastSlash) : 'common';
    const origName = lastSlash > 0 ? cloudPath.substring(lastSlash + 1) : cloudPath;
    const safeName = cloudPath.replace(/\//g, '_');
    const cacheFilePath = `${context.cacheDir}/${safeName}`;

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
      const contentType = UploadService.guessContentType(origName);
      const url = await ApiClient.uploadBase64(prefix, origName, base64, contentType, context);
      return url;
    } finally {
      fileIo.unlink(cacheFilePath).catch(() => {});
    }
  }


  static async getDownloadURL(cloudPathOrUrl: string): Promise<string> {
    if (!cloudPathOrUrl) return '';
    if (cloudPathOrUrl.startsWith('http://') || cloudPathOrUrl.startsWith('https://')) {
      return cloudPathOrUrl;
    }
    try {
      const url = await ApiClient.get<string>('/upload/url', { path: cloudPathOrUrl } as UploadUrlQuery);
      return url || '';
    } catch (e) {
      console.warn('[UploadService] getDownloadURL failed:', e);
      return '';
    }
  }

  private static guessContentType(name: string): string {
    const lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }
}
