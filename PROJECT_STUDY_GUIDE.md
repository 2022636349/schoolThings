# 校园失物招领系统项目学习指南

> 适用目录：`E:\school`
>
> 本文档的目标不是机械罗列每一个 getter / setter，而是帮助你**真正学会整个项目**：
> - 先理解整体架构
> - 再理解各模块功能
> - 然后看核心代码链路
> - 最后知道应该从哪些类、函数、接口入手继续深入

---

# 1. 项目整体认识

这个项目是一个**校园失物招领系统**，采用三端结构：

1. **HarmonyOS / ArkTS APP**
   - 面向学生用户
   - 负责登录注册、浏览物品、发布物品、聊天联系、提交异议、个人中心等

2. **Spring Boot 后端**
   - 提供统一 REST API
   - 负责用户认证、物品数据、聊天、公告、异议处理、反馈、后台管理等

3. **Vue 后台管理系统**
   - 面向管理员
   - 负责用户管理、帖子管理、公告管理、异议处理、反馈处理、会话查看、仪表盘统计等

> 当前仓库**没有真正的小程序代码**。用户侧客户端实际是 HarmonyOS APP。

---

# 2. 目录结构速览

## 2.1 APP 目录

```text
Application/
  entry/
    src/main/ets/
      common/        通用基础能力（配置、HTTP、Session）
      components/    可复用组件
      model/         前端数据模型
      pages/         页面
      services/      调后端接口的服务层
      entryability/  应用入口 Ability
      entryformability/ 桌面卡片 Form Ability
      widget/        卡片页面
```

## 2.2 后端目录

```text
backend/
  src/main/java/com/campus/lostfound/
    common/      公共响应、异常、工具类
    config/      Spring / Security / MinIO / Redis 等配置
    security/    JWT 认证过滤器与鉴权处理
    modules/
      auth/
      user/
      item/
      chat/
      report/
      announcement/
      feedback/
      admin/
      upload/
      system/
  sql/
    01-schema.sql
```

## 2.3 后台目录

```text
admin-web/
  src/
    api/      Axios API 封装
    router/   路由
    stores/   Pinia 状态
    views/    页面
```

---

# 3. 技术栈

## 3.1 APP 端

- ArkTS
- ArkUI
- HarmonyOS Ability
- Preferences 本地存储
- NotificationKit
- PushKit
- FormKit（桌面卡片）
- BackgroundTasksKit
- PhotoViewPicker / FilePicker

## 3.2 后端

- Spring Boot 3.x
- Spring Security
- JWT
- MyBatis-Plus
- Redis
- MinIO
- RabbitMQ（依赖已接入，当前业务侧使用较少）
- Knife4j / OpenAPI

## 3.3 后台前端

- Vue 3
- TypeScript
- Vite
- Element Plus
- Pinia
- Vue Router
- Axios

---

# 4. 运行方式（你平时调试最常用）

## 4.1 后端

启动类：

```text
backend/src/main/java/com/campus/lostfound/LostFoundApplication.java
```

开发配置：

```text
backend/src/main/resources/application-dev.yml
```

关键配置：
- MySQL
- Redis
- RabbitMQ
- MinIO

## 4.2 APP

入口：

```text
Application/entry/src/main/ets/entryability/EntryAbility.ets
```

页面注册：

```text
Application/entry/src/main/resources/base/profile/main_pages.json
```

模块配置：

```text
Application/entry/src/main/module.json5
```

## 4.3 后台前端

入口：

```text
admin-web/src/main.ts
```

HTTP 基础地址：

```text
admin-web/src/api/http.ts
```

默认：

```ts
VITE_API_BASE_URL || 'http://localhost:8080/api'
```

---

# 5. 学习整个项目的最佳顺序

如果你想真正学会这个项目，建议按这个顺序看：

1. **登录链路**
2. **物品发布链路**
3. **大厅列表与详情链路**
4. **聊天链路**
5. **异议处理链路**
6. **后台管理链路**
7. **桌面卡片与通知链路**

这是因为这几条链路基本覆盖了：
- 用户
- 物品
- 互动
- 管理
- 平台能力

---

# 6. APP 模块详解

---

## 6.1 启动与首页壳子

### 作用
决定 APP 启动进哪个页面，以及整体底部导航/平板布局。

### 关键文件

- `Application/entry/src/main/ets/entryability/EntryAbility.ets`
- `Application/entry/src/main/ets/pages/HomePage.ets`

### EntryAbility 的作用

它是 APP 真正入口。

主要函数：

#### `onCreate(want, launchParam)`
作用：
- 注入全局 `ApiClient` context
- 启动网络监听
- 解析桌面卡片 / 推送拉起参数

#### `onWindowStageCreate(windowStage)`
作用：
- 判断是否已登录
- 已登录就加载 `pages/HomePage`
- 否则加载 `pages/LoginPage`

#### `parseLaunchWant(want)`
作用：
- 处理 widget 或推送带来的启动参数
- 写入 `AppStorage.widgetAction`

#### `onForeground()` / `onBackground()`
作用：
- 前后台切换时做消息轮询、后台检查等处理

### HomePage 的作用

`HomePage` 是整个 APP 的“主壳”。

主要职责：
- 手机模式：底部 4 tab
- 平板模式：左主页面 + 右扩展页面
- 统一处理消息未读、通知、桌面卡片联动
- 统一处理中心发布按钮

### HomePage 关键状态

#### `currentIndex`
当前底部导航页：
- 0：首页
- 1：大厅
- 2：消息
- 3：我的

#### `tabletRightType`
平板右侧打开的页面类型，例如：
- `detail`
- `chat`
- `ranking`
- `warning`
- `myPosts`
- `myLiked`
- `myReports`
- `feedback`
- `settings`
- `post`
- `announcementDetail`

#### `widgetAction`
桌面卡片或外部启动想让首页执行的动作。

### 学习建议
先读：
- `EntryAbility.ets`
- `HomePage.ets`

这是整个 APP 的总入口。

---

## 6.2 登录、注册、忘记密码

### 关键页面

- `pages/LoginPage.ets`
- `pages/RegisterPage.ets`
- `pages/ResetPasswordPage.ets`

### 关键服务

- `services/AuthService.ets`
- `services/SmsService.ets`
- `services/PasswordResetService.ets`
- `common/Session.ets`
- `common/ApiClient.ets`

### LoginPage 作用

负责：
- 学号 + 密码登录
- 登录成功后进入首页
- 登录失败显示错误提示
- 跳注册 / 忘记密码

关键函数：

#### `handleLogin()`
作用：
- 校验输入
- 调 `AuthService.login()`
- 成功后 `router.replaceUrl('pages/HomePage')`

### RegisterPage 作用

负责：
- 学号查重
- 短信验证码发送
- 注册学生账号
- 自动登录

### ResetPasswordPage 作用

负责：
- 短信验证码校验
- 重置密码
- 返回登录页

### AuthService 作用

这是 APP 端最核心的认证服务层。

关键函数：

#### `login(studentNo, password)`
作用：
- 调后端 `/auth/login/student`
- 保存 accessToken、refreshToken、用户信息到 `Session`

#### `register(...)`
作用：
- 调 `/auth/register/student`
- 成功后自动保存登录态

#### `getSession(context)`
作用：
- 调 `/user/me` 获取最新用户信息
- 更新本地 Session

#### `changePassword(...)`
作用：
- 调 `/user/change-password`

#### `savePushToken(...)`
作用：
- 调 `/user/push-token`

### Session 作用

`Session.ets` 封装了本地登录态存储。

关键函数：

- `save(...)`
- `read(...)`
- `clear(...)`
- `updateTokens(...)`
- `getAccessToken(...)`
- `getRefreshToken(...)`
- `updateProfile(...)`

学习这一块时，要重点理解：

> 登录成功后，真正落地的不是页面变量，而是 `Session + Preferences`

---

## 6.3 首页 FrontPage

### 关键文件

- `pages/FrontPage.ets`
- `services/AnnouncementService.ets`
- `services/ItemService.ets`

### FrontPage 作用

首页承载这些能力：
- 公告轮播
- 表彰排行入口
- 失物预警入口
- 热门推荐

### 关键函数

#### `loadAnnouncements()`
作用：
- 拉取公告
- 拉取热门物品
- 过滤已认领项
- 转换成首页热榜卡片数据

#### `openAnnouncement()`
作用：
- 手机：全屏打开公告详情
- 平板：右侧打开公告详情

#### `openRanking()`
打开排行榜页

#### `openWarning()`
打开预警页

#### `handleHotCardClick(item)`
作用：
- 手机：跳详情页
- 平板：右侧打开详情页

### 学习建议
看这一页时，要理解：
- 首页不是直接写死内容
- 而是通过 `AnnouncementService + ItemService` 从后端拿数据

---

## 6.4 大厅 HallPage

### 关键文件

- `pages/HallPage.ets`
- `components/HallItemCard.ets`
- `model/HallItemData.ets`
- `model/ItemCategory.ets`
- `services/ItemService.ets`

### HallPage 作用

大厅是物品信息流核心页面。

功能包括：
- 失物招领 / 寻物启事切换
- 搜索
- 搜索历史
- 分类筛选
- 地点筛选
- 时间范围筛选
- 排序
- 点赞同步
- 点击详情
- 下拉刷新
- 卡片进入动画

### HallPage 关键函数

#### `loadItems()`
作用：
- 根据当前 tab 拉取列表
- 转换成 `HallItemData`
- 更新列表动画触发器

#### `doSearch(keyword)`
作用：
- 调 `/items/search`
- 切换为搜索模式
- 保存搜索历史

#### `applySortAndFilter(items)`
作用：
- 本地按分类/地点/时间/点赞数进行二次处理

#### `handleCardClick(item)`
作用：
- 手机：全屏详情
- 平板：右侧详情

### HallItemCard 作用

这是大厅单张卡片组件。

功能：
- 封面图
- 标题
- 描述
- 分类标签
- 状态标签
- 发布人
- 点赞按钮
- 入场动画

关键函数：

#### `playEnterAnimation()`
作用：
- 卡片从右向左滑入
- 透明度渐显
- 根据 index 延迟，形成从上到下依次进入效果

#### `handleLikeClick()`
作用：
- 点赞/取消点赞
- 回调通知 `HallPage` 更新列表数据

### ItemCategory 作用

`ItemCategory.ets` 负责：
- 分类常量
- 状态显示映射
- `deriveStatus(...)`
- `getStatusLabel(...)`
- `getStatusColor(...)`
- `getStatusBg(...)`

它是状态显示统一的关键。

---

## 6.5 MainPage / Card 通用列表

### 关键文件

- `pages/MainPage.ets`
- `pages/Card.ets`

### 作用

这是另一套通用物品列表流，支持：
- 全部
- 失物
- 招领
- 已认领
- 搜索
- 分页加载

### Card.ets 的作用

它是 APP 通用物品卡片组件，很多页面复用它：
- 我的发布
- 我的收藏
- MainPage 列表

功能包括：
- 状态展示
- 多图布局
- 点击跳详情
- 平板模式右侧打开详情

---

## 6.6 物品详情页 DetailPage

### 关键文件

- `pages/DetailPage.ets`
- `components/DisputeDialog.ets`
- `services/ItemService.ets`
- `services/ChatService.ets`
- `services/ReportService.ets`

### 作用

展示单个物品完整信息，并承载操作。

包括：
- 图片轮播
- 发布者信息
- 分类 / 时间 / 描述
- 点赞
- 已认领状态
- 认领人学号显示
- 联系 TA
- 提交异议
- 编辑
- 删除
- 标记已认领

### 关键函数

#### `checkLikeStatus()`
检查当前用户是否点过赞

#### `handleToggleLike()`
执行点赞切换

#### `doDelete()`
删除帖子

#### `handleDispute(description)`
提交异议到后端 `/reports`

#### `contactOwner()`
作用：
- 获取 / 创建会话
- 发送 item-card 消息
- 打开聊天页

### 特别注意
详情页的很多动作不是直接操作数据库，而是：
- 通过 `ItemService`
- 通过 `ChatService`
- 通过 `ReportService`

所以学习详情页时一定要跟 service 往下看。

---

## 6.7 发布页 PostPage / PostForm

### 关键文件

- `pages/PostPage.ets`
- `components/PostForm.ets`
- `services/PostService.ets`
- `services/UploadService.ets`

### PostPage 的作用

它负责：
- 承接发布页容器
- 读编辑参数
- 表单校验
- 调 PostService 提交
- 成功后触发首页和我的发布刷新

### 关键函数

#### `handleImagePick()`
调用 HarmonyOS 相册选择器，最多选 3 张图。

#### `handleSubmit()`
作用：
- 校验输入
- 编辑模式调用 `PostService.update(...)`
- 发布模式调用 `PostService.publishFull(...)`
- 成功后关闭页面

### PostForm 的作用

它负责真正的表单 UI：
- 标题
- 描述
- 分类
- 类型
- 时间
- 地点
- 联系方式
- 图片列表

---

## 6.8 我的发布 / 我的收藏 / 我的异议

### 我的发布
文件：
- `pages/MyPostsPage.ets`

作用：
- 查看自己发过的帖子
- 复用 `ItemCardView`
- 点击进入详情继续操作

### 我的收藏
文件：
- `pages/MyLikedPage.ets`

作用：
- 展示我点赞过的帖子
- 复用 `ItemCardView`

### 我的异议
文件：
- `pages/MyReportsPage.ets`

作用：
- 展示我提交的异议 / 举报记录

---

## 6.9 消息页与聊天页

### 关键文件

- `pages/MessagePage.ets`
- `pages/ChatPage.ets`
- `services/ChatService.ets`
- `model/ChatSession.ets`
- `model/ChatMessage.ets`

### MessagePage 作用

- 展示会话列表
- 显示未读数
- 显示最后消息
- 删除会话（本地隐藏）
- 点击进入聊天

### ChatPage 作用

- 拉取消息
- 发送文本消息
- 显示 item-card/system/image/text 消息
- 双方确认认领
- 进入物品详情
- 未读标记
- 轮询新消息

### ChatService 核心函数

#### `getOrCreateSession(...)`
创建或获取会话

#### `getSessionsForUser(...)`
获取所有会话

#### `getMessages(...)`
拉取消息列表

#### `sendMessage(...)`
发送文本

#### `sendItemCardMessage(...)`
发送物品卡片消息

#### `sendSystemMessage(...)`
发送系统消息

#### `confirmClaimed(...)`
双方确认认领

#### `getUnreadSummary(...)`
未读汇总

---

## 6.10 个人中心与设置

### 关键文件

- `pages/PersonalPage.ets`
- `pages/SettingsPage.ets`
- `services/AuthService.ets`
- `services/UserService.ets`
- `services/UploadService.ets`

### 个人中心作用

展示：
- 学号
- 昵称
- 手机号
- 发布数
- 已认领数
- 热心值
- 异常次数

并支持：
- 上传头像
- 我的发布
- 我的点赞
- 我的异议
- 意见反馈
- 设置

### 设置页作用

支持：
- 编辑资料
- 修改密码
- 关于我们
- 退出登录

---

## 6.11 排行榜与预警页

### 排行榜
文件：
- `pages/RankingPage.ets`
- `services/RankingService.ets`

作用：
- 展示热心榜 Top 用户

### 预警页
文件：
- `pages/WarningPage.ets`
- `services/WarningService.ets`

作用：
- 展示长期未处理物品
- 点击进入详情

---

## 6.12 公告、反馈、桌面卡片

### 公告
文件：
- `pages/AnnouncementDetailPage.ets`
- `services/AnnouncementService.ets`

作用：
- 公告列表 / 公告详情展示

### 反馈
文件：
- `pages/FeedbackPage.ets`
- `services/FeedbackService.ets`

作用：
- 用户提交反馈

### 桌面卡片
文件：
- `entryformability/EntryFormAbility.ets`
- `widget/pages/MessageWidgetCard.ets`
- `widget/pages/PublishWidgetCard.ets`
- `widget/pages/AnnouncementWidgetCard.ets`
- `widget/pages/HotItemWidgetCard.ets`
- `resources/base/profile/form_config.json`

作用：
- 消息提醒卡片
- 快速发布卡片
- 公告卡片
- 热门推荐卡片

---

# 7. 后端模块详解

---

## 7.1 认证模块 auth

### 路径

```text
backend/src/main/java/com/campus/lostfound/modules/auth/
```

### 主要职责
- 登录
- 注册
- 学号查重
- 短信验证码
- refresh token
- 忘记密码

### 关键文件

- `AuthController.java`
- `AuthService.java`
- `AuthServiceImpl.java`
- `SmsService.java`
- `SmsServiceImpl.java`

### 关键函数说明

#### `studentLogin(...)`
学号密码登录

#### `studentRegister(...)`
学生注册

#### `refresh(...)`
刷新 access token

#### `passwordReset(...)`
通过手机号重置密码

---

## 7.2 用户模块 user

### 主要职责
- 获取当前用户信息
- 更新资料
- 修改密码
- 更新头像
- 保存 push token
- 用户排行榜

### 关键文件

- `UserController.java`
- `UserService.java`
- `UserServiceImpl.java`
- `User.java`
- `UserStat.java`
- `UserMapper.java`
- `UserStatMapper.java`

### 核心函数

#### `me()`
返回当前用户 session 信息

#### `updateProfile(...)`
更新昵称、手机号

#### `changePassword(...)`
修改密码

#### `updateAvatar(...)`
更新头像 URL

#### `ranking()`
返回排行榜

---

## 7.3 物品模块 item

### 主要职责
- 发布物品
- 编辑物品
- 列表
- 详情
- 搜索
- 热门
- 预警
- 点赞
- 已认领状态变更
- 删除限制

### 关键文件

- `ItemController.java`
- `ItemService.java`
- `ItemServiceImpl.java`
- `Item.java`
- `ItemMedia.java`
- `ItemLike.java`
- `ItemMapper.java`
- `ItemMediaMapper.java`
- `ItemLikeMapper.java`
- `ItemCardVO.java`

### 重点学习函数

#### `createItem(...)`
创建帖子

#### `updateItem(...)`
编辑帖子

#### `listByType(...)`
按类型或已认领状态分页查询

#### `detail(...)`
单条详情

#### `toggleLike(...)`
点赞切换

#### `markClaimed(...)`
设置已认领并更新统计

#### `deleteItem(...)`
删除帖子；已认领帖子禁止删除

#### `enrich(...)`
非常关键：
把 item 批量补齐成前端要用的卡片数据：
- 发布者
- 图片
- 状态
- 认领人学号
- likeCount

---

## 7.4 聊天模块 chat

### 主要职责
- 建会话
- 发消息
- 拉消息
- 未读统计
- 双方确认认领
- 管理员查看会话

### 关键文件

- `ChatController.java`
- `ChatService.java`
- `ChatServiceImpl.java`
- `ChatSession.java`
- `ChatMessage.java`
- `ChatSessionMapper.java`
- `ChatMessageMapper.java`

### 重点函数

#### `getOrCreateSession(...)`
创建或返回已有会话

#### `sendMessage(...)`
保存消息并更新会话最后消息

#### `confirmClaim(...)`
双方确认认领

#### `listMessages(...)`
查询消息

#### `getUnreadSummary(...)`
未读汇总

---

## 7.5 异议模块 report

### 主要职责
- 用户提交异议
- 查看我的异议
- 管理员处理异议

### 关键文件

- `ReportController.java`
- `ReportService.java`
- `ReportServiceImpl.java`
- `Report.java`
- `ReportMapper.java`
- `CreateReportReq.java`
- `ReportVO.java`

### 重点函数

#### `create(...)`
用户发起异议

#### `listMine(...)`
查看我的异议

---

## 7.6 公告模块 announcement

### 主要职责
- 公告列表
- 公告详情
- 后台公告 CRUD

### 关键文件

- `AnnouncementController.java`
- `AnnouncementService.java`
- `AnnouncementServiceImpl.java`
- `Announcement.java`
- `AnnouncementMapper.java`
- `AnnouncementVO.java`

---

## 7.7 反馈模块 feedback

### 主要职责
- 用户提交反馈
- 管理员处理反馈

### 关键文件

- `FeedbackController.java`
- `FeedbackService.java`
- `FeedbackServiceImpl.java`
- `Feedback.java`
- `FeedbackMapper.java`

### 注意
这个模块的反馈数据实际落在：

```text
audit_log
```

不是独立 feedback 表。

---

## 7.8 后台模块 admin

### 主要职责
- 管理员登录
- 仪表盘
- 用户管理
- 帖子管理
- 公告管理
- 异议处理
- 反馈管理
- 会话查看
- 导出概览

### 关键文件

- `AdminController.java`
- `AdminUser.java`
- `AdminUserMapper.java`
- `AdminProfileVO.java`
- `DashboardStatsVO.java`
- `AdminUserVO.java`
- `AdminItemVO.java`
- `AdminAnnouncementVO.java`
- `AdminReportVO.java`

### 学习建议
后台模块最值得读的是：

```text
AdminController.java
```

因为大量后台功能都集中在这里。

---

## 7.9 上传模块 upload

### 主要职责
- 文件上传到 MinIO
- base64 上传
- path 转 URL

### 关键文件

- `UploadController.java`
- `UploadService.java`
- `UploadServiceImpl.java`

### 关键函数

#### `uploadBase64(...)`
APP 最常走的上传接口

---

# 8. 后台前端模块详解

---

## 8.1 后台启动与路由

### 文件

- `admin-web/src/main.ts`
- `admin-web/src/router/index.ts`
- `admin-web/src/views/layout/AdminLayout.vue`
- `admin-web/src/stores/user.ts`
- `admin-web/src/api/http.ts`

### 作用
- 创建 Vue 应用
- 装 Pinia / Router / Element Plus
- 路由守卫判断后台 token
- 统一请求拦截器 / 错误提示

---

## 8.2 后台 API 封装

### 文件

- `admin-web/src/api/admin.ts`

### 作用
这是后台前端最重要的接口封装文件。

里面定义了：
- 所有后台数据类型
- 所有后台 API 方法

例如：
- `login()`
- `dashboardStats()`
- `users()`
- `updateUserStatus()`
- `items()`
- `updateItemStatus()`
- `announcements()`
- `saveAnnouncement()`
- `reports()`
- `reviewReport()`
- `feedbacks()`
- `chatSessions()`

学习后台时，这个文件一定要看。

---

## 8.3 后台页面说明

### 登录页
- `views/LoginPage.vue`

### 仪表盘
- `views/DashboardPage.vue`

### 用户管理
- `views/UsersPage.vue`

### 帖子管理
- `views/ItemsPage.vue`

### 公告管理
- `views/AnnouncementsPage.vue`

### 异议处理
- `views/ReportsPage.vue`

### 反馈管理
- `views/FeedbacksPage.vue`

### 会话查看
- `views/ChatSessionsPage.vue`

### 学习建议
后台页面学习顺序建议：
1. `LoginPage.vue`
2. `AdminLayout.vue`
3. `DashboardPage.vue`
4. `UsersPage.vue`
5. `ItemsPage.vue`
6. `ReportsPage.vue`

---

# 9. 关键代码链路（最值得学）

---

## 9.1 登录链路

```text
LoginPage.ets
→ AuthService.ets
→ ApiClient.ets
→ /auth/login/student
→ AuthController.java
→ AuthServiceImpl.java
→ user 表
→ Session.ets
```

---

## 9.2 发帖链路

```text
PostPage.ets
→ PostForm.ets
→ PostService.ets
→ UploadService.ets
→ /upload/base64
→ /items
→ ItemController.java
→ ItemServiceImpl.java
→ item / item_media / user_stat
```

---

## 9.3 大厅列表链路

```text
HallPage.ets
→ HallItemCard.ets
→ ItemService.ets
→ /items
→ ItemController.java
→ ItemServiceImpl.listByType()
→ ItemServiceImpl.enrich()
→ item / item_media / user / item_like
```

---

## 9.4 详情 + 联系 TA → 聊天链路

```text
DetailPage.ets
→ ChatService.getOrCreateSession()
→ /chat/sessions
→ ChatController.java
→ ChatServiceImpl.java
→ chat_session

DetailPage.contactOwner()
→ sendItemCardMessage()
→ /chat/sessions/{id}/messages
→ chat_message
```

---

## 9.5 双方确认认领链路

```text
ChatPage.ets
→ ChatService.confirmClaimed()
→ /chat/sessions/{id}/confirm-claim
→ ChatServiceImpl.confirmClaim()
→ ItemServiceImpl.markClaimed()
→ item.status = claimed
→ user_stat.incrementClaim / incrementReturn
```

---

## 9.6 异议链路

```text
DetailPage.ets
→ DisputeDialog.ets
→ ReportService.ets
→ POST /reports
→ ReportController.java
→ ReportServiceImpl.java
→ dispute

后台 ReportsPage.vue
→ adminApi.reports()
→ GET /admin/reports
→ AdminController.reports()
→ dispute / item / user / user_stat
```

---

## 9.7 桌面卡片链路

```text
HomePage.pollUnread()
→ updateWidgetData()
→ preferences(widget_data)
→ formProvider.updateForm()
→ EntryFormAbility.onUpdateForm()
→ WidgetCard / 各 Widget 页面刷新
```

---

# 10. 数据库表学习顺序

最重要的表按这个顺序看：

1. `user`
2. `user_stat`
3. `item`
4. `item_media`
5. `item_like`
6. `chat_session`
7. `chat_message`
8. `dispute`
9. `announcement`
10. `admin_user`
11. `audit_log`

---

# 11. 当前项目亮点总结（便于你自己理解）

这个项目最值得学习的不是某一个页面，而是这些“系统级设计”：

1. **统一请求层**：`ApiClient.ets`
2. **统一登录态存储**：`Session.ets`
3. **平板左右分栏主从布局**：`HomePage.ets`
4. **状态统一展示逻辑**：`ItemCategory.ets`
5. **物品卡片统一数据补全**：`ItemServiceImpl.enrich()`
6. **聊天与认领状态联动**：`ChatServiceImpl + ItemServiceImpl`
7. **异议处理三方信息模型**：后台 `AdminReportVO` / `ReportsPage.vue`
8. **鸿蒙特性融合**：通知、推送、桌面卡片、后台任务

---

# 12. 你下一步应该怎么学

如果你要真正掌握这个项目，建议你接下来这样做：

## 第一步：读通 5 个入口文件

1. `EntryAbility.ets`
2. `HomePage.ets`
3. `ApiClient.ets`
4. `AuthService.ets`
5. `AdminController.java`

## 第二步：跟 4 条主链路

1. 登录链路
2. 发帖链路
3. 大厅链路
4. 聊天链路

## 第三步：再看后台治理链路

1. 用户管理
2. 帖子管理
3. 异议处理
4. 公告管理

## 第四步：最后学鸿蒙特性整合

1. 桌面卡片
2. 通知
3. Push token
4. 平板分栏布局

---

# 13. 一句话总结这个项目

这是一个以 **HarmonyOS APP 为用户端、Spring Boot 为后端、Vue 为后台** 的校园失物招领系统，核心业务围绕：

- 用户认证
- 物品发布与浏览
- 详情与聊天
- 已认领状态流转
- 异议处理
- 后台治理
- 鸿蒙特色能力（桌面卡片、通知、平板布局）

展开。

---

如果你后面还要，我可以继续基于这份文档再生成两份更实用的材料：

1. `PPT_答辩提纲.md`：每一页 PPT 放什么内容
2. `项目演示讲稿.md`：3 分钟 / 5 分钟 / 8 分钟讲稿
