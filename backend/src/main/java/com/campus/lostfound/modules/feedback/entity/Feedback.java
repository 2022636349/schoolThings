package com.campus.lostfound.modules.feedback.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("audit_log")
public class Feedback {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String userName;
    private String module;
    private String action;
    private String target;
    private String params;
    private String result;
    private String ip;
    private String userAgent;
    private Integer durationMs;
    private String errorMsg;
    @TableField("created_at")
    private LocalDateTime createdAt;
}
