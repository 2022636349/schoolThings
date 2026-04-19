package com.campus.lostfound.modules.item.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campus.lostfound.common.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("item")
public class Item extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long publisherId;
    private String type;          // lost / found
    private String title;
    private String description;
    private Long categoryId;
    private String categoryName;
    private String location;
    private BigDecimal longitude;
    private BigDecimal latitude;
    private LocalDateTime lostTime;
    private String contact;
    private String status;        // active / claimed / closed / frozen
    private Long claimedBy;
    private LocalDateTime claimedAt;
    private Integer viewCount;
    private Integer likeCount;
    private LocalDateTime warningExpireAt;
    private Integer auditStatus;
    private String auditRemark;
}
