-- ============================================================
-- 校园失物招领后端 - 数据库表结构
-- MySQL 8.0 + utf8mb4
-- 覆盖：用户 / 物品 / 认领 / 聊天 / 运营 六大域 共 19 张表
-- ============================================================

USE campus_lostfound;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ================== 用户域 ==================

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `open_id`       VARCHAR(64)              DEFAULT NULL COMMENT '第三方 openId（微信/华为）',
    `phone`         VARCHAR(20)              DEFAULT NULL COMMENT '手机号（加密后）',
    `phone_hash`    VARCHAR(64)              DEFAULT NULL COMMENT '手机号哈希（用于唯一索引）',
    `password`      VARCHAR(128)             DEFAULT NULL COMMENT 'BCrypt 密码',
    `nickname`      VARCHAR(64)     NOT NULL COMMENT '昵称',
    `avatar`        VARCHAR(512)             DEFAULT NULL COMMENT '头像 URL',
    `gender`        TINYINT         NOT NULL DEFAULT 0 COMMENT '性别 0未知 1男 2女',
    `college`       VARCHAR(64)              DEFAULT NULL COMMENT '学院',
    `major`         VARCHAR(64)              DEFAULT NULL COMMENT '专业',
    `student_no`    VARCHAR(32)              DEFAULT NULL COMMENT '学号',
    `bio`           VARCHAR(255)             DEFAULT NULL COMMENT '个性签名',
    `status`        TINYINT         NOT NULL DEFAULT 1 COMMENT '状态 1正常 0禁用',
    `last_login_at` DATETIME                 DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip` VARCHAR(64)              DEFAULT NULL COMMENT '最后登录 IP',
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`       TINYINT         NOT NULL DEFAULT 0 COMMENT '软删 1=已删',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_phone_hash` (`phone_hash`),
    UNIQUE KEY `uk_open_id` (`open_id`),
    KEY `idx_student_no` (`student_no`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

DROP TABLE IF EXISTS `user_stat`;
CREATE TABLE `user_stat` (
    `user_id`      BIGINT UNSIGNED NOT NULL COMMENT '用户 ID',
    `heart_value`  INT             NOT NULL DEFAULT 0 COMMENT '热心值（归还越多越高）',
    `fraud_value`  INT             NOT NULL DEFAULT 0 COMMENT '冒领值（越高越不可信）',
    `post_count`   INT             NOT NULL DEFAULT 0 COMMENT '发布物品数',
    `claim_count`  INT             NOT NULL DEFAULT 0 COMMENT '成功认领数',
    `return_count` INT             NOT NULL DEFAULT 0 COMMENT '成功归还数',
    `like_received` INT            NOT NULL DEFAULT 0 COMMENT '收到点赞总数',
    `updated_at`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户统计（与 user 1:1）';

DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`        VARCHAR(32)     NOT NULL COMMENT '角色编码 STUDENT/MODERATOR/ADMIN',
    `name`        VARCHAR(64)     NOT NULL COMMENT '角色名称',
    `description` VARCHAR(255)             DEFAULT NULL,
    `enabled`     TINYINT         NOT NULL DEFAULT 1,
    `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

DROP TABLE IF EXISTS `permission`;
CREATE TABLE `permission` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`        VARCHAR(64)     NOT NULL COMMENT '权限编码 item:delete / user:ban 等',
    `name`        VARCHAR(64)     NOT NULL,
    `module`      VARCHAR(32)              DEFAULT NULL COMMENT '所属模块',
    `description` VARCHAR(255)             DEFAULT NULL,
    `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限表';

DROP TABLE IF EXISTS `role_permission`;
CREATE TABLE `role_permission` (
    `role_id`       BIGINT UNSIGNED NOT NULL,
    `permission_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`role_id`, `permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色-权限关联';

DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role` (
    `user_id` BIGINT UNSIGNED NOT NULL,
    `role_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`user_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户-角色关联';

-- ================== 物品域 ==================

DROP TABLE IF EXISTS `item_category`;
CREATE TABLE `item_category` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_id`   BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '父分类 0=根',
    `name`        VARCHAR(32)     NOT NULL COMMENT '分类名',
    `icon`        VARCHAR(64)              DEFAULT NULL COMMENT '图标 emoji 或 URL',
    `color`       VARCHAR(16)              DEFAULT NULL COMMENT '标签色',
    `sort`        INT             NOT NULL DEFAULT 0 COMMENT '排序',
    `enabled`     TINYINT         NOT NULL DEFAULT 1,
    `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_parent` (`parent_id`),
    KEY `idx_enabled_sort` (`enabled`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物品分类';

DROP TABLE IF EXISTS `item`;
CREATE TABLE `item` (
    `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `publisher_id` BIGINT UNSIGNED NOT NULL COMMENT '发布者 userId',
    `type`         VARCHAR(16)     NOT NULL COMMENT '类型 lost=失物 found=招领',
    `title`        VARCHAR(128)    NOT NULL COMMENT '标题',
    `description`  TEXT            NOT NULL COMMENT '描述',
    `category_id`  BIGINT UNSIGNED          DEFAULT NULL COMMENT '分类 ID',
    `category_name` VARCHAR(32)             DEFAULT NULL COMMENT '分类名（冗余）',
    `location`     VARCHAR(255)             DEFAULT NULL COMMENT '地点文字',
    `longitude`    DECIMAL(10, 6)           DEFAULT NULL COMMENT '经度',
    `latitude`     DECIMAL(10, 6)           DEFAULT NULL COMMENT '纬度',
    `lost_time`    DATETIME                 DEFAULT NULL COMMENT '丢失/发现时间',
    `contact`      VARCHAR(128)             DEFAULT NULL COMMENT '联系方式（脱敏展示）',
    `status`       VARCHAR(16)     NOT NULL DEFAULT 'active' COMMENT 'active/claimed/closed/frozen',
    `claimed_by`   BIGINT UNSIGNED          DEFAULT NULL COMMENT '认领人 userId',
    `claimed_at`   DATETIME                 DEFAULT NULL COMMENT '认领时间',
    `view_count`   INT             NOT NULL DEFAULT 0 COMMENT '浏览数',
    `like_count`   INT             NOT NULL DEFAULT 0 COMMENT '点赞数',
    `warning_expire_at` DATETIME            DEFAULT NULL COMMENT '预警到期时间（默认发布+15天）',
    `audit_status` TINYINT         NOT NULL DEFAULT 1 COMMENT '审核 1=通过 0=待审 -1=驳回',
    `audit_remark` VARCHAR(255)             DEFAULT NULL,
    `created_at`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`      TINYINT         NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_publisher` (`publisher_id`),
    KEY `idx_type_status` (`type`, `status`),
    KEY `idx_category` (`category_id`),
    KEY `idx_created` (`created_at`),
    KEY `idx_warning` (`warning_expire_at`),
    FULLTEXT KEY `ft_title_desc` (`title`, `description`) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物品主表';

DROP TABLE IF EXISTS `item_media`;
CREATE TABLE `item_media` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item_id`    BIGINT UNSIGNED NOT NULL,
    `type`       VARCHAR(16)     NOT NULL DEFAULT 'image' COMMENT 'image/video',
    `url`        VARCHAR(512)    NOT NULL,
    `sort`       INT             NOT NULL DEFAULT 0,
    `width`      INT                      DEFAULT NULL,
    `height`     INT                      DEFAULT NULL,
    `size_kb`    INT                      DEFAULT NULL,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_item_sort` (`item_id`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物品媒体附件';

DROP TABLE IF EXISTS `item_like`;
CREATE TABLE `item_like` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item_id`    BIGINT UNSIGNED NOT NULL,
    `user_id`    BIGINT UNSIGNED NOT NULL,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_item_user` (`item_id`, `user_id`),
    KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='点赞明细';

DROP TABLE IF EXISTS `item_favorite`;
CREATE TABLE `item_favorite` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item_id`    BIGINT UNSIGNED NOT NULL,
    `user_id`    BIGINT UNSIGNED NOT NULL,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_item_user` (`item_id`, `user_id`),
    KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏明细';

DROP TABLE IF EXISTS `item_view_log`;
CREATE TABLE `item_view_log` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item_id`    BIGINT UNSIGNED NOT NULL,
    `user_id`    BIGINT UNSIGNED          DEFAULT NULL COMMENT '匿名访问为空',
    `ip`         VARCHAR(64)              DEFAULT NULL,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_item_time` (`item_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='浏览日志（做热度推荐）';

-- ================== 认领域 ==================

DROP TABLE IF EXISTS `claim_request`;
CREATE TABLE `claim_request` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item_id`       BIGINT UNSIGNED NOT NULL,
    `claimant_id`   BIGINT UNSIGNED NOT NULL COMMENT '认领申请人 userId',
    `publisher_id`  BIGINT UNSIGNED NOT NULL COMMENT '发布者 userId（冗余）',
    `description`   TEXT                     COMMENT '申请说明：物品特征等',
    `contact`       VARCHAR(128)             DEFAULT NULL COMMENT '认领人联系方式',
    `status`        VARCHAR(16)     NOT NULL DEFAULT 'pending' COMMENT 'pending/approved/rejected/confirmed/disputed/cancelled',
    `reject_reason` VARCHAR(255)             DEFAULT NULL,
    `approved_at`   DATETIME                 DEFAULT NULL,
    `confirmed_at`  DATETIME                 DEFAULT NULL COMMENT '线下交接确认时间',
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_item` (`item_id`),
    KEY `idx_claimant` (`claimant_id`),
    KEY `idx_publisher` (`publisher_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='认领申请';

DROP TABLE IF EXISTS `claim_evidence`;
CREATE TABLE `claim_evidence` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `claim_id`   BIGINT UNSIGNED NOT NULL,
    `type`       VARCHAR(16)     NOT NULL COMMENT 'image/text/ocr',
    `url`        VARCHAR(512)             DEFAULT NULL,
    `content`    TEXT                     COMMENT '文字凭证',
    `sort`       INT             NOT NULL DEFAULT 0,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_claim` (`claim_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='认领凭证';

DROP TABLE IF EXISTS `dispute`;
CREATE TABLE `dispute` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `target_type`   VARCHAR(16)     NOT NULL COMMENT 'item/claim/user/message',
    `target_id`     BIGINT UNSIGNED NOT NULL,
    `reporter_id`   BIGINT UNSIGNED NOT NULL,
    `reason`        VARCHAR(64)     NOT NULL COMMENT '举报原因枚举',
    `description`   TEXT                     COMMENT '详细说明',
    `evidence_urls` TEXT                     COMMENT '证据图（JSON 数组）',
    `status`        VARCHAR(16)     NOT NULL DEFAULT 'pending' COMMENT 'pending/processing/resolved/rejected',
    `handler_id`    BIGINT UNSIGNED          DEFAULT NULL COMMENT '处理的管理员 ID',
    `resolution`    VARCHAR(255)             DEFAULT NULL COMMENT '处理结果说明',
    `resolved_at`   DATETIME                 DEFAULT NULL,
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_target` (`target_type`, `target_id`),
    KEY `idx_status` (`status`),
    KEY `idx_reporter` (`reporter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='争议/举报';

-- ================== 交互域 ==================

DROP TABLE IF EXISTS `chat_session`;
CREATE TABLE `chat_session` (
    `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_a_id`       BIGINT UNSIGNED NOT NULL COMMENT '较小的 userId',
    `user_b_id`       BIGINT UNSIGNED NOT NULL COMMENT '较大的 userId',
    `item_id`         BIGINT UNSIGNED          DEFAULT NULL COMMENT '关联物品',
    `last_message`    VARCHAR(512)             DEFAULT NULL COMMENT '最后一条消息摘要',
    `last_message_at` DATETIME                 DEFAULT NULL,
    `a_unread_count`  INT             NOT NULL DEFAULT 0,
    `b_unread_count`  INT             NOT NULL DEFAULT 0,
    `a_deleted`       TINYINT         NOT NULL DEFAULT 0,
    `b_deleted`       TINYINT         NOT NULL DEFAULT 0,
    `created_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_users_item` (`user_a_id`, `user_b_id`, `item_id`),
    KEY `idx_a` (`user_a_id`),
    KEY `idx_b` (`user_b_id`),
    KEY `idx_last_msg` (`last_message_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会话';

DROP TABLE IF EXISTS `chat_message`;
CREATE TABLE `chat_message` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `session_id` BIGINT UNSIGNED NOT NULL,
    `sender_id`  BIGINT UNSIGNED NOT NULL,
    `type`       VARCHAR(16)     NOT NULL DEFAULT 'text' COMMENT 'text/image/item-card/system',
    `content`    TEXT            NOT NULL COMMENT '文字或 JSON（图片 URL / 物品卡片数据）',
    `read_flag`  TINYINT         NOT NULL DEFAULT 0 COMMENT '接收方已读',
    `recalled`   TINYINT         NOT NULL DEFAULT 0 COMMENT '是否撤回',
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_session_time` (`session_id`, `created_at`),
    KEY `idx_sender` (`sender_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='聊天消息';

DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    BIGINT UNSIGNED NOT NULL COMMENT '接收人',
    `type`       VARCHAR(32)     NOT NULL COMMENT 'claim/like/chat/system/warning',
    `title`      VARCHAR(128)    NOT NULL,
    `content`    VARCHAR(512)             DEFAULT NULL,
    `link`       VARCHAR(255)             DEFAULT NULL COMMENT '点击跳转路径',
    `ref_type`   VARCHAR(32)              DEFAULT NULL COMMENT '关联资源类型',
    `ref_id`     BIGINT UNSIGNED          DEFAULT NULL,
    `read_flag`  TINYINT         NOT NULL DEFAULT 0,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_unread` (`user_id`, `read_flag`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='站内通知';

-- ================== 运营域 ==================

DROP TABLE IF EXISTS `announcement`;
CREATE TABLE `announcement` (
    `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title`        VARCHAR(128)    NOT NULL,
    `content`      TEXT            NOT NULL COMMENT '富文本',
    `cover`        VARCHAR(512)             DEFAULT NULL COMMENT '封面图',
    `author_id`    BIGINT UNSIGNED NOT NULL,
    `priority`     INT             NOT NULL DEFAULT 0 COMMENT '优先级越大越靠前',
    `status`       VARCHAR(16)     NOT NULL DEFAULT 'draft' COMMENT 'draft/published/offline',
    `publish_from` DATETIME                 DEFAULT NULL COMMENT '生效时间',
    `publish_to`   DATETIME                 DEFAULT NULL COMMENT '失效时间',
    `view_count`   INT             NOT NULL DEFAULT 0,
    `created_at`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_status_priority` (`status`, `priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告';

DROP TABLE IF EXISTS `sensitive_word`;
CREATE TABLE `sensitive_word` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `word`       VARCHAR(64)     NOT NULL,
    `level`      TINYINT         NOT NULL DEFAULT 1 COMMENT '1警告 2屏蔽 3封号',
    `category`   VARCHAR(32)              DEFAULT NULL,
    `enabled`    TINYINT         NOT NULL DEFAULT 1,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_word` (`word`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='敏感词';

DROP TABLE IF EXISTS `audit_log`;
CREATE TABLE `audit_log` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    BIGINT UNSIGNED          DEFAULT NULL COMMENT '操作者 ID',
    `user_name`  VARCHAR(64)              DEFAULT NULL,
    `module`     VARCHAR(32)     NOT NULL COMMENT '模块',
    `action`     VARCHAR(64)     NOT NULL COMMENT '动作',
    `target`     VARCHAR(128)             DEFAULT NULL COMMENT '对象描述',
    `params`     TEXT                     COMMENT '请求参数 JSON',
    `result`     VARCHAR(16)     NOT NULL DEFAULT 'success' COMMENT 'success/fail',
    `ip`         VARCHAR(64)              DEFAULT NULL,
    `user_agent` VARCHAR(255)             DEFAULT NULL,
    `duration_ms` INT                     DEFAULT NULL,
    `error_msg`  VARCHAR(512)             DEFAULT NULL,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_time` (`user_id`, `created_at`),
    KEY `idx_module_action` (`module`, `action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作审计日志';

DROP TABLE IF EXISTS `system_config`;
CREATE TABLE `system_config` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `config_key`  VARCHAR(64)     NOT NULL,
    `config_value` TEXT                    DEFAULT NULL,
    `description` VARCHAR(255)             DEFAULT NULL,
    `editable`    TINYINT         NOT NULL DEFAULT 1,
    `updated_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置';

SET FOREIGN_KEY_CHECKS = 1;
