package com.campus.lostfound.modules.chat.dto;

import lombok.Data;

@Data
public class ChatMessageVO {
    private Long msgId;
    private String sessionId;
    private String senderId;
    private String content;
    private Long sendTime;        // 毫秒
    private String messageType;   // text / image / item-card / system
    private String imageUrl;      // messageType=image 时有效
}
