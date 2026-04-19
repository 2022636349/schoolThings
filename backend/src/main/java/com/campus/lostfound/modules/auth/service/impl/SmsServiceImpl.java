package com.campus.lostfound.modules.auth.service.impl;

import cn.hutool.core.util.RandomUtil;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.modules.auth.service.SmsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class SmsServiceImpl implements SmsService {

    private final StringRedisTemplate redis;

    @Value("${app.sms.mock:true}")
    private boolean mock;

    @Value("${app.sms.code-expire-minutes:5}")
    private long codeExpireMinutes;

    @Value("${app.sms.code-length:6}")
    private int codeLength;

    private static final String CODE_KEY = "sms:code:%s:%s";        // scene:phone
    private static final String LIMIT_KEY = "sms:limit:%s:%s";      // scene:phone

    @Override
    public void sendCode(String phone, String scene) {
        String limitKey = String.format(LIMIT_KEY, scene, phone);
        Boolean ok = redis.opsForValue().setIfAbsent(limitKey, "1", Duration.ofSeconds(60));
        if (Boolean.FALSE.equals(ok)) {
            throw new BusinessException(ResultCode.SMS_SEND_TOO_FREQUENT);
        }

        String code = RandomUtil.randomNumbers(codeLength);
        String key = String.format(CODE_KEY, scene, phone);
        redis.opsForValue().set(key, code, Duration.ofMinutes(codeExpireMinutes));

        if (mock) {
            log.info("[SMS MOCK] 手机号={} 场景={} 验证码={} 有效期={}分钟", phone, scene, code, codeExpireMinutes);
        } else {
            // TODO: 接入真实短信通道（阿里云 / 华为云）
            log.info("[SMS] 发送真实短信到 {} 场景 {}", phone, scene);
        }
    }

    @Override
    public boolean verifyAndConsume(String phone, String scene, String code) {
        String key = String.format(CODE_KEY, scene, phone);
        String saved = redis.opsForValue().get(key);
        if (saved == null || !saved.equals(code)) {
            return false;
        }
        redis.delete(key);
        return true;
    }

    @Override
    public boolean verifyOnly(String phone, String scene, String code) {
        String key = String.format(CODE_KEY, scene, phone);
        String saved = redis.opsForValue().get(key);
        return saved != null && saved.equals(code);
    }
}
