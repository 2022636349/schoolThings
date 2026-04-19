package com.campus.lostfound.modules.user.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.campus.lostfound.modules.user.entity.User;

import java.util.List;
import java.util.Map;

public interface UserService extends IService<User> {

    User findByPhoneHash(String phoneHash);

    User findByOpenId(String openId);

    User findByStudentNo(String studentNo);

    /** 注册或返回已有用户（手机号） */
    User registerByPhone(String phone, String nickname, String rawPassword);

    /** 按学号注册 */
    User registerByStudentNo(String studentNo, String password, String nickname, String phone);

    /** 更新最后登录信息 */
    void updateLastLogin(Long userId, String ip);

    /** 保存推送 token */
    void savePushToken(Long userId, String token);

    /** 按 userId 批量查 → map<userIdString, user> */
    Map<String, User> batchGetByIds(List<Long> ids);

    /** 修改密码（校验旧密码） */
    boolean changePassword(Long userId, String oldPwd, String newPwd);

    void resetPassword(Long userId, String newPwd);
}
