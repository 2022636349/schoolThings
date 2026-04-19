package com.campus.lostfound.modules.auth.service.impl;

import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.digest.DigestUtil;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.common.util.JwtUtil;
import com.campus.lostfound.modules.auth.dto.PasswordLoginReq;
import com.campus.lostfound.modules.auth.dto.RegisterReq;
import com.campus.lostfound.modules.auth.dto.ResetPasswordReq;
import com.campus.lostfound.modules.auth.dto.SmsLoginReq;
import com.campus.lostfound.modules.auth.dto.StudentLoginReq;
import com.campus.lostfound.modules.auth.dto.StudentRegisterReq;
import com.campus.lostfound.modules.auth.dto.TokenVO;
import com.campus.lostfound.modules.auth.service.AuthService;
import com.campus.lostfound.modules.auth.service.SmsService;
import com.campus.lostfound.modules.user.entity.User;
import com.campus.lostfound.modules.user.service.UserService;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserService userService;
    private final SmsService smsService;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final StringRedisTemplate redis;

    private static final String REFRESH_KEY = "auth:refresh:%d";

    @Override
    public TokenVO register(RegisterReq req, String ip) {
        if (!smsService.verifyAndConsume(req.getPhone(), "register", req.getCode())) {
            throw new BusinessException(ResultCode.SMS_CODE_INVALID);
        }
        User u = userService.registerByPhone(req.getPhone(), req.getNickname(), req.getPassword());
        userService.updateLastLogin(u.getId(), ip);
        return buildToken(u);
    }

    @Override
    public TokenVO smsLogin(SmsLoginReq req, String ip) {
        if (!smsService.verifyAndConsume(req.getPhone(), "login", req.getCode())) {
            throw new BusinessException(ResultCode.SMS_CODE_INVALID);
        }
        String phoneHash = DigestUtil.sha256Hex(req.getPhone());
        User u = userService.findByPhoneHash(phoneHash);
        if (u == null) {
            // 首次手机号登录：自动创建账户
            u = userService.registerByPhone(req.getPhone(), null, null);
        }
        userService.updateLastLogin(u.getId(), ip);
        return buildToken(u);
    }

    @Override
    public TokenVO passwordLogin(PasswordLoginReq req, String ip) {
        String phoneHash = DigestUtil.sha256Hex(req.getPhone());
        User u = userService.findByPhoneHash(phoneHash);
        if (u == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        if (StrUtil.isBlank(u.getPassword())
                || !passwordEncoder.matches(req.getPassword(), u.getPassword())) {
            throw new BusinessException(ResultCode.PASSWORD_ERROR);
        }
        if (u.getStatus() != null && u.getStatus() == 0) {
            throw new BusinessException(ResultCode.FORBIDDEN, "账号已被禁用");
        }
        userService.updateLastLogin(u.getId(), ip);
        return buildToken(u);
    }

    @Override
    public TokenVO studentRegister(StudentRegisterReq req, String ip) {
        // 如果同时填了 phone + code，必须校验通过
        if (StrUtil.isNotBlank(req.getPhone()) && StrUtil.isNotBlank(req.getCode())) {
            if (!smsService.verifyAndConsume(req.getPhone(), "register", req.getCode())) {
                throw new BusinessException(ResultCode.SMS_CODE_INVALID);
            }
        }
        User u = userService.registerByStudentNo(
                req.getStudentNo(), req.getPassword(), req.getNickname(), req.getPhone());
        userService.updateLastLogin(u.getId(), ip);
        return buildToken(u);
    }

    @Override
    public TokenVO studentLogin(StudentLoginReq req, String ip) {
        User u = userService.findByStudentNo(req.getStudentNo());
        if (u == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        if (StrUtil.isBlank(u.getPassword())
                || !passwordEncoder.matches(req.getPassword(), u.getPassword())) {
            throw new BusinessException(ResultCode.PASSWORD_ERROR);
        }
        if (u.getStatus() != null && u.getStatus() == 0) {
            throw new BusinessException(ResultCode.FORBIDDEN, "账号已被禁用");
        }
        userService.updateLastLogin(u.getId(), ip);
        return buildToken(u);
    }

    @Override
    public boolean isStudentNoTaken(String studentNo) {
        return userService.findByStudentNo(studentNo) != null;
    }

    @Override
    public TokenVO refresh(String refreshToken) {
        if (StrUtil.isBlank(refreshToken) || !jwtUtil.isValid(refreshToken)) {
            throw new BusinessException(ResultCode.TOKEN_INVALID);
        }
        Claims claims = jwtUtil.parse(refreshToken);
        if (!"refresh".equals(claims.get("type"))) {
            throw new BusinessException(ResultCode.TOKEN_INVALID);
        }
        Long userId = jwtUtil.getUserId(refreshToken);
        String cached = redis.opsForValue().get(String.format(REFRESH_KEY, userId));
        if (cached == null || !cached.equals(refreshToken)) {
            throw new BusinessException(ResultCode.TOKEN_EXPIRED);
        }
        User u = userService.getById(userId);
        if (u == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        return buildToken(u);
    }

    @Override
    public void resetPassword(ResetPasswordReq req) {
        if (!smsService.verifyAndConsume(req.getPhone(), "reset_password", req.getCode())) {
            throw new BusinessException(ResultCode.SMS_CODE_INVALID);
        }
        String phoneHash = DigestUtil.sha256Hex(req.getPhone());
        User u = userService.findByPhoneHash(phoneHash);
        if (u == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        userService.resetPassword(u.getId(), req.getNewPassword());
    }

    @Override
    public void logout(Long userId) {
        if (userId != null) {
            redis.delete(String.format(REFRESH_KEY, userId));
        }
    }

    private TokenVO buildToken(User u) {
        String access = jwtUtil.generateAccessToken(u.getId(), u.getNickname());
        String refresh = jwtUtil.generateRefreshToken(u.getId());
        // 缓存 refresh token，支持主动吊销
        redis.opsForValue().set(
                String.format(REFRESH_KEY, u.getId()),
                refresh,
                Duration.ofDays(30)
        );
        return TokenVO.builder()
                .userId(u.getId())
                .nickname(u.getNickname())
                .avatar(u.getAvatar())
                .accessToken(access)
                .refreshToken(refresh)
                .expiresIn(jwtUtil.getAccessExpireSeconds())
                .tokenType("Bearer")
                .build();
    }
}
