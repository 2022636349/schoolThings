package com.campus.lostfound.modules.item.dto;

import lombok.Data;

import java.util.List;

@Data
public class ItemPageVO {
    private List<ItemCardVO> list;
    private Long lastId;       // 下一页起点
    private boolean hasMore;
}
