package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

@Data
public class ChangeAdminPasswordReq {
    private String oldPassword;
    private String newPassword;
}
