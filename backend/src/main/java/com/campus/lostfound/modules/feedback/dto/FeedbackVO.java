package com.campus.lostfound.modules.feedback.dto;

import lombok.Data;

@Data
public class FeedbackVO {
    private Long id;
    private String content;
    private String reply;
    private Long createdAt;
}
