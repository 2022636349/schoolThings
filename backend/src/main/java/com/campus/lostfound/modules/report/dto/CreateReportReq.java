package com.campus.lostfound.modules.report.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateReportReq {
    @NotNull(message = "目标不能为空")
    private Long targetId;

    @NotBlank(message = "目标类型不能为空")
    private String targetType;

    @NotBlank(message = "说明不能为空")
    private String description;
}
