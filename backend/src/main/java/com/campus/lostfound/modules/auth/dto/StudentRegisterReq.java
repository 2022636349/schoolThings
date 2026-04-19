package com.campus.lostfound.modules.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class StudentRegisterReq {

    @NotBlank(message = "学号不能为空")
    @Size(min = 4, max = 32)
    private String studentNo;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 64)
    private String password;

    @NotBlank(message = "昵称不能为空")
    private String nickname;

    private String phone;

    /** 可选：如果填了 phone 且填了 code，会校验 */
    private String code;
}
