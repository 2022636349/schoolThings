package com.campus.lostfound.modules.announcement.dto;

import lombok.Data;

@Data
public class AnnouncementVO {
    private Long id;
    private String title;
    private String content;
    private String cover;
    private Integer priority;
    private Long createdAt;
}
