package com.campus.lostfound.modules.claim.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateClaimRequestReq {
    @NotNull(message = "物品不能为空")
    private Long itemId;

    @NotBlank(message = "说明不能为空")
    private String description;
}
