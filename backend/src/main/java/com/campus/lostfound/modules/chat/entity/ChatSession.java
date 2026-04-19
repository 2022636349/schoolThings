package com.campus.lostfound.modules.chat.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("chat_session")
public class ChatSession implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long initiatorId;
    private Long ownerId;
    private Long itemId;
    private String lastMessage;
    private LocalDateTime lastMessageAt;
    private Integer initiatorConfirmed;
    private Integer ownerConfirmed;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
