package com.campus.lostfound.modules.item.dto;

import lombok.Data;

import java.util.List;

/**
 * App 大厅卡片用（字段名与现有 App ItemCard 结构保持一致，方便前端零改动）
 */
@Data
public class ItemCardVO {
    private Long itemId;
    private String type;                 // lost / found / claimed
    private String text;                 // 合并后的文本：description + 地点/时间
    private String title;
    private String description;
    private String location;
    private Long publishTime;            // 毫秒时间戳
    private String publishId;            // 发布者 userId（字符串）
    private String publisherName;
    private String publisherAvatar;
    private List<MediaDTO> mediaList;
    private String category;
    private Integer likeCount;
    private String status;               // active / pending / claimed / warning / offline
    private String claimedBy;            // 认领人 userId（字符串 / null）
    private Long lostTime;               // 毫秒时间戳 / 0
}
