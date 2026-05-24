package com.focus.server.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Project {
    private Long id;
    private Long userId;
    private String name;
    private String color;
    private String icon;
    private Long updatedAt;
    private Integer isDeleted;
}

