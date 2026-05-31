package com.focus.server.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Task {
    private Long id;
    private Long userId;
    private String title;
    private String note;
    private Long projectId;
    private Integer priority;
    private Long dueAt;
    private Integer status;
    private Integer pomodoroCount;
    private Long createdAt;
    private Long updatedAt;
    private Long completedAt;
    private Integer isDeleted;
    private String clientRequestId;
    private String tagsJson;
    private String subtasksJson;
}

