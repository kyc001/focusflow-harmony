package com.focus.server.controller;

import com.focus.server.common.AuthUser;
import com.focus.server.common.Result;
import com.focus.server.dto.StatsSummary;
import com.focus.server.mapper.PomodoroMapper;
import com.focus.server.mapper.TaskMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/stats")
public class StatsController {
    private final PomodoroMapper pomodoroMapper;
    private final TaskMapper taskMapper;

    public StatsController(PomodoroMapper pomodoroMapper, TaskMapper taskMapper) {
        this.pomodoroMapper = pomodoroMapper;
        this.taskMapper = taskMapper;
    }

    @GetMapping("/summary")
    public Result<StatsSummary> summary(HttpServletRequest servletRequest) {
        Long userId = AuthUser.id(servletRequest);
        int seconds = safe(pomodoroMapper.sumCompletedDuration(userId));
        int completed = safe(pomodoroMapper.countByCompleted(userId, 1));
        int interrupted = safe(pomodoroMapper.countByCompleted(userId, 0));
        long count = taskMapper.count(userId, null, null, null);
        return Result.ok(new StatsSummary(seconds / 60, completed, interrupted, completed > 0 ? 1 : 0, (int) count));
    }

    private int safe(Integer value) {
        return value == null ? 0 : value;
    }
}
