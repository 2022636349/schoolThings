package com.campus.lostfound.modules.auth.service;

public interface SmsService {

    /** 发送验证码（开发环境 mock 到日志） */
    void sendCode(String phone, String scene);

    /** 校验验证码并消费 */
    boolean verifyAndConsume(String phone, String scene, String code);

    /** 仅校验验证码是否匹配，不消费（前端注册页单独校验用） */
    boolean verifyOnly(String phone, String scene, String code);
}
