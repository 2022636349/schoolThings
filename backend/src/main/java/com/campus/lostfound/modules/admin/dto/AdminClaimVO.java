package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminClaimVO {
    private Long id;
    private Long itemId;
    private String itemTitle;
    private String itemStatus;
    private String description;
    private String contact;
    private String status;
    private String claimantId;
    private String claimantName;
    private String publisherId;
    private String publisherName;
    private String reviewRemark;
    private Long createdAt;
    private Long approvedAt;
}
