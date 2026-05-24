# Focus Server（可选薄同步层）

本后端不是 Focus App 的核心依赖。Focus 的主流程采用鸿蒙端本地优先：RDB + Preferences 即可完成任务、番茄、复盘和游客模式。

保留该服务是为了课程展示：

- Spring Boot + MyBatis + MySQL 工程结构
- 登录 / 注册接口
- 任务、项目、番茄 REST CRUD
- 统计汇总接口
- 增量同步 `pull` / 批量上传 `push`

## 启动

1. 执行 `src/main/resources/init.sql` 初始化 MySQL 数据库 `focus_db`。
2. 修改 `src/main/resources/application.yml` 中的 MySQL 用户名和密码。
3. 启动：

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;D:\Tools\apache-maven-3.9.10\bin;$env:Path"
mvn spring-boot:run
```

## 打包验证

```powershell
mvn -q -DskipTests package
```

已验证可生成：

`target/focus-server-0.0.1-SNAPSHOT.jar`

## 默认约定

- 默认演示用户：`demo`
- 默认密码：`secret`
- 不接入复杂鉴权；接口默认读取请求头 `X-User-Id`，缺省为 `1`
- 这是课程联调用的薄服务，不建议把它作为番茄钟核心体验的强依赖

