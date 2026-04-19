package com.campus.lostfound.modules.user.dto;

import lombok.Data;

/**
 * 对外暴露的用户信息（脱敏）
 */
@Data
public class UserInfoVO {
    private Long id;
    private String nickname;
    private String avatar;
    private Integer gender;
    private String college;
    private String major;
    private String bio;
    private String phoneMasked; // 138****1234
}
