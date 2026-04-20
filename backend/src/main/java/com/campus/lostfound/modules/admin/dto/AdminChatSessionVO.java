package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminChatSessionVO {
    private Long id;
    private Long itemId;
    private String itemTitle;
    private String initiatorId;
    private String initiatorName;
    private String ownerId;
    private String ownerName;
    private String lastMessage;
    private Long lastMessageAt;
}
