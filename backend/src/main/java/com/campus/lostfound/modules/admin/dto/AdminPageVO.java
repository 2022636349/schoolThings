package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

import java.util.List;

@Data
public class AdminPageVO<T> {
    private Long total;
    private Long current;
    private Long size;
    private List<T> records;
}
