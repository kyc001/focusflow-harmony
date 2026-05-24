package com.focus.server.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Pomodoro {
    private Long id;
    private Long userId;
    private Long taskId;
    private Long startAt;
    private Integer duration;
    private Integer completed;
    private String interruptReason;
    private Long updatedAt;
    private String clientRequestId;
}

