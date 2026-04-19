package com.campus.lostfound.modules.claim.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campus.lostfound.common.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("claim_request")
public class ClaimRequest extends BaseEntity {
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
}
