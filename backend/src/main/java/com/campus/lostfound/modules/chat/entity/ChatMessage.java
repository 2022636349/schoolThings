package com.campus.lostfound.modules.chat.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("chat_message")
public class ChatMessage implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long sessionId;
    private Long senderId;
    private String type;       // text / image / item-card / system
    private String content;
    private Integer readFlag;
    private Integer recalled;
    private LocalDateTime createdAt;
}
