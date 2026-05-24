package com.focus.server.controller;

import com.focus.server.common.Result;
import com.focus.server.dto.ProjectRequest;
import com.focus.server.entity.Project;
import com.focus.server.mapper.ProjectMapper;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/projects")
public class ProjectController {
    private final ProjectMapper projectMapper;

    public ProjectController(ProjectMapper projectMapper) {
        this.projectMapper = projectMapper;
    }

    @GetMapping
    public Result<List<Project>> list(@RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return Result.ok(projectMapper.findAll(userId));
    }

    @PostMapping
    public Result<Project> create(@RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
                                  @RequestBody ProjectRequest request) {
        Project project = new Project();
        project.setUserId(userId);
        project.setName(request.getName());
        project.setColor(request.getColor() == null ? "#2F6BFF" : request.getColor());
        project.setIcon(request.getIcon() == null ? "P" : request.getIcon());
        project.setUpdatedAt(System.currentTimeMillis());
        project.setIsDeleted(0);
        projectMapper.insert(project);
        return Result.ok(project);
    }

    @PutMapping("/{id}")
    public Result<Project> update(@RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
                                  @PathVariable Long id,
                                  @RequestBody ProjectRequest request) {
        Project project = projectMapper.findById(id, userId);
        if (project == null) {
            return Result.fail("project not found");
        }
        project.setName(request.getName());
        project.setColor(request.getColor());
        project.setIcon(request.getIcon());
        project.setUpdatedAt(System.currentTimeMillis());
        projectMapper.update(project);
        return Result.ok(project);
    }

    @DeleteMapping("/{id}")
    public Result<Boolean> delete(@RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
                                  @PathVariable Long id) {
        projectMapper.softDelete(id, userId, System.currentTimeMillis());
        return Result.ok(true);
    }
}

