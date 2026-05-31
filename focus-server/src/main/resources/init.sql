CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(32) NOT NULL UNIQUE,
  password_hash VARCHAR(128) NOT NULL,
  nickname VARCHAR(32) NOT NULL,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS projects (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  name VARCHAR(64) NOT NULL,
  color VARCHAR(16) NOT NULL,
  icon VARCHAR(16) NOT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_projects_user_updated ON projects (user_id, updated_at);

CREATE TABLE IF NOT EXISTS tasks (
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
  subtasks_json TEXT
);
CREATE INDEX IF NOT EXISTS idx_tasks_user_updated ON tasks (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON tasks (user_id, status);

CREATE TABLE IF NOT EXISTS pomodoros (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  task_id BIGINT,
  start_at BIGINT NOT NULL,
  duration INT NOT NULL,
  completed TINYINT NOT NULL,
  interrupt_reason VARCHAR(128),
  updated_at BIGINT NOT NULL,
  client_request_id VARCHAR(64)
);
CREATE INDEX IF NOT EXISTS idx_pomodoros_user_start ON pomodoros (user_id, start_at);
CREATE INDEX IF NOT EXISTS idx_pomodoros_user_updated ON pomodoros (user_id, updated_at);

INSERT INTO users (id, username, password_hash, nickname, created_at)
SELECT 1, 'demo', '2bb80d537b1da3e38bd30361aa855686bde0eacd7162fef6a25fe97bf527a25b', 'Focus Demo', DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP())
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);

INSERT INTO projects (id, user_id, name, color, icon, updated_at, is_deleted)
SELECT 1, 1, '数据库', '#4F7BFF', 'DB', DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE id = 1);
INSERT INTO projects (id, user_id, name, color, icon, updated_at, is_deleted)
SELECT 2, 1, '科研', '#12A87D', 'R', DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE id = 2);
INSERT INTO projects (id, user_id, name, color, icon, updated_at, is_deleted)
SELECT 3, 1, '协程演讲', '#F59E0B', 'P', DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE id = 3);
INSERT INTO projects (id, user_id, name, color, icon, updated_at, is_deleted)
SELECT 4, 1, '移动开发', '#E4566E', 'A', DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE id = 4);

INSERT INTO tasks (id, user_id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted, tags_json, subtasks_json)
SELECT 1, 1, '完成 HW4 实验报告复盘', '整理接口、页面和测试截图。', 4, 0, DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()) + 14400000, 0, 1, DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0, 0, '["报告","高优"]', '["补充架构图","标注关键代码"]'
WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE id = 1);
INSERT INTO tasks (id, user_id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted, tags_json, subtasks_json)
SELECT 2, 1, '数据库索引章节总结', '复习 B+ 树和查询优化。', 1, 1, DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()) + 86400000, 0, 2, DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0, 0, '["期末","笔记"]', '["画一张思维导图"]'
WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE id = 2);
INSERT INTO tasks (id, user_id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted, tags_json, subtasks_json)
SELECT 3, 1, '协程演讲 Demo 排练', '控制在 6 分钟内。', 3, 2, DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()) + 172800000, 0, 0, DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), DATEDIFF('MILLISECOND', TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP()), 0, 0, '["展示"]', '["检查录屏","压缩 PPT"]'
WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE id = 3);
