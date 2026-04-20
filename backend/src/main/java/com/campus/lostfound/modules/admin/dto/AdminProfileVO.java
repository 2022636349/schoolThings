package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class AdminProfileVO {
    private Long id;
    private String username;
    private String nickname;
    private String role;
}
