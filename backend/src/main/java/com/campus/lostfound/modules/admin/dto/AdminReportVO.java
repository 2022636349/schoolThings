package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminReportVO {
    private Long id;
    private String targetType;
    private Long targetId;
    private String targetTitle;
    private String reporterId;
    private String reporterStudentNo;
    private String reporterName;
    private String reporterPhone;
    private String publisherId;
    private String publisherStudentNo;
    private String publisherName;
    private String publisherPhone;
    private String claimantId;
    private String claimantStudentNo;
    private String claimantName;
    private String claimantPhone;
    private String reason;
    private String description;
    private String evidenceUrls;
    private String status;
    private String resolution;
    private Integer reporterHeartValue;
    private Integer reporterFraudValue;
    private Integer publisherHeartValue;
    private Integer publisherFraudValue;
    private Integer claimantHeartValue;
    private Integer claimantFraudValue;
    private Long createdAt;
}
