package com.focus.server.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class JwtService {
    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder URL_DECODER = Base64.getUrlDecoder();

    private final ObjectMapper objectMapper;
    private final byte[] secret;
    private final long expireSeconds;

    public JwtService(ObjectMapper objectMapper,
                      @Value("${focus.jwt.secret:focus-dev-secret-change-me}") String secret,
                      @Value("${focus.jwt.expire-seconds:604800}") long expireSeconds) {
        this.objectMapper = objectMapper;
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.expireSeconds = expireSeconds;
    }

    public String createToken(Long userId, String username) {
        long now = Instant.now().getEpochSecond();
        Map<String, Object> header = new LinkedHashMap<>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("sub", String.valueOf(userId));
        payload.put("username", username);
        payload.put("iat", now);
        payload.put("exp", now + expireSeconds);

        String encodedHeader = encodeJson(header);
        String encodedPayload = encodeJson(payload);
        String unsignedToken = encodedHeader + "." + encodedPayload;
        return unsignedToken + "." + sign(unsignedToken);
    }

    public Long verifyAndGetUserId(String token) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("missing token");
        }
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            throw new IllegalArgumentException("invalid token");
        }
        String unsignedToken = parts[0] + "." + parts[1];
        String expectedSignature = sign(unsignedToken);
        if (!constantTimeEquals(expectedSignature, parts[2])) {
            throw new IllegalArgumentException("invalid signature");
        }
        try {
            JsonNode payload = objectMapper.readTree(URL_DECODER.decode(parts[1]));
            long exp = payload.path("exp").asLong(0L);
            if (exp <= Instant.now().getEpochSecond()) {
                throw new IllegalArgumentException("token expired");
            }
            long userId = payload.path("sub").asLong(0L);
            if (userId <= 0) {
                throw new IllegalArgumentException("missing subject");
            }
            return userId;
        } catch (IllegalArgumentException err) {
            throw err;
        } catch (Exception err) {
            throw new IllegalArgumentException("invalid payload", err);
        }
    }

    private String encodeJson(Map<String, Object> value) {
        try {
            return URL_ENCODER.encodeToString(objectMapper.writeValueAsBytes(value));
        } catch (Exception err) {
            throw new IllegalStateException("failed to encode jwt", err);
        }
    }

    private String sign(String value) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret, HMAC_ALGORITHM));
            return URL_ENCODER.encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception err) {
            throw new IllegalStateException("failed to sign jwt", err);
        }
    }

    private boolean constantTimeEquals(String left, String right) {
        byte[] leftBytes = left.getBytes(StandardCharsets.UTF_8);
        byte[] rightBytes = right.getBytes(StandardCharsets.UTF_8);
        int diff = leftBytes.length ^ rightBytes.length;
        int length = Math.min(leftBytes.length, rightBytes.length);
        for (int i = 0; i < length; i++) {
            diff |= leftBytes[i] ^ rightBytes[i];
        }
        return diff == 0;
    }
}
