package com.campus.lostfound.modules.claim.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("claim_request")
public class ClaimRequest {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long itemId;
    private Long claimantId;
    private Long publisherId;
    private String description;
    private String contact;
    private String status;
    private String rejectReason;
    private LocalDateTime approvedAt;
    private LocalDateTime confirmedAt;
    @TableField("created_at")
    private LocalDateTime createdAt;
    @TableField("updated_at")
    private LocalDateTime updatedAt;
}
