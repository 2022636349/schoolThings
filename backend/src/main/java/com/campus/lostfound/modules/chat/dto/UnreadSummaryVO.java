package com.campus.lostfound.modules.chat.dto;

import lombok.Data;

@Data
public class UnreadSummaryVO {
    private int count;
    private String latest;
}
