package com.campus.lostfound.modules.auth.controller;

import cn.hutool.extra.servlet.JakartaServletUtil;
import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.auth.dto.PasswordLoginReq;
import com.campus.lostfound.modules.auth.dto.RegisterReq;
import com.campus.lostfound.modules.auth.dto.ResetPasswordReq;
import com.campus.lostfound.modules.auth.dto.SmsLoginReq;
import com.campus.lostfound.modules.auth.dto.SmsSendReq;
import com.campus.lostfound.modules.auth.dto.StudentLoginReq;
import com.campus.lostfound.modules.auth.dto.StudentRegisterReq;
import com.campus.lostfound.modules.auth.dto.TokenVO;
import com.campus.lostfound.modules.auth.service.AuthService;
import com.campus.lostfound.modules.auth.service.SmsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "认证", description = "注册 / 登录 / 刷新 / 登出")
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final SmsService smsService;

    @Operation(summary = "发送短信验证码")
    @PostMapping("/sms/send")
    public Result<Void> sendSms(@RequestBody @Valid SmsSendReq req) {
        smsService.sendCode(req.getPhone(), req.getScene());
        return Result.success();
    }

    @Operation(summary = "仅校验验证码是否正确（不消费）")
    @PostMapping("/sms/verify")
    public Result<Boolean> verifySms(@RequestBody SmsVerifyReqBody req) {
        boolean ok = smsService.verifyOnly(req.getPhone(), req.getScene(), req.getCode());
        return Result.success(ok);
    }

    @lombok.Data
    public static class SmsVerifyReqBody {
        private String phone;
        private String scene;
        private String code;
    }

    @Operation(summary = "注册（手机号 + 验证码 + 可选密码）")
    @PostMapping("/register")
    public Result<TokenVO> register(@RequestBody @Valid RegisterReq req, HttpServletRequest request) {
        return Result.success(authService.register(req, JakartaServletUtil.getClientIP(request)));
    }

    @Operation(summary = "手机号 + 验证码登录（不存在则自动注册）")
    @PostMapping("/login/sms")
    public Result<TokenVO> smsLogin(@RequestBody @Valid SmsLoginReq req, HttpServletRequest request) {
        return Result.success(authService.smsLogin(req, JakartaServletUtil.getClientIP(request)));
    }

    @Operation(summary = "手机号 + 密码登录")
    @PostMapping("/login/password")
    public Result<TokenVO> passwordLogin(@RequestBody @Valid PasswordLoginReq req, HttpServletRequest request) {
        return Result.success(authService.passwordLogin(req, JakartaServletUtil.getClientIP(request)));
    }

    @Operation(summary = "学号 + 密码注册（面向校园用户）")
    @PostMapping("/register/student")
    public Result<TokenVO> studentRegister(@RequestBody @Valid StudentRegisterReq req, HttpServletRequest request) {
        return Result.success(authService.studentRegister(req, JakartaServletUtil.getClientIP(request)));
    }

    @Operation(summary = "学号 + 密码登录")
    @PostMapping("/login/student")
    public Result<TokenVO> studentLogin(@RequestBody @Valid StudentLoginReq req, HttpServletRequest request) {
        return Result.success(authService.studentLogin(req, JakartaServletUtil.getClientIP(request)));
    }

    @Operation(summary = "学号是否已注册")
    @GetMapping("/student/taken")
    public Result<Boolean> isStudentNoTaken(@RequestParam("studentNo") String studentNo) {
        return Result.success(authService.isStudentNoTaken(studentNo));
    }

    @Operation(summary = "刷新 access token")
    @PostMapping("/refresh")
    public Result<TokenVO> refresh(@RequestParam("refreshToken") String refreshToken) {
        return Result.success(authService.refresh(refreshToken));
    }

    @Operation(summary = "短信重置密码")
    @PostMapping("/password/reset")
    public Result<Void> resetPassword(@RequestBody @Valid ResetPasswordReq req) {
        authService.resetPassword(req);
        return Result.success();
    }

    @Operation(summary = "登出（吊销 refresh token）")
    @PostMapping("/logout")
    public Result<Void> logout() {
        authService.logout(UserContext.get());
        return Result.success();
    }
}
