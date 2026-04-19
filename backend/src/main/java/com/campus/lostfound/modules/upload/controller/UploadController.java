package com.campus.lostfound.modules.upload.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.upload.service.UploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "上传", description = "文件上传 (MinIO)")
@RestController
@RequestMapping("/upload")
@RequiredArgsConstructor
public class UploadController {

    private final UploadService uploadService;

    @Operation(summary = "上传文件")
    @PostMapping(value = "/file", consumes = "multipart/form-data")
    public Result<UploadResp> upload(@RequestPart("file") MultipartFile file,
                                     @RequestParam(value = "prefix", defaultValue = "common") String prefix) {
        UserContext.require(); // 要求登录
        String url = uploadService.upload(file, prefix);
        UploadResp resp = new UploadResp();
        resp.setUrl(url);
        return Result.success(resp);
    }

    @Operation(summary = "已有对象路径 → 公开 URL（兼容旧字段）")
    @GetMapping("/url")
    public Result<String> toUrl(@RequestParam("path") String path) {
        return Result.success(uploadService.toPublicUrl(path));
    }

    @Operation(summary = "base64 上传（HarmonyOS 端方便使用，直接返回 URL 字符串）")
    @PostMapping("/base64")
    public Result<String> uploadBase64(@RequestBody Base64Req req) {
        UserContext.require();
        String url = uploadService.uploadBase64(req.getPrefix(), req.getName(), req.getBase64(), req.getContentType());
        return Result.success(url);
    }

    @Data
    public static class UploadResp {
        private String url;
    }

    @Data
    public static class Base64Req {
        private String prefix;
        private String name;
        private String base64;
        private String contentType;
    }
}
