package com.campus.lostfound.modules.user.dto;

import lombok.Data;

/**
 * 用户会话信息（匹配 App 端 SessionInfo 结构）
 */
@Data
public class SessionVO {
    private String id;           // 实际为 user.id 的字符串形式
    private String studentNo;
    private String name;
    private String avatar;
    private Integer published;
    private Integer claimed;
    private Integer heartValue;
    private Integer fraudCount;
    private String phoneMasked;
}
