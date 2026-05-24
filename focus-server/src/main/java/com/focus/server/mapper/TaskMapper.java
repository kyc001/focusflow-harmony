package com.focus.server.mapper;

import com.focus.server.entity.Task;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface TaskMapper {
    List<Task> findPage(@Param("userId") Long userId, @Param("keyword") String keyword,
                        @Param("status") Integer status, @Param("projectId") Long projectId,
                        @Param("offset") Integer offset, @Param("pageSize") Integer pageSize);

    Long count(@Param("userId") Long userId, @Param("keyword") String keyword,
               @Param("status") Integer status, @Param("projectId") Long projectId);

    List<Task> findUpdatedSince(@Param("userId") Long userId, @Param("since") Long since);

    Task findById(@Param("id") Long id, @Param("userId") Long userId);

    Task findByClientRequestId(@Param("userId") Long userId, @Param("clientRequestId") String clientRequestId);

    int insert(Task task);

    int update(Task task);

    int softDelete(@Param("id") Long id, @Param("userId") Long userId, @Param("updatedAt") Long updatedAt);

    int increasePomodoro(@Param("id") Long id, @Param("userId") Long userId, @Param("updatedAt") Long updatedAt);
}

