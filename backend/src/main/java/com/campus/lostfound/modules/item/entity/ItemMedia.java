package com.campus.lostfound.modules.item.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("item_media")
public class ItemMedia implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long itemId;
    private String type;    // image / video
    private String url;
    private Integer sort;
    private Integer width;
    private Integer height;
    private Integer sizeKb;
    private LocalDateTime createdAt;
}
