package com.campus.lostfound.modules.user.service.impl;

import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.digest.DigestUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.modules.user.entity.User;
import com.campus.lostfound.modules.user.mapper.UserMapper;
import com.campus.lostfound.modules.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final PasswordEncoder passwordEncoder;

    @Override
    public User findByPhoneHash(String phoneHash) {
        if (StrUtil.isBlank(phoneHash)) return null;
        return this.getOne(new LambdaQueryWrapper<User>()
                .eq(User::getPhoneHash, phoneHash));
    }

    @Override
    public User findByOpenId(String openId) {
        if (StrUtil.isBlank(openId)) return null;
        return this.getOne(new LambdaQueryWrapper<User>()
                .eq(User::getOpenId, openId));
    }

    @Override
    public User findByStudentNo(String studentNo) {
        if (StrUtil.isBlank(studentNo)) return null;
        return this.getOne(new LambdaQueryWrapper<User>()
                .eq(User::getStudentNo, studentNo));
    }

    @Override
    public User registerByPhone(String phone, String nickname, String rawPassword) {
        String phoneHash = DigestUtil.sha256Hex(phone);
        User exists = findByPhoneHash(phoneHash);
        if (exists != null) {
            throw new BusinessException(ResultCode.USER_ALREADY_EXISTS);
        }
        User u = new User();
        u.setPhone(phone);
        u.setPhoneHash(phoneHash);
        u.setNickname(StrUtil.isBlank(nickname) ? "用户" + phone.substring(phone.length() - 4) : nickname);
        if (StrUtil.isNotBlank(rawPassword)) {
            u.setPassword(passwordEncoder.encode(rawPassword));
        }
        u.setGender(0);
        u.setStatus(1);
        this.save(u);
        return u;
    }

    @Override
    public User registerByStudentNo(String studentNo, String password, String nickname, String phone) {
        if (findByStudentNo(studentNo) != null) {
            throw new BusinessException(ResultCode.USER_ALREADY_EXISTS, "学号已注册");
        }
        User u = new User();
        u.setStudentNo(studentNo);
        u.setNickname(StrUtil.isBlank(nickname) ? studentNo : nickname);
        if (StrUtil.isNotBlank(password)) {
            u.setPassword(passwordEncoder.encode(password));
        }
        if (StrUtil.isNotBlank(phone)) {
            u.setPhone(phone);
            u.setPhoneHash(DigestUtil.sha256Hex(phone));
        }
        u.setGender(0);
        u.setStatus(1);
        this.save(u);
        return u;
    }

    @Override
    public void updateLastLogin(Long userId, String ip) {
        User u = new User();
        u.setId(userId);
        u.setLastLoginAt(LocalDateTime.now());
        u.setLastLoginIp(ip);
        this.updateById(u);
    }

    @Override
    public void savePushToken(Long userId, String token) {
        if (userId == null || StrUtil.isBlank(token)) return;
        User u = new User();
        u.setId(userId);
        u.setPushToken(token);
        this.updateById(u);
    }

    @Override
    public Map<String, User> batchGetByIds(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return Collections.emptyMap();
        List<User> list = this.listByIds(ids);
        Map<String, User> map = new HashMap<>();
        for (User u : list) {
            map.put(String.valueOf(u.getId()), u);
        }
        return map;
    }

    @Override
    public boolean changePassword(Long userId, String oldPwd, String newPwd) {
        User u = this.getById(userId);
        if (u == null) return false;
        if (StrUtil.isNotBlank(u.getPassword())
                && !passwordEncoder.matches(oldPwd, u.getPassword())) {
            return false;
        }
        User upd = new User();
        upd.setId(userId);
        upd.setPassword(passwordEncoder.encode(newPwd));
        this.updateById(upd);
        return true;
    }

    @Override
    public void resetPassword(Long userId, String newPwd) {
        User upd = new User();
        upd.setId(userId);
        upd.setPassword(passwordEncoder.encode(newPwd));
        this.updateById(upd);
    }
}
