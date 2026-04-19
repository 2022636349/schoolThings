package com.campus.lostfound.modules.user.dto;

import lombok.Data;

/**
 * 卡片展示用：发布者简要信息
 */
@Data
public class PublisherVO {
    private String userId;       // 字符串形式的 user.id
    private String studentNo;
    private String name;
    private String avatar;
}
