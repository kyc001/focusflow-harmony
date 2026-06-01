package com.focus.server.controller;

import com.focus.server.common.AuthUser;
import com.focus.server.common.PageResult;
import com.focus.server.common.Result;
import com.focus.server.dto.TaskRequest;
import com.focus.server.entity.Task;
import com.focus.server.mapper.TaskMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {
    private final TaskMapper taskMapper;

    public TaskController(TaskMapper taskMapper) {
        this.taskMapper = taskMapper;
    }

    @GetMapping
    public Result<PageResult<Task>> list(HttpServletRequest servletRequest,
                                         @RequestParam(value = "keyword", required = false) String keyword,
                                         @RequestParam(value = "status", required = false) Integer status,
                                         @RequestParam(value = "projectId", required = false) Long projectId,
                                         @RequestParam(value = "page", defaultValue = "1") Integer page,
                                         @RequestParam(value = "pageSize", defaultValue = "20") Integer pageSize) {
        Long userId = AuthUser.id(servletRequest);
        int offset = Math.max(0, page - 1) * pageSize;
        List<Task> list = taskMapper.findPage(userId, keyword, status, projectId, offset, pageSize);
        Long total = taskMapper.count(userId, keyword, status, projectId);
        return Result.ok(new PageResult<>(list, page, pageSize, total));
    }

    @GetMapping("/{id}")
    public Result<Task> detail(HttpServletRequest servletRequest,
                               @PathVariable Long id) {
        Long userId = AuthUser.id(servletRequest);
        Task task = taskMapper.findById(id, userId);
        return task == null ? Result.fail("task not found") : Result.ok(task);
    }

    @PostMapping
    public Result<Task> create(HttpServletRequest servletRequest,
                               @RequestBody TaskRequest request) {
        Long userId = AuthUser.id(servletRequest);
        if (request.getClientRequestId() != null) {
            Task existing = taskMapper.findByClientRequestId(userId, request.getClientRequestId());
            if (existing != null) {
                return Result.ok(existing);
            }
        }
        long now = System.currentTimeMillis();
        Task task = new Task();
        applyRequest(task, request);
        task.setUserId(userId);
        task.setPomodoroCount(0);
        task.setCreatedAt(now);
        task.setUpdatedAt(now);
        task.setCompletedAt(0L);
        task.setIsDeleted(0);
        taskMapper.insert(task);
        return Result.ok(task);
    }

    @PutMapping("/{id}")
    public Result<Task> update(HttpServletRequest servletRequest,
                               @PathVariable Long id,
                               @RequestBody TaskRequest request) {
        Long userId = AuthUser.id(servletRequest);
        Task task = taskMapper.findById(id, userId);
        if (task == null) {
            return Result.fail("task not found");
        }
        applyRequest(task, request);
        task.setUpdatedAt(System.currentTimeMillis());
        if (task.getStatus() != null && task.getStatus() == 1) {
            task.setCompletedAt(System.currentTimeMillis());
        }
        taskMapper.update(task);
        return Result.ok(task);
    }

    @DeleteMapping("/{id}")
    public Result<Boolean> delete(HttpServletRequest servletRequest,
                                  @PathVariable Long id) {
        Long userId = AuthUser.id(servletRequest);
        taskMapper.softDelete(id, userId, System.currentTimeMillis());
        return Result.ok(true);
    }

    private void applyRequest(Task task, TaskRequest request) {
        task.setTitle(request.getTitle());
        task.setNote(request.getNote());
        task.setProjectId(request.getProjectId());
        task.setPriority(request.getPriority() == null ? 0 : request.getPriority());
        task.setDueAt(request.getDueAt() == null ? 0L : request.getDueAt());
        task.setStatus(request.getStatus() == null ? 0 : request.getStatus());
        task.setClientRequestId(request.getClientRequestId());
    }
}
