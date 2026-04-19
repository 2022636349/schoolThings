package com.campus.lostfound.modules.upload.service.impl;

import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.modules.upload.service.UploadService;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Base64;

@Slf4j
@Service
@RequiredArgsConstructor
public class UploadServiceImpl implements UploadService {

    private final MinioClient minioClient;

    @Value("${minio.bucket}")
    private String bucket;

    @Value("${minio.endpoint}")
    private String endpoint;

    @Value("${app.upload.public-host:}")
    private String publicHost;

    @Override
    public String upload(MultipartFile file, String pathPrefix) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(ResultCode.FILE_UPLOAD_ERROR, "文件为空");
        }
        String original = StrUtil.blankToDefault(file.getOriginalFilename(), "upload.bin");
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot >= 0) ext = original.substring(dot);
        String date = LocalDate.now().toString();
        String prefix = StrUtil.blankToDefault(pathPrefix, "common/");
        if (!prefix.endsWith("/")) prefix = prefix + "/";
        String objectName = prefix + date + "/" + IdUtil.fastSimpleUUID() + ext;

        try (InputStream in = file.getInputStream()) {
            minioClient.putObject(PutObjectArgs.builder()
                    .bucket(bucket)
                    .object(objectName)
                    .stream(in, file.getSize(), -1)
                    .contentType(StrUtil.blankToDefault(file.getContentType(), "application/octet-stream"))
                    .build());
        } catch (Exception e) {
            log.error("文件上传失败", e);
            throw new BusinessException(ResultCode.FILE_UPLOAD_ERROR, e.getMessage());
        }
        return toPublicUrl(objectName);
    }

    @Override
    public String uploadBase64(String pathPrefix, String fileName, String base64, String contentType) {
        if (StrUtil.isBlank(base64)) {
            throw new BusinessException(ResultCode.FILE_UPLOAD_ERROR, "内容为空");
        }
        // 兼容 data URL：data:image/jpeg;base64,xxx
        String pure = base64;
        int comma = pure.indexOf(',');
        if (pure.startsWith("data:") && comma > 0) {
            pure = pure.substring(comma + 1);
        }
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(pure.getBytes(StandardCharsets.UTF_8));
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ResultCode.FILE_UPLOAD_ERROR, "base64 解码失败");
        }
        String original = StrUtil.blankToDefault(fileName, "upload.bin");
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot >= 0) ext = original.substring(dot);
        String date = LocalDate.now().toString();
        String prefix = StrUtil.blankToDefault(pathPrefix, "common/");
        if (!prefix.endsWith("/")) prefix = prefix + "/";
        String objectName = prefix + date + "/" + IdUtil.fastSimpleUUID() + ext;
        String mime = StrUtil.blankToDefault(contentType, "application/octet-stream");
        try (InputStream in = new ByteArrayInputStream(bytes)) {
            minioClient.putObject(PutObjectArgs.builder()
                    .bucket(bucket)
                    .object(objectName)
                    .stream(in, bytes.length, -1)
                    .contentType(mime)
                    .build());
        } catch (Exception e) {
            log.error("base64 上传失败", e);
            throw new BusinessException(ResultCode.FILE_UPLOAD_ERROR, e.getMessage());
        }
        return toPublicUrl(objectName);
    }

    @Override
    public String toPublicUrl(String objectPath) {
        if (StrUtil.isBlank(objectPath)) return "";
        if (objectPath.startsWith("http://") || objectPath.startsWith("https://")) return objectPath;
        String host = StrUtil.blankToDefault(publicHost, endpoint);
        if (host.endsWith("/")) host = host.substring(0, host.length() - 1);
        return host + "/" + bucket + "/" + objectPath;
    }
}
