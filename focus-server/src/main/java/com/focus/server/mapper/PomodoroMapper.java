package com.focus.server.mapper;

import com.focus.server.entity.Pomodoro;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface PomodoroMapper {
    List<Pomodoro> findByRange(@Param("userId") Long userId, @Param("startAt") Long startAt, @Param("endAt") Long endAt);

    List<Pomodoro> findUpdatedSince(@Param("userId") Long userId, @Param("since") Long since);

    Pomodoro findByClientRequestId(@Param("userId") Long userId, @Param("clientRequestId") String clientRequestId);

    int insert(Pomodoro pomodoro);

    int update(Pomodoro pomodoro);

    Integer sumCompletedDuration(@Param("userId") Long userId);

    Integer countByCompleted(@Param("userId") Long userId, @Param("completed") Integer completed);
}
