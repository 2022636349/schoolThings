package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminTrendVO {
    private String date;
    private Long userCount;
    private Long itemCount;
    private Long reportCount;
}
