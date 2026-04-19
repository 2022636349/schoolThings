# 校园失物招领 - 后端

Spring Boot 3.2 + JDK 17 + MyBatis-Plus + Redis + MinIO + RabbitMQ + JWT。

## 目录结构

```
backend/
├── docker-compose.yml        # 本地中间件一键启动
├── pom.xml                   # Maven 构建
├── sql/
│   └── 01-schema.sql         # 数据库 schema（22 张表）
└── src/main/
    ├── java/com/campus/lostfound/
    │   ├── LostFoundApplication.java
    │   ├── common/           # 通用：Result / Exception / JwtUtil / BaseEntity
    │   ├── config/           # Security / MybatisPlus / Redis 配置
    │   ├── security/         # JWT 过滤器 / EntryPoint / AccessDenied
    │   └── modules/
    │       ├── auth/         # 注册 / 登录 / 验证码 / 刷新 token
    │       ├── user/         # 用户 CRUD
    │       └── system/       # 健康检查
    └── resources/
        ├── application.yml
        └── application-dev.yml
```

## 快速启动

### 1. 启动中间件

```bash
cd backend
docker compose up -d
```

启动后：

| 组件     | 端口       | 账号                          |
|----------|------------|-------------------------------|
| MySQL    | 3306       | root / root123456             |
| Redis    | 6379       | password: redis123            |
| MinIO    | 9000/9001  | minioadmin / minioadmin123    |
| RabbitMQ | 5672/15672 | rabbit / rabbit123            |

MySQL 首次启动会自动执行 `sql/01-schema.sql`，创建 `campus_lostfound` 库及全部表。

### 2. 运行后端

```bash
./mvnw spring-boot:run          # Linux/Mac
mvnw.cmd spring-boot:run        # Windows
```

或用 IDE 直接运行 `LostFoundApplication`。

默认监听 **http://localhost:8080/api** 。

### 3. 验证

```bash
# 健康检查
curl http://localhost:8080/api/system/health

# 发送验证码（开发环境 mock 到日志）
curl -X POST http://localhost:8080/api/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","scene":"register"}'

# 查看 backend 日志，找到形如：
# [SMS MOCK] 手机号=13800138000 场景=register 验证码=123456 有效期=5分钟

# 注册
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456","password":"pass1234","nickname":"小明"}'

# 手机号验证码登录（不存在自动注册）
curl -X POST http://localhost:8080/api/auth/login/sms \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'

# 带上 accessToken 请求受保护接口
curl http://localhost:8080/api/user/me \
  -H "Authorization: Bearer <accessToken>"
```

### 4. 接口文档

- Swagger UI：<http://localhost:8080/api/swagger-ui.html>
- Knife4j：<http://localhost:8080/api/doc.html>

## 响应约定

```json
{
  "code": 0,
  "message": "OK",
  "data": { ... },
  "timestamp": 1713600000000
}
```

`code = 0` 表示成功，非 0 为错误码；详见 `ResultCode`。

## 认证

- access token 有效期 2 小时，放在 `Authorization: Bearer xxx`
- refresh token 有效期 30 天，通过 `/auth/refresh?refreshToken=xxx` 换新
- `/auth/logout` 会吊销当前用户 refresh token

## 白名单路径

无需 token：`/auth/**`、`/system/health`、`/swagger-ui/**`、`/doc.html`。

## 关闭中间件

```bash
docker compose down        # 保留数据卷
docker compose down -v     # 清空数据卷
```

## 后续待接入

- [ ] 物品发布 / 列表 / 详情（item 模块）
- [ ] 认领流程（claim 模块）
- [ ] 一对一聊天（chat 模块 + WebSocket）
- [ ] 通知（notification + RabbitMQ）
- [ ] 文件上传（MinIO 预签名 URL）
- [ ] 管理员后台（announcement / sensitive_word / audit_log）
