package com.campus.lostfound.common.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * JWT 工具
 */
@Slf4j
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-expire-minutes:120}")
    private long accessExpireMinutes;

    @Value("${jwt.refresh-expire-days:30}")
    private long refreshExpireDays;

    @Value("${jwt.issuer:campus-lostfound}")
    private String issuer;

    private SecretKey signingKey;

    @PostConstruct
    public void init() {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateAccessToken(Long userId, String nickname) {
        return buildToken(userId, nickname, "access", "user", accessExpireMinutes * 60 * 1000L);
    }

    public String generateAdminAccessToken(Long adminId, String username, String role) {
        return buildToken(adminId, username, "access", role == null ? "admin" : role, accessExpireMinutes * 60 * 1000L);
    }

    public String generateRefreshToken(Long userId) {
        return buildToken(userId, null, "refresh", "user", refreshExpireDays * 24 * 60 * 60 * 1000L);
    }

    private String buildToken(Long userId, String nickname, String type, String role, long ttlMillis) {
        Date now = new Date();
        Date exp = new Date(now.getTime() + ttlMillis);
        Map<String, Object> claims = new HashMap<>();
        claims.put("uid", userId);
        claims.put("type", type);
        claims.put("role", role);
        if (nickname != null) {
            claims.put("nickname", nickname);
        }
        return Jwts.builder()
                .claims(claims)
                .subject(String.valueOf(userId))
                .issuer(issuer)
                .issuedAt(now)
                .expiration(exp)
                .signWith(signingKey)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long getUserId(String token) {
        Claims c = parse(token);
        Object uid = c.get("uid");
        if (uid instanceof Integer i) return i.longValue();
        if (uid instanceof Long l) return l;
        return Long.parseLong(String.valueOf(uid));
    }

    public boolean isValid(String token) {
        try {
            parse(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.debug("token expired");
            return false;
        } catch (Exception e) {
            log.debug("token invalid: {}", e.getMessage());
            return false;
        }
    }

    public String getRole(String token) {
        Object role = parse(token).get("role");
        return role == null ? "user" : String.valueOf(role);
    }

    public long getAccessExpireSeconds() {
        return accessExpireMinutes * 60L;
    }
}
