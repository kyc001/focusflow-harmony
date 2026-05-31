# Focus Server

本目录是知序项目的正式后端，不是展示用空壳。它参考课程里的学生管理系统后端结构，采用 Spring Boot + MyBatis + 数据库，提供登录、项目、任务、番茄记录、统计和同步接口，支撑“鸿蒙前端 -> 服务器 -> 数据库”的完整数据闭环。

## 技术组成

- Spring Boot 3.2
- MyBatis Mapper + XML SQL
- 启动脚本默认使用 MySQL profile，适合正式数据库演示
- 保留 H2 文件数据库配置，数据落在 `focus-server/data/`，适合快速测试
- `application-mysql.yml` 和 `init-mysql.sql` 用于 MySQL 初始化

## 一键启动

从项目根目录执行：

```powershell
.\start-backend.ps1
```

脚本会使用项目内 `tools/jdk-21` 和 `tools/maven`，自动打包并启动：

`http://localhost:8080`

默认会使用 MySQL，等价于启动时带上：

```text
--spring.profiles.active=mysql
```

首次使用 MySQL 前，请先执行 `src/main/resources/init-mysql.sql`，创建 `focus_db`、表结构和演示账号。如果只是接口测试或课堂快速演示，可切换到 H2：

```powershell
.\start-backend.ps1 -DbProfile h2
```

默认账号：

- 用户名：`demo`
- 密码：`secret`

H2 控制台：

`http://localhost:8080/h2-console`

连接参数：

- JDBC URL：`jdbc:h2:file:./data/focus_db`
- User：`sa`
- Password：留空

## API 闭环

- `POST /api/user/login`：登录
- `POST /api/user/register`：注册
- `GET/POST/PUT/DELETE /api/projects`：项目管理
- `GET/POST/PUT/DELETE /api/tasks`：任务管理
- `GET/POST /api/pomodoros`：番茄记录
- `GET /api/stats/summary`：统计汇总
- `POST /api/sync/pull`：从后端拉取增量数据
- `POST /api/sync/push`：把前端本地 RDB 数据推送到后端数据库

接口默认读取请求头 `X-User-Id`，移动端登录后会保存用户标识并用于同步。

## 验证命令

```powershell
. .\setup-backend-env.ps1
cd focus-server
mvn -q -DskipTests package
java -jar target\focus-server-0.0.1-SNAPSHOT.jar
```

如果遇到 MySQL 未安装或 `focus_db` 不存在，可先用 `.\start-backend.ps1 -DbProfile h2` 完成后端功能验证。
