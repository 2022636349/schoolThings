package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class SaveAnnouncementReq {
    private Long id;
    private String title;
    private String content;
    private String cover;
    private Integer priority;
    private String status;
    private Long publishFrom;
    private Long publishTo;
}
