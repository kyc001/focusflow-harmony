package com.focus.server.controller;

import com.focus.server.common.AuthUser;
import com.focus.server.common.Result;
import com.focus.server.dto.SyncBundle;
import com.focus.server.dto.SyncPushRequest;
import com.focus.server.entity.Pomodoro;
import com.focus.server.entity.Project;
import com.focus.server.entity.Task;
import com.focus.server.mapper.PomodoroMapper;
import com.focus.server.mapper.ProjectMapper;
import com.focus.server.mapper.TaskMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;

@RestController
@RequestMapping("/api/sync")
public class SyncController {
    private final ProjectMapper projectMapper;
    private final TaskMapper taskMapper;
    private final PomodoroMapper pomodoroMapper;

    public SyncController(ProjectMapper projectMapper, TaskMapper taskMapper, PomodoroMapper pomodoroMapper) {
        this.projectMapper = projectMapper;
        this.taskMapper = taskMapper;
        this.pomodoroMapper = pomodoroMapper;
    }

    @PostMapping("/pull")
    public Result<SyncBundle> pull(HttpServletRequest servletRequest,
                                   @RequestParam(value = "since", defaultValue = "0") Long since) {
        Long userId = AuthUser.id(servletRequest);
        SyncBundle bundle = new SyncBundle();
        bundle.setServerTime(System.currentTimeMillis());
        bundle.setProjects(projectMapper.findUpdatedSince(userId, since));
        bundle.setTasks(taskMapper.findUpdatedSince(userId, since));
        bundle.setPomodoros(pomodoroMapper.findUpdatedSince(userId, since));
        return Result.ok(bundle);
    }

    @PostMapping("/push")
    @Transactional
    public Result<SyncBundle> push(HttpServletRequest servletRequest,
                                   @RequestBody SyncPushRequest request) {
        Long userId = AuthUser.id(servletRequest);
        long now = System.currentTimeMillis();
        for (Project project : request.getProjects()) {
            project.setUserId(userId);
            project.setUpdatedAt(project.getUpdatedAt() == null || project.getUpdatedAt() <= 0 ? now : project.getUpdatedAt());
            project.setIsDeleted(project.getIsDeleted() == null ? 0 : project.getIsDeleted());
            Project existing = project.getId() == null ? null : projectMapper.findById(project.getId(), userId);
            if (existing == null) {
                projectMapper.insert(project);
            } else if (existing.getUpdatedAt() == null || existing.getUpdatedAt() <= project.getUpdatedAt()) {
                project.setId(existing.getId());
                projectMapper.update(project);
            }
        }
        for (Task task : request.getTasks()) {
            task.setUserId(userId);
            task.setUpdatedAt(task.getUpdatedAt() == null || task.getUpdatedAt() <= 0 ? now : task.getUpdatedAt());
            task.setCreatedAt(task.getCreatedAt() == null ? now : task.getCreatedAt());
            task.setCompletedAt(task.getCompletedAt() == null ? 0L : task.getCompletedAt());
            task.setPomodoroCount(task.getPomodoroCount() == null ? 0 : task.getPomodoroCount());
            task.setIsDeleted(task.getIsDeleted() == null ? 0 : task.getIsDeleted());
            if (task.getClientRequestId() == null || task.getClientRequestId().trim().isEmpty()) {
                task.setClientRequestId("client-task-" + (task.getId() == null ? now : task.getId()));
            }
            Task existing = taskMapper.findByClientRequestId(userId, task.getClientRequestId());
            if (existing == null && task.getId() != null) {
                existing = taskMapper.findById(task.getId(), userId);
            }
            if (existing == null) {
                taskMapper.insert(task);
            } else if (existing.getUpdatedAt() == null || existing.getUpdatedAt() <= task.getUpdatedAt()) {
                task.setId(existing.getId());
                taskMapper.update(task);
            }
        }
        for (Pomodoro pomodoro : request.getPomodoros()) {
            pomodoro.setUserId(userId);
            pomodoro.setUpdatedAt(pomodoro.getUpdatedAt() == null || pomodoro.getUpdatedAt() <= 0 ? now : pomodoro.getUpdatedAt());
            if (pomodoro.getClientRequestId() == null || pomodoro.getClientRequestId().trim().isEmpty()) {
                pomodoro.setClientRequestId("server-pomo-" + now + "-" + pomodoro.getTaskId() + "-" + pomodoro.getStartAt());
                pomodoroMapper.insert(pomodoro);
                continue;
            }
            Pomodoro existing = pomodoroMapper.findByClientRequestId(userId, pomodoro.getClientRequestId());
            if (existing == null) {
                pomodoroMapper.insert(pomodoro);
            } else if (existing.getUpdatedAt() == null || existing.getUpdatedAt() <= pomodoro.getUpdatedAt()) {
                pomodoro.setId(existing.getId());
                pomodoroMapper.update(pomodoro);
            }
        }
        SyncBundle bundle = new SyncBundle();
        bundle.setServerTime(System.currentTimeMillis());
        bundle.setProjects(new ArrayList<>());
        bundle.setTasks(new ArrayList<>());
        bundle.setPomodoros(new ArrayList<>());
        return Result.ok(bundle);
    }
}
