package com.campus.lostfound.modules.feedback.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateFeedbackReq {
    @NotBlank(message = "反馈内容不能为空")
    private String content;
}
