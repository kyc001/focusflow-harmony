package com.focus.server.mapper;

import com.focus.server.entity.User;
import org.apache.ibatis.annotations.Param;

public interface UserMapper {
    User findByUsername(@Param("username") String username);

    User findById(@Param("id") Long id);

    int insert(User user);
}

