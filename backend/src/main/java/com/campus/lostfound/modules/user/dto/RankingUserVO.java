package com.campus.lostfound.modules.user.dto;

import lombok.Data;

@Data
public class RankingUserVO {
    private String userId;
    private String name;
    private String avatar;
    private Integer heartValue;
    private Integer returnCount;
}
