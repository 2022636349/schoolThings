package com.campus.lostfound.common.util;

import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;

/**
 * 当前登录用户上下文（基于 ThreadLocal）
 */
public class UserContext {

    private static final ThreadLocal<Long> CURRENT_USER_ID = new ThreadLocal<>();

    public static void set(Long userId) {
        CURRENT_USER_ID.set(userId);
    }

    public static Long get() {
        return CURRENT_USER_ID.get();
    }

    public static Long require() {
        Long uid = CURRENT_USER_ID.get();
        if (uid == null) {
            throw new BusinessException(ResultCode.UNAUTHORIZED);
        }
        return uid;
    }

    public static void clear() {
        CURRENT_USER_ID.remove();
    }
}
