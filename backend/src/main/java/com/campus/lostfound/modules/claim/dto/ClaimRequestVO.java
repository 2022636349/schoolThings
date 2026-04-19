package com.campus.lostfound.modules.claim.dto;

import lombok.Data;

@Data
public class ClaimRequestVO {
    private Long id;
    private Long itemId;
    private String claimantId;
    private String publisherId;
    private String description;
    private String status;
    private Long createdAt;
    private String itemTitle;
    private String itemStatus;
}
