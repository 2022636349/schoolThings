package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminUserQueryReq {
    private String keyword;
    private Integer status;
    private Long current = 1L;
    private Long size = 10L;
}
