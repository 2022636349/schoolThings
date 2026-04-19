package com.campus.lostfound.modules.report.dto;

import lombok.Data;

@Data
public class ReportVO {
    private Long id;
    private String targetType;
    private Long targetId;
    private String reporterId;
    private String description;
    private String status;
    private Long createdAt;
}
