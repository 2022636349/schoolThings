package com.campus.lostfound.modules.auth.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class TokenVO {
    private Long userId;
    private String nickname;
    private String avatar;
    private String accessToken;
    private String refreshToken;
    private long expiresIn; // 秒
    private String tokenType;
}
