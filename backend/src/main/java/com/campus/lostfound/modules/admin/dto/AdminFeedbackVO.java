package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminFeedbackVO {
    private Long id;
    private String userId;
    private String userName;
    private String content;
    private String result;
    private Long createdAt;
}
