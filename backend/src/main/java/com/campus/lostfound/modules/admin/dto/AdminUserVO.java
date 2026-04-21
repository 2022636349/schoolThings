package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminUserVO {
    private Long id;
    private String studentNo;
    private String nickname;
    private String phone;
    private Integer status;
    private Long createdAt;
    private Integer heartValue;
    private Integer fraudValue;
    private Integer postCount;
    private Integer returnCount;
    private Integer likeReceived;
}
