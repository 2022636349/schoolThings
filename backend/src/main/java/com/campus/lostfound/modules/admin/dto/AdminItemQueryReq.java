package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminItemQueryReq {
    private String keyword;
    private String type;
    private String status;
    private Long current = 1L;
    private Long size = 10L;
}
