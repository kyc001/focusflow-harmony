package com.focus.server.mapper;

import com.focus.server.entity.Project;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface ProjectMapper {
    List<Project> findAll(@Param("userId") Long userId);

    List<Project> findUpdatedSince(@Param("userId") Long userId, @Param("since") Long since);

    Project findById(@Param("id") Long id, @Param("userId") Long userId);

    int insert(Project project);

    int update(Project project);

    int softDelete(@Param("id") Long id, @Param("userId") Long userId, @Param("updatedAt") Long updatedAt);
}

