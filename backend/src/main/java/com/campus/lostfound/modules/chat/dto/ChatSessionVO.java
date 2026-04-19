package com.campus.lostfound.modules.chat.dto;

import lombok.Data;

@Data
public class ChatSessionVO {
    private String sessionId;        // 数据库 id 的字符串形式
    private Long itemId;
    private String initiatorId;      // userId 字符串
    private String ownerId;
    private String lastMessage;
    private Long lastTime;           // 毫秒 / null
    private Integer initiatorConfirmed;
    private Integer ownerConfirmed;

    // 额外展示信息（对端用户）
    private String peerName;
    private String peerAvatar;
    private String itemTitle;
    private String itemStatus;
    private String itemType;
}
