package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminAnnouncementVO {
    private Long id;
    private String title;
    private String content;
    private String cover;
    private String status;
    private Integer priority;
    private Long publishFrom;
    private Long publishTo;
    private Long createdAt;
    private Integer viewCount;
}
