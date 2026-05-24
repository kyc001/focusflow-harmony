package com.focus.server.dto;

import com.focus.server.entity.Pomodoro;
import com.focus.server.entity.Project;
import com.focus.server.entity.Task;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SyncBundle {
    private Long serverTime;
    private List<Project> projects = new ArrayList<>();
    private List<Task> tasks = new ArrayList<>();
    private List<Pomodoro> pomodoros = new ArrayList<>();
}

