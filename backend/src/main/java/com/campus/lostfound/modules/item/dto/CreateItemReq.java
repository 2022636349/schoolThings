package com.campus.lostfound.modules.item.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

@Data
public class CreateItemReq {

    @NotBlank(message = "类型不能为空")
    private String type;          // lost / found

    private String title;

    @NotBlank(message = "描述不能为空")
    private String description;

    private String category;
    private String location;
    private String contact;
    private Long lostTime;        // 毫秒

    /** 已上传好的媒体列表 */
    private List<MediaDTO> mediaList;
}
