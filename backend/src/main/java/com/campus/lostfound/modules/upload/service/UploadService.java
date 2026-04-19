package com.campus.lostfound.modules.upload.service;

import org.springframework.web.multipart.MultipartFile;

public interface UploadService {

    /**
     * 上传文件到 MinIO，返回可公开访问的 URL
     * @param file       multipart 文件
     * @param pathPrefix 目录前缀，如 avatars/ items/
     * @return 公开 URL
     */
    String upload(MultipartFile file, String pathPrefix);

    /** 按传入对象路径生成外链（若已是 http 则原样返回） */
    String toPublicUrl(String objectPath);

    /**
     * base64 方式上传（HarmonyOS 端方便使用）
     * @param pathPrefix 目录前缀，如 avatars/ items/
     * @param fileName   原始文件名（取扩展名）
     * @param base64     base64 编码的文件内容
     * @param contentType MIME 类型
     * @return 公开 URL
     */
    String uploadBase64(String pathPrefix, String fileName, String base64, String contentType);
}
