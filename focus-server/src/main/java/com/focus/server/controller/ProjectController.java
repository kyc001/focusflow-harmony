package com.focus.server.controller;

import com.focus.server.common.AuthUser;
import com.focus.server.common.Result;
import com.focus.server.dto.ProjectRequest;
import com.focus.server.entity.Project;
import com.focus.server.mapper.ProjectMapper;
import jakarta.servlet.http.HttpServletRequest;
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
    public Result<List<Project>> list(HttpServletRequest servletRequest) {
        Long userId = AuthUser.id(servletRequest);
        return Result.ok(projectMapper.findAll(userId));
    }

    @PostMapping
    public Result<Project> create(HttpServletRequest servletRequest,
                                  @RequestBody ProjectRequest request) {
        Long userId = AuthUser.id(servletRequest);
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
    public Result<Project> update(HttpServletRequest servletRequest,
                                  @PathVariable Long id,
                                  @RequestBody ProjectRequest request) {
        Long userId = AuthUser.id(servletRequest);
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
    public Result<Boolean> delete(HttpServletRequest servletRequest,
                                  @PathVariable Long id) {
        Long userId = AuthUser.id(servletRequest);
        projectMapper.softDelete(id, userId, System.currentTimeMillis());
        return Result.ok(true);
    }
}
