package com.focus.server.controller;

import com.focus.server.common.Result;
import com.focus.server.dto.PomodoroRequest;
import com.focus.server.entity.Pomodoro;
import com.focus.server.mapper.PomodoroMapper;
import com.focus.server.mapper.TaskMapper;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pomodoros")
public class PomodoroController {
    private final PomodoroMapper pomodoroMapper;
    private final TaskMapper taskMapper;

    public PomodoroController(PomodoroMapper pomodoroMapper, TaskMapper taskMapper) {
        this.pomodoroMapper = pomodoroMapper;
        this.taskMapper = taskMapper;
    }

    @GetMapping
    public Result<List<Pomodoro>> list(@RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
                                       @RequestParam(value = "startAt", defaultValue = "0") Long startAt,
                                       @RequestParam(value = "endAt", required = false) Long endAt) {
        long end = endAt == null ? System.currentTimeMillis() : endAt;
        return Result.ok(pomodoroMapper.findByRange(userId, startAt, end));
    }

    @PostMapping
    public Result<Pomodoro> create(@RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
                                   @RequestBody PomodoroRequest request) {
        if (request.getClientRequestId() != null) {
            Pomodoro existing = pomodoroMapper.findByClientRequestId(userId, request.getClientRequestId());
            if (existing != null) {
                return Result.ok(existing);
            }
        }
        Pomodoro pomodoro = new Pomodoro();
        pomodoro.setUserId(userId);
        pomodoro.setTaskId(request.getTaskId());
        pomodoro.setStartAt(request.getStartAt() == null ? System.currentTimeMillis() : request.getStartAt());
        pomodoro.setDuration(request.getDuration() == null ? 0 : request.getDuration());
        pomodoro.setCompleted(request.getCompleted() == null ? 0 : request.getCompleted());
        pomodoro.setInterruptReason(request.getInterruptReason());
        pomodoro.setUpdatedAt(System.currentTimeMillis());
        pomodoro.setClientRequestId(request.getClientRequestId());
        pomodoroMapper.insert(pomodoro);
        if (pomodoro.getCompleted() == 1 && pomodoro.getTaskId() != null) {
            taskMapper.increasePomodoro(pomodoro.getTaskId(), userId, System.currentTimeMillis());
        }
        return Result.ok(pomodoro);
    }
}

