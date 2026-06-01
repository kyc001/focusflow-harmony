package com.focus.server.controller;

import com.focus.server.common.HashUtil;
import com.focus.server.common.Result;
import com.focus.server.dto.AuthResponse;
import com.focus.server.dto.LoginRequest;
import com.focus.server.dto.RegisterRequest;
import com.focus.server.entity.User;
import com.focus.server.mapper.UserMapper;
import com.focus.server.service.JwtService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user")
public class UserController {
    private final UserMapper userMapper;
    private final JwtService jwtService;

    public UserController(UserMapper userMapper, JwtService jwtService) {
        this.userMapper = userMapper;
        this.jwtService = jwtService;
    }

    @GetMapping("/ping")
    public Result<String> ping() {
        return Result.ok("pong");
    }

    @PostMapping("/register")
    public Result<AuthResponse> register(@RequestBody RegisterRequest request) {
        if (request.getUsername() == null || request.getPassword() == null) {
            return Result.fail("username and password required");
        }
        if (userMapper.findByUsername(request.getUsername()) != null) {
            return Result.fail("username exists");
        }
        User user = new User();
        user.setUsername(request.getUsername());
        user.setPasswordHash(HashUtil.sha256(request.getPassword()));
        user.setNickname(request.getNickname() == null || request.getNickname().isBlank() ? request.getUsername() : request.getNickname());
        user.setCreatedAt(System.currentTimeMillis());
        userMapper.insert(user);
        return Result.ok(toAuth(user));
    }

    @PostMapping("/login")
    public Result<AuthResponse> login(@RequestBody LoginRequest request) {
        return loginByCredential(request.getUsername(), request.getPassword());
    }

    private Result<AuthResponse> loginByCredential(String username, String password) {
        if (username == null || password == null) {
            return Result.fail("username and password required");
        }
        User user = userMapper.findByUsername(username);
        if (user == null || !user.getPasswordHash().equals(HashUtil.sha256(password))) {
            return Result.fail("invalid username or password");
        }
        return Result.ok(toAuth(user));
    }

    private AuthResponse toAuth(User user) {
        return new AuthResponse(user.getId(), user.getUsername(), user.getNickname(), jwtService.createToken(user.getId(), user.getUsername()));
    }
}
