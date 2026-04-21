package com.campus.lostfound.modules.user.controller;

import cn.hutool.core.util.StrUtil;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.user.dto.PublisherVO;
import com.campus.lostfound.modules.user.dto.RankingUserVO;
import com.campus.lostfound.modules.user.dto.SessionVO;
import com.campus.lostfound.modules.user.dto.UserInfoVO;
import com.campus.lostfound.modules.user.entity.User;
import com.campus.lostfound.modules.user.entity.UserStat;
import com.campus.lostfound.modules.user.mapper.UserStatMapper;
import com.campus.lostfound.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Tag(name = "用户", description = "用户信息")
@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final UserStatMapper userStatMapper;

    @Operation(summary = "获取当前登录用户会话信息（含统计）")
    @GetMapping("/me")
    public Result<SessionVO> me() {
        Long uid = UserContext.require();
        User u = userService.getById(uid);
        if (u == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        UserStat stat = userStatMapper.selectById(uid);
        return Result.success(toSessionVO(u, stat));
    }

    @Operation(summary = "更新当前用户信息")
    @PutMapping("/me")
    public Result<UserInfoVO> update(@RequestBody UserInfoVO body) {
        Long uid = UserContext.require();
        User u = new User();
        u.setId(uid);
        u.setNickname(body.getNickname());
        u.setAvatar(body.getAvatar());
        u.setGender(body.getGender());
        u.setCollege(body.getCollege());
        u.setMajor(body.getMajor());
        u.setBio(body.getBio());
        userService.updateById(u);
        User after = userService.getById(uid);
        return Result.success(toUserInfoVO(after));
    }

    @Operation(summary = "更新当前用户基础资料")
    @PutMapping("/profile")
    public Result<UserInfoVO> updateProfile(@RequestBody UpdateProfileReq req) {
        Long uid = UserContext.require();
        User u = new User();
        u.setId(uid);
        u.setNickname(req.getNickname());
        u.setPhone(req.getPhone());
        userService.updateById(u);
        User after = userService.getById(uid);
        return Result.success(toUserInfoVO(after));
    }
    @Operation(summary = "批量按 userId 查用户（卡片用）")
    @GetMapping("/batch")
    public Result<List<PublisherVO>> batchByIds(@RequestParam("ids") String idsCsv) {
        if (StrUtil.isBlank(idsCsv)) {
            return Result.success(new ArrayList<>());
        }
        List<Long> ids = new ArrayList<>();
        for (String s : idsCsv.split(",")) {
            String t = s.trim();
            if (!t.isEmpty()) {
                try {
                    ids.add(Long.parseLong(t));
                } catch (NumberFormatException ignore) {
                }
            }
        }
        Map<String, User> map = userService.batchGetByIds(ids);
        List<PublisherVO> list = new ArrayList<>();
        for (User u : map.values()) {
            PublisherVO vo = new PublisherVO();
            vo.setUserId(String.valueOf(u.getId()));
            vo.setStudentNo(u.getStudentNo());
            vo.setName(u.getNickname());
            vo.setAvatar(u.getAvatar());
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "热心榜 TOP")
    @GetMapping("/ranking")
    public Result<List<RankingUserVO>> ranking(@RequestParam(value = "limit", defaultValue = "10") int limit) {
        List<UserStat> stats = userStatMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<UserStat>()
                .orderByDesc(UserStat::getHeartValue)
                .orderByDesc(UserStat::getReturnCount)
                .orderByDesc(UserStat::getUserId)
                .last("LIMIT " + Math.min(Math.max(limit, 1), 20)));
        List<Long> ids = new ArrayList<>();
        for (UserStat stat : stats) {
            ids.add(stat.getUserId());
        }
        Map<String, User> userMap = userService.batchGetByIds(ids);
        List<RankingUserVO> list = new ArrayList<>();
        for (UserStat stat : stats) {
            User u = userMap.get(String.valueOf(stat.getUserId()));
            RankingUserVO vo = new RankingUserVO();
            vo.setUserId(String.valueOf(stat.getUserId()));
            vo.setName(u != null ? u.getNickname() : "匿名用户");
            vo.setAvatar(u != null ? u.getAvatar() : null);
            vo.setHeartValue(stat.getHeartValue() == null ? 0 : stat.getHeartValue());
            vo.setReturnCount(stat.getReturnCount() == null ? 0 : stat.getReturnCount());
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "按 userId 查单个用户")
    @GetMapping("/{userId}")
    public Result<PublisherVO> getById(@PathVariable("userId") Long userId) {
        User u = userService.getById(userId);
        if (u == null) throw new BusinessException(ResultCode.USER_NOT_FOUND);
        PublisherVO vo = new PublisherVO();
        vo.setUserId(String.valueOf(u.getId()));
        vo.setStudentNo(u.getStudentNo());
        vo.setName(u.getNickname());
        vo.setAvatar(u.getAvatar());
        return Result.success(vo);
    }

    @Operation(summary = "上报推送 token")
    @PostMapping("/push-token")
    public Result<Void> savePushToken(@RequestBody PushTokenReq req) {
        Long uid = UserContext.require();
        userService.savePushToken(uid, req.getToken());
        return Result.success();
    }

    @Operation(summary = "修改密码")
    @PostMapping("/change-password")
    public Result<Boolean> changePassword(@RequestBody ChangePasswordReq req) {
        Long uid = UserContext.require();
        boolean ok = userService.changePassword(uid, req.getOldPassword(), req.getNewPassword());
        return Result.success(ok);
    }

    @Operation(summary = "更新头像（URL 已通过上传接口获取）")
    @PostMapping("/avatar")
    public Result<String> updateAvatar(@RequestBody AvatarReq req) {
        Long uid = UserContext.require();
        User u = new User();
        u.setId(uid);
        u.setAvatar(req.getUrl());
        userService.updateById(u);
        return Result.success(req.getUrl());
    }

    private SessionVO toSessionVO(User u, UserStat stat) {
        SessionVO vo = new SessionVO();
        vo.setId(String.valueOf(u.getId()));
        vo.setStudentNo(u.getStudentNo());
        vo.setName(u.getNickname());
        vo.setAvatar(u.getAvatar());
        vo.setPublished(stat != null && stat.getPostCount() != null ? stat.getPostCount() : 0);
        vo.setClaimed(0);
        vo.setHeartValue(stat != null && stat.getHeartValue() != null ? stat.getHeartValue() : 0);
        vo.setFraudCount(stat != null && stat.getFraudValue() != null ? stat.getFraudValue() : 0);
        vo.setPhoneMasked(maskPhone(u.getPhone()));
        return vo;
    }

    private UserInfoVO toUserInfoVO(User u) {
        UserInfoVO vo = new UserInfoVO();
        vo.setId(u.getId());
        vo.setNickname(u.getNickname());
        vo.setAvatar(u.getAvatar());
        vo.setGender(u.getGender());
        vo.setCollege(u.getCollege());
        vo.setMajor(u.getMajor());
        vo.setBio(u.getBio());
        vo.setPhoneMasked(maskPhone(u.getPhone()));
        return vo;
    }

    private String maskPhone(String phone) {
        if (StrUtil.isBlank(phone) || phone.length() < 11) return null;
        return phone.substring(0, 3) + "****" + phone.substring(7);
    }

    @Data
    public static class UpdateProfileReq {
        private String nickname;
        private String phone;
    }

    @Data
    public static class PushTokenReq {
        private String token;
    }

    @Data
    public static class ChangePasswordReq {
        private String oldPassword;
        private String newPassword;
    }

    @Data
    public static class AvatarReq {
        private String url;
    }
}
