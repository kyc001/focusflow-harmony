package com.focus.server.dto;

import lombok.Data;

@Data
public class TaskRequest {
    private String title;
    private String note;
    private Long projectId;
    private Integer priority;
    private Long dueAt;
    private Integer status;
    private String clientRequestId;
}

