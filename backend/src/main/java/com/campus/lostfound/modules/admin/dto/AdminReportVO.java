package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminReportVO {
    private Long id;
    private String targetType;
    private Long targetId;
    private String targetTitle;
    private String reporterId;
    private String reporterName;
    private String reason;
    private String description;
    private String evidenceUrls;
    private String status;
    private String resolution;
    private Long createdAt;
}
