package com.focus.server.dto;

import com.focus.server.entity.Pomodoro;
import com.focus.server.entity.Project;
import com.focus.server.entity.Task;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class SyncPushRequest {
    private List<Project> projects = new ArrayList<>();
    private List<Task> tasks = new ArrayList<>();
    private List<Pomodoro> pomodoros = new ArrayList<>();
}

