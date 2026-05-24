package com.focus.server.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StatsSummary {
    private Integer totalMinutes;
    private Integer completedPomodoros;
    private Integer interruptedPomodoros;
    private Integer streakDays;
    private Integer taskCount;
}

