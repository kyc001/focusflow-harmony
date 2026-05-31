CREATE DATABASE IF NOT EXISTS focus_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE focus_db;

DROP TABLE IF EXISTS sync_changes;
DROP TABLE IF EXISTS pomodoros;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(32) NOT NULL UNIQUE,
  password_hash VARCHAR(128) NOT NULL,
  nickname VARCHAR(32) NOT NULL,
  created_at BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE projects (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  name VARCHAR(64) NOT NULL,
  color VARCHAR(16) NOT NULL,
  icon VARCHAR(16) NOT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT NOT NULL DEFAULT 0,
  INDEX idx_projects_user_updated (user_id, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tasks (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  title VARCHAR(128) NOT NULL,
  note TEXT,
  project_id BIGINT,
  priority TINYINT NOT NULL DEFAULT 0,
  due_at BIGINT NOT NULL DEFAULT 0,
  status TINYINT NOT NULL DEFAULT 0,
  pomodoro_count INT NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  completed_at BIGINT NOT NULL DEFAULT 0,
  is_deleted TINYINT NOT NULL DEFAULT 0,
  client_request_id VARCHAR(64),
  tags_json TEXT,
  subtasks_json TEXT,
  INDEX idx_tasks_user_updated (user_id, updated_at),
  INDEX idx_tasks_user_status (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pomodoros (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  task_id BIGINT,
  start_at BIGINT NOT NULL,
  duration INT NOT NULL,
  completed TINYINT NOT NULL,
  interrupt_reason VARCHAR(128),
  updated_at BIGINT NOT NULL,
  client_request_id VARCHAR(64),
  INDEX idx_pomodoros_user_start (user_id, start_at),
  INDEX idx_pomodoros_user_updated (user_id, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO users (username, password_hash, nickname, created_at)
VALUES ('demo', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Focus Demo', UNIX_TIMESTAMP() * 1000);

INSERT INTO projects (user_id, name, color, icon, updated_at, is_deleted) VALUES
(1, '数据库', '#4F7BFF', 'DB', UNIX_TIMESTAMP() * 1000, 0),
(1, '科研', '#12A87D', 'R', UNIX_TIMESTAMP() * 1000, 0),
(1, '协程演讲', '#F59E0B', 'P', UNIX_TIMESTAMP() * 1000, 0),
(1, '移动开发', '#E4566E', 'A', UNIX_TIMESTAMP() * 1000, 0);

INSERT INTO tasks (user_id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted)
VALUES
(1, '完成 HW4 实验报告复盘', '整理接口、页面和测试截图。', 4, 0, UNIX_TIMESTAMP() * 1000 + 14400000, 0, 1, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0, 0),
(1, '数据库索引章节总结', '复习 B+ 树和查询优化。', 1, 1, UNIX_TIMESTAMP() * 1000 + 86400000, 0, 2, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0, 0),
(1, '协程演讲 Demo 排练', '控制在 6 分钟内。', 3, 2, UNIX_TIMESTAMP() * 1000 + 172800000, 0, 0, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0, 0);

