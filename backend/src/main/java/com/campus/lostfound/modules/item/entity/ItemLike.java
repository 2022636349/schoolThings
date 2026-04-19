package com.campus.lostfound.modules.item.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("item_like")
public class ItemLike implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long itemId;
    private Long userId;
    private LocalDateTime createdAt;
}
