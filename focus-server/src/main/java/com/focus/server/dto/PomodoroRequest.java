package com.focus.server.dto;

import lombok.Data;

@Data
public class PomodoroRequest {
    private Long taskId;
    private Long startAt;
    private Integer duration;
    private Integer completed;
    private String interruptReason;
    private String clientRequestId;
}

