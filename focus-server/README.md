# Focus Server

本目录是知序项目的正式后端，不是展示用空壳。它参考课程里的学生管理系统后端结构，采用 Spring Boot + MyBatis + 数据库，提供登录、项目、任务、番茄记录、统计和同步接口，支撑“鸿蒙前端 -> 服务器 -> 数据库”的完整数据闭环。

## 技术组成

- Spring Boot 3.2
- MyBatis Mapper + XML SQL
- JWT 登录鉴权
- Swagger / OpenAPI 接口文档
- 启动脚本默认使用 MySQL profile，适合正式数据库演示
- 保留 H2 文件数据库配置，数据落在 `focus-server/data/`，适合快速测试
- `application-mysql.yml` 和 `init-mysql.sql` 用于 MySQL 初始化

## 一键启动

从项目根目录执行：

```powershell
.\start-backend.ps1
```

脚本会自动选择可用 JDK，并使用项目内 `tools/maven` 自动打包和启动：

`http://localhost:8080`

默认会使用 MySQL，等价于启动时带上：

```text
--spring.profiles.active=mysql
```

首次使用 MySQL 前，请先执行 `src/main/resources/init-mysql.sql`，创建 `focus_db`、表结构和演示账号。如果只是接口测试或课堂快速演示，可切换到 H2：

如果本机 MySQL 不是空密码 root 账号，请在项目根目录 `.env` 中配置：

```text
MYSQL_URL=jdbc:mysql://localhost:3306/focus_db?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai
MYSQL_USERNAME=root
MYSQL_PASSWORD=your-local-password
FOCUS_JWT_SECRET=replace-with-a-local-dev-secret
FOCUS_JWT_EXPIRE_SECONDS=604800
```

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

`/api/user/login` 和 `/api/user/register` 会返回 JWT。除登录、注册和 `/api/user/ping` 外，业务接口需要携带：

```text
Authorization: Bearer <token>
```

Swagger 调试页：

```text
http://localhost:8080/swagger-ui.html
```

## 验证命令

```powershell
. .\setup-backend-env.ps1
cd focus-server
mvn -q -DskipTests package
java -jar target\focus-server-0.0.1-SNAPSHOT.jar
```

如果遇到 MySQL 未安装或 `focus_db` 不存在，可先用 `.\start-backend.ps1 -DbProfile h2` 完成后端功能验证。
