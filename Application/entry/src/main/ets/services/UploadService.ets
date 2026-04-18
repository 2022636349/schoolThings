import { cloudStorage } from '@kit.CloudFoundationKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError, request } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class UploadService {
  private static readonly bucket: cloudStorage.StorageBucket = cloudStorage.bucket();

  static async getDownloadURL(cloudPath: string): Promise<string> {
    return UploadService.bucket.getDownloadURL(cloudPath);
  }

  /**
   * 将 picker URI 上传到云存储，返回公开下载链接
   * @param context  UIAbilityContext
   * @param localUri picker 返回的 URI
   * @param cloudPath 云存储路径，如 "avatars/userId.jpg"
   */
  static async uploadFile(
    context: common.UIAbilityContext,
    localUri: string,
    cloudPath: string
  ): Promise<string> {
    // 1. picker URI 是临时授权，先复制到 cacheDir 落盘
    const fileName = cloudPath.replace(/\//g, '_');
    const cacheFilePath = `${context.cacheDir}/${fileName}`;

    const srcFile = fileIo.openSync(localUri, fileIo.OpenMode.READ_ONLY);
    const dstFile = fileIo.openSync(cacheFilePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    fileIo.copyFileSync(srcFile.fd, dstFile.fd);
    fileIo.closeSync(srcFile);
    fileIo.closeSync(dstFile);

    // 2. 上传到云存储，完成后获取下载链接
    return new Promise<string>((resolve, reject) => {
      UploadService.bucket.uploadFile(context, {
        localPath: cacheFilePath,
        cloudPath: cloudPath
      }).then((task: request.agent.Task) => {
        task.on('completed', () => {
          UploadService.bucket.getDownloadURL(cloudPath).then((url: string) => {
            fileIo.unlink(cacheFilePath).catch(() => {});
            resolve(url);
          }).catch((err: BusinessError) => {
            fileIo.unlink(cacheFilePath).catch(() => {});
            reject(err);
          });
        });
        task.on('failed', (progress) => {
          fileIo.unlink(cacheFilePath).catch(() => {});
          const detail = JSON.stringify(progress);
          console.error('[UploadService] 上传失败:', detail);
          reject(new Error(`上传失败: ${detail}`));
        });
        task.start().catch((err: BusinessError) => {
          fileIo.unlink(cacheFilePath).catch(() => {});
          reject(err);
        });
      }).catch((err: BusinessError) => {
        fileIo.unlink(cacheFilePath).catch(() => {});
        reject(err);
      });
    });
  }
}
