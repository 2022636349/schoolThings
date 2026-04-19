package com.campus.lostfound.modules.user.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campus.lostfound.common.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 用户表实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("user")
public class User extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String openId;
    private String phone;
    private String phoneHash;
    private String password;
    private String nickname;
    private String avatar;
    private Integer gender;
    private String college;
    private String major;
    private String studentNo;
    private String bio;
    private Integer status;
    private LocalDateTime lastLoginAt;
    private String lastLoginIp;

    /** 推送 token，登录后上报 */
    @com.baomidou.mybatisplus.annotation.TableField("push_token")
    private String pushToken;
}
