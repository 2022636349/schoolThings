package com.campus.lostfound.common.result;

/**
 * 统一响应码
 */
public enum ResultCode {

    SUCCESS(0, "OK"),
    FAIL(1, "FAIL"),

    // 参数 / 校验
    PARAM_ERROR(1001, "参数错误"),
    PARAM_MISSING(1002, "缺少必填参数"),

    // 认证 / 授权
    UNAUTHORIZED(2001, "未登录或登录已过期"),
    TOKEN_INVALID(2002, "token 无效"),
    TOKEN_EXPIRED(2003, "token 已过期"),
    FORBIDDEN(2004, "无权限"),

    // 用户
    USER_NOT_FOUND(3001, "用户不存在"),
    USER_ALREADY_EXISTS(3002, "用户已存在"),
    PASSWORD_ERROR(3003, "密码错误"),
    SMS_CODE_INVALID(3004, "验证码错误或已过期"),
    SMS_SEND_TOO_FREQUENT(3005, "验证码发送过于频繁"),

    // 业务
    ITEM_NOT_FOUND(4001, "物品不存在"),
    CLAIM_ALREADY_EXISTS(4002, "已提交过认领申请"),

    // 系统
    INTERNAL_ERROR(9000, "系统内部错误"),
    FILE_UPLOAD_ERROR(9001, "文件上传失败");

    private final int code;
    private final String message;

    ResultCode(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }
}
