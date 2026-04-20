package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

import java.util.List;

@Data
public class AdminItemVO {
    private Long id;
    private String title;
    private String type;
    private String status;
    private String publisherId;
    private String publisherName;
    private String location;
    private Long createdAt;
    private Long lostTime;
    private Integer likeCount;
    private List<String> images;
}
