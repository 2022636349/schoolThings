package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class ReviewReportReq {
    private String status;
    private String resolution;
    private String itemStatus;
    private Integer reporterHeartDelta;
    private Integer reporterFraudDelta;
    private Integer publisherHeartDelta;
    private Integer publisherFraudDelta;
    private Integer claimantHeartDelta;
    private Integer claimantFraudDelta;
}
