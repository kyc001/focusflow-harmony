package com.focus.server.common;

import com.focus.server.config.AuthInterceptor;
import jakarta.servlet.http.HttpServletRequest;

public final class AuthUser {
    private AuthUser() {
    }

    public static Long id(HttpServletRequest request) {
        Object value = request.getAttribute(AuthInterceptor.USER_ID_ATTRIBUTE);
        if (value instanceof Long userId) {
            return userId;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        return 0L;
    }
}
