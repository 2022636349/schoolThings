package com.campus.lostfound.modules.admin.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.JwtUtil;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.admin.dto.*;
import com.campus.lostfound.modules.admin.entity.AdminUser;
import com.campus.lostfound.modules.admin.mapper.AdminUserMapper;
import com.campus.lostfound.modules.announcement.entity.Announcement;
import com.campus.lostfound.modules.announcement.mapper.AnnouncementMapper;
import com.campus.lostfound.modules.chat.entity.ChatSession;
import com.campus.lostfound.modules.chat.mapper.ChatSessionMapper;
import com.campus.lostfound.modules.chat.service.ChatService;
import com.campus.lostfound.modules.claim.entity.ClaimRequest;
import com.campus.lostfound.modules.claim.mapper.ClaimRequestMapper;
import com.campus.lostfound.modules.feedback.entity.Feedback;
import com.campus.lostfound.modules.feedback.mapper.FeedbackMapper;
import com.campus.lostfound.modules.item.entity.Item;
import com.campus.lostfound.modules.item.entity.ItemMedia;
import com.campus.lostfound.modules.item.mapper.ItemMapper;
import com.campus.lostfound.modules.item.mapper.ItemMediaMapper;
import com.campus.lostfound.modules.item.service.ItemService;
import com.campus.lostfound.modules.report.entity.Report;
import com.campus.lostfound.modules.report.mapper.ReportMapper;
import com.campus.lostfound.modules.user.entity.User;
import com.campus.lostfound.modules.user.entity.UserStat;
import com.campus.lostfound.modules.user.mapper.UserMapper;
import com.campus.lostfound.modules.user.mapper.UserStatMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.ZoneId;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "管理后台", description = "后台管理 MVP 接口")
@Slf4j
@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final AdminUserMapper adminUserMapper;
    private final UserMapper userMapper;
    private final UserStatMapper userStatMapper;
    private final ItemMapper itemMapper;
    private final ItemMediaMapper itemMediaMapper;
    private final ItemService itemService;
    private final AnnouncementMapper announcementMapper;
    private final ChatSessionMapper chatSessionMapper;
    private final ChatService chatService;
    private final ClaimRequestMapper claimRequestMapper;
    private final ReportMapper reportMapper;
    private final FeedbackMapper feedbackMapper;

    @Operation(summary = "管理员登录")
    @PostMapping("/auth/login")
    public Result<AdminLoginVO> login(@RequestBody @Valid AdminLoginReq req) {
        AdminUser admin = adminUserMapper.selectOne(new LambdaQueryWrapper<AdminUser>()
                .eq(AdminUser::getUsername, req.getUsername())
                .last("LIMIT 1"));
        boolean exists = admin != null;
        boolean enabled = exists && admin.getStatus() != null && admin.getStatus() == 1;
        String storedPassword = exists ? admin.getPassword() : null;
        boolean passwordMatched = exists && storedPassword != null && passwordEncoder.matches(req.getPassword(), storedPassword);
        log.warn("admin login attempt username={}, exists={}, status={}, enabled={}, passwordMatched={}, role={}, deleted={}, rawPasswordLength={}, storedPasswordLength={}, storedPasswordPrefix={}, dbAdminId={}",
                req.getUsername(),
                exists,
                exists ? admin.getStatus() : null,
                enabled,
                passwordMatched,
                exists ? admin.getRole() : null,
                exists ? admin.getDeleted() : null,
                req.getPassword() == null ? null : req.getPassword().length(),
                storedPassword == null ? null : storedPassword.length(),
                storedPassword == null ? null : storedPassword.substring(0, Math.min(7, storedPassword.length())),
                exists ? admin.getId() : null);
        if (!exists || !enabled || !passwordMatched) {
            throw new RuntimeException("账号或密码错误");
        }
        AdminUser update = new AdminUser();
        update.setId(admin.getId());
        update.setLastLoginAt(LocalDateTime.now());
        adminUserMapper.updateById(update);
        String token = jwtUtil.generateAdminAccessToken(admin.getId(), admin.getUsername(), admin.getRole());
        return Result.success(AdminLoginVO.builder()
                .token(token)
                .username(admin.getNickname() == null ? admin.getUsername() : admin.getNickname())
                .role(admin.getRole())
                .build());
    }

    @Operation(summary = "当前管理员信息")
    @GetMapping("/profile")
    public Result<AdminProfileVO> profile() {
        Long adminId = UserContext.require();
        AdminUser admin = adminUserMapper.selectById(adminId);
        AdminProfileVO vo = new AdminProfileVO();
        if (admin != null) {
            vo.setId(admin.getId());
            vo.setUsername(admin.getUsername());
            vo.setNickname(admin.getNickname());
            vo.setRole(admin.getRole());
        }
        return Result.success(vo);
    }

    @Operation(summary = "修改管理员密码")
    @PostMapping("/profile/password")
    public Result<Void> changePassword(@RequestBody ChangeAdminPasswordReq req) {
        Long adminId = UserContext.require();
        AdminUser admin = adminUserMapper.selectById(adminId);
        if (admin == null || !passwordEncoder.matches(req.getOldPassword(), admin.getPassword())) {
            throw new RuntimeException("原密码错误");
        }
        AdminUser update = new AdminUser();
        update.setId(adminId);
        update.setPassword(passwordEncoder.encode(req.getNewPassword()));
        adminUserMapper.updateById(update);
        return Result.success();
    }

    @Operation(summary = "仪表盘统计")
    @GetMapping("/dashboard/stats")
    public Result<DashboardStatsVO> stats() {
        DashboardStatsVO vo = new DashboardStatsVO();
        vo.setUserCount(userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getDeleted, 0)));
        vo.setItemCount(itemMapper.selectCount(new LambdaQueryWrapper<Item>().eq(Item::getDeleted, 0)));
        vo.setClaimCount(claimRequestMapper.selectCount(new LambdaQueryWrapper<ClaimRequest>()));
        vo.setReportCount(reportMapper.selectCount(new LambdaQueryWrapper<Report>()));
        vo.setPendingClaimCount(claimRequestMapper.selectCount(new LambdaQueryWrapper<ClaimRequest>().eq(ClaimRequest::getStatus, "pending")));
        vo.setPendingReportCount(reportMapper.selectCount(new LambdaQueryWrapper<Report>().eq(Report::getStatus, "pending")));
        vo.setTrends(buildTrends(7));
        vo.setRecentAnnouncements(recentAnnouncements(5));
        vo.setRecentItems(recentItems(5));
        vo.setRecentReports(recentReports(5));
        log.warn("dashboard stats userCount={}, itemCount={}, claimCount={}, reportCount={}, pendingClaimCount={}, pendingReportCount={}",
                vo.getUserCount(), vo.getItemCount(), vo.getClaimCount(), vo.getReportCount(), vo.getPendingClaimCount(), vo.getPendingReportCount());
        return Result.success(vo);
    }

    @Operation(summary = "用户列表")
    @GetMapping("/users")
    public Result<AdminPageVO<AdminUserVO>> users(AdminUserQueryReq req) {
        Page<User> page = userMapper.selectPage(new Page<>(safeCurrent(req.getCurrent()), safeSize(req.getSize())),
                new LambdaQueryWrapper<User>()
                        .and(hasText(req.getKeyword()), w -> w.like(User::getStudentNo, req.getKeyword())
                                .or().like(User::getNickname, req.getKeyword())
                                .or().like(User::getPhone, req.getKeyword()))
                        .eq(req.getStatus() != null, User::getStatus, req.getStatus())
                        .orderByDesc(User::getId));
        List<User> users = page.getRecords();
        Map<Long, UserStat> statMap = loadUserStatMap(users);
        List<AdminUserVO> list = new ArrayList<>();
        for (User item : users) {
            UserStat stat = statMap.get(item.getId());
            AdminUserVO vo = new AdminUserVO();
            vo.setId(item.getId());
            vo.setStudentNo(item.getStudentNo());
            vo.setNickname(item.getNickname());
            vo.setPhone(item.getPhone());
            vo.setStatus(item.getStatus());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            vo.setHeartValue(statValue(stat, UserStat::getHeartValue));
            vo.setFraudValue(statValue(stat, UserStat::getFraudValue));
            vo.setPostCount(statValue(stat, UserStat::getPostCount));
            vo.setClaimCount(statValue(stat, UserStat::getClaimCount));
            vo.setReturnCount(statValue(stat, UserStat::getReturnCount));
            vo.setLikeReceived(statValue(stat, UserStat::getLikeReceived));
            list.add(vo);
        }
        return Result.success(toPageVO(page, list));
    }

    @Operation(summary = "更新用户状态")
    @PostMapping("/users/{id}/status")
    public Result<Void> updateUserStatus(@PathVariable("id") Long id, @RequestBody UpdateUserStatusReq req) {
        User user = new User();
        user.setId(id);
        user.setStatus(req.getStatus());
        userMapper.updateById(user);
        return Result.success();
    }

    @Operation(summary = "帖子列表")
    @GetMapping("/items")
    public Result<AdminPageVO<AdminItemVO>> items(AdminItemQueryReq req) {
        Page<Item> page = itemMapper.selectPage(new Page<>(safeCurrent(req.getCurrent()), safeSize(req.getSize())),
                new LambdaQueryWrapper<Item>()
                        .and(hasText(req.getKeyword()), w -> w.like(Item::getTitle, req.getKeyword())
                                .or().like(Item::getDescription, req.getKeyword())
                                .or().like(Item::getLocation, req.getKeyword()))
                        .eq(hasText(req.getType()), Item::getType, req.getType())
                        .eq(hasText(req.getStatus()), Item::getStatus, req.getStatus())
                        .orderByDesc(Item::getId));
        List<Item> items = page.getRecords();
        Map<Long, User> userMap = loadUserMapByIds(items);
        Map<Long, List<String>> imageMap = loadItemImages(items);
        List<AdminItemVO> list = new ArrayList<>();
        for (Item item : items) {
            User publisher = userMap.get(item.getPublisherId());
            AdminItemVO vo = new AdminItemVO();
            vo.setId(item.getId());
            vo.setTitle(item.getTitle());
            vo.setType(item.getType());
            vo.setStatus(item.getStatus());
            vo.setPublisherId(item.getPublisherId() == null ? null : String.valueOf(item.getPublisherId()));
            vo.setPublisherName(publisher == null ? null : publisher.getNickname());
            vo.setLocation(item.getLocation());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            vo.setLostTime(toMillis(item.getLostTime()));
            vo.setLikeCount(item.getLikeCount() == null ? 0 : item.getLikeCount());
            vo.setImages(imageMap.getOrDefault(item.getId(), Collections.emptyList()));
            list.add(vo);
        }
        return Result.success(toPageVO(page, list));
    }

    @Operation(summary = "删除帖子")
    @DeleteMapping("/items/{id}")
    public Result<Void> deleteItem(@PathVariable("id") Long id) {
        itemMapper.deleteById(id);
        return Result.success();
    }

    @Operation(summary = "批量删除帖子")
    @PostMapping("/items/batch-delete")
    public Result<Void> batchDeleteItems(@RequestBody DeleteIdsReq req) {
        if (req.getIds() == null || req.getIds().length == 0) {
            return Result.success();
        }
        List<Long> ids = new ArrayList<>();
        for (Long id : req.getIds()) {
            if (id != null) {
                ids.add(id);
            }
        }
        if (!ids.isEmpty()) {
            for (Long itemId : ids) {
                itemMapper.deleteById(itemId);
            }
        }
        return Result.success();
    }

    @Operation(summary = "更新帖子状态")
    @PostMapping("/items/{id}/status")
    public Result<Void> updateItemStatus(@PathVariable("id") Long id, @RequestBody UpdateItemStatusReq req) {
        Item item = new Item();
        item.setId(id);
        item.setStatus(req.getStatus());
        itemMapper.updateById(item);
        return Result.success();
    }

    @Operation(summary = "反馈列表")
    @GetMapping("/feedbacks")
    public Result<List<AdminFeedbackVO>> feedbacks() {
        List<Feedback> items = feedbackMapper.selectList(new LambdaQueryWrapper<Feedback>().orderByDesc(Feedback::getId).last("LIMIT 100"));
        List<AdminFeedbackVO> list = new ArrayList<>();
        for (Feedback item : items) {
            AdminFeedbackVO vo = new AdminFeedbackVO();
            vo.setId(item.getId());
            vo.setUserId(item.getUserId() == null ? null : String.valueOf(item.getUserId()));
            vo.setUserName(item.getUserName());
            vo.setContent(item.getParams());
            vo.setResult(item.getResult());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "更新反馈处理结果")
    @PostMapping("/feedbacks/{id}/result")
    public Result<Void> updateFeedbackResult(@PathVariable("id") Long id, @RequestBody UpdateFeedbackReq req) {
        Feedback item = new Feedback();
        item.setId(id);
        item.setResult(req.getResult());
        feedbackMapper.updateById(item);
        return Result.success();
    }

    @Operation(summary = "会话列表")
    @GetMapping("/chat/sessions")
    public Result<List<AdminChatSessionVO>> chatSessions() {
        List<ChatSession> sessions = chatSessionMapper.selectList(new LambdaQueryWrapper<ChatSession>().orderByDesc(ChatSession::getLastMessageAt).last("LIMIT 100"));
        List<Long> userIds = new ArrayList<>();
        List<Long> itemIds = new ArrayList<>();
        for (ChatSession session : sessions) {
            if (session.getInitiatorId() != null) {
                userIds.add(session.getInitiatorId());
            }
            if (session.getOwnerId() != null) {
                userIds.add(session.getOwnerId());
            }
            if (session.getItemId() != null) {
                itemIds.add(session.getItemId());
            }
        }
        Map<Long, User> userMap = loadUsersByIds(userIds);
        Map<Long, Item> itemMap = loadItemsByIds(itemIds);
        List<AdminChatSessionVO> list = new ArrayList<>();
        for (ChatSession session : sessions) {
            User initiator = session.getInitiatorId() == null ? null : userMap.get(session.getInitiatorId());
            User owner = session.getOwnerId() == null ? null : userMap.get(session.getOwnerId());
            Item item = session.getItemId() == null ? null : itemMap.get(session.getItemId());
            AdminChatSessionVO vo = new AdminChatSessionVO();
            vo.setId(session.getId());
            vo.setItemId(session.getItemId());
            vo.setItemTitle(item == null ? null : item.getTitle());
            vo.setInitiatorId(session.getInitiatorId() == null ? null : String.valueOf(session.getInitiatorId()));
            vo.setInitiatorName(initiator == null ? null : initiator.getNickname());
            vo.setOwnerId(session.getOwnerId() == null ? null : String.valueOf(session.getOwnerId()));
            vo.setOwnerName(owner == null ? null : owner.getNickname());
            vo.setLastMessage(session.getLastMessage());
            vo.setLastMessageAt(toMillis(session.getLastMessageAt()));
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "导出概览数据")
    @GetMapping("/export/overview")
    public Result<String> exportOverview() {
        String csv = "type,count\n"
                + "users," + defaultLong(userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getDeleted, 0))) + "\n"
                + "items," + defaultLong(itemMapper.selectCount(new LambdaQueryWrapper<Item>().eq(Item::getDeleted, 0))) + "\n"
                + "claims," + defaultLong(claimRequestMapper.selectCount(new LambdaQueryWrapper<ClaimRequest>())) + "\n"
                + "reports," + defaultLong(reportMapper.selectCount(new LambdaQueryWrapper<Report>())) + "\n";
        return Result.success(csv);
    }
    @Operation(summary = "公告列表")
    @GetMapping("/announcements")
    public Result<List<AdminAnnouncementVO>> announcements() {
        List<Announcement> items = announcementMapper.selectList(new LambdaQueryWrapper<Announcement>().orderByDesc(Announcement::getId).last("LIMIT 100"));
        List<AdminAnnouncementVO> list = new ArrayList<>();
        for (Announcement item : items) {
            AdminAnnouncementVO vo = new AdminAnnouncementVO();
            vo.setId(item.getId());
            vo.setTitle(item.getTitle());
            vo.setContent(item.getContent());
            vo.setCover(item.getCover());
            vo.setStatus(item.getStatus());
            vo.setPriority(item.getPriority());
            vo.setPublishFrom(toMillis(item.getPublishFrom()));
            vo.setPublishTo(toMillis(item.getPublishTo()));
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            vo.setViewCount(item.getViewCount() == null ? 0 : item.getViewCount());
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "保存公告")
    @PostMapping("/announcements")
    public Result<Void> saveAnnouncement(@RequestBody SaveAnnouncementReq req) {
        Announcement item = new Announcement();
        item.setId(req.getId());
        item.setTitle(req.getTitle());
        item.setContent(req.getContent());
        item.setCover(req.getCover());
        item.setPriority(req.getPriority() == null ? 0 : req.getPriority());
        item.setStatus(req.getStatus() == null ? "draft" : req.getStatus());
        item.setPublishFrom(toLocalDateTime(req.getPublishFrom()));
        item.setPublishTo(toLocalDateTime(req.getPublishTo()));
        item.setAuthorId(0L);
        if (req.getId() == null) {
            announcementMapper.insert(item);
        } else {
            announcementMapper.updateById(item);
        }
        return Result.success();
    }

    @Operation(summary = "删除公告")
    @DeleteMapping("/announcements/{id}")
    public Result<Void> deleteAnnouncement(@PathVariable("id") Long id) {
        announcementMapper.deleteById(id);
        return Result.success();
    }

    @Operation(summary = "认领申请列表")
    @GetMapping("/claims")
    public Result<List<AdminClaimVO>> claims() {
        List<ClaimRequest> items = claimRequestMapper.selectList(new LambdaQueryWrapper<ClaimRequest>().orderByDesc(ClaimRequest::getId).last("LIMIT 100"));
        Map<Long, Item> itemMap = loadItemMapByIdsFromClaims(items);
        Map<Long, User> userMap = loadUserMapByClaimUsers(items);
        List<AdminClaimVO> list = new ArrayList<>();
        for (ClaimRequest item : items) {
            Item linkedItem = itemMap.get(item.getItemId());
            User claimant = item.getClaimantId() == null ? null : userMap.get(item.getClaimantId());
            User publisher = item.getPublisherId() == null ? null : userMap.get(item.getPublisherId());
            AdminClaimVO vo = new AdminClaimVO();
            vo.setId(item.getId());
            vo.setItemId(item.getItemId());
            vo.setItemTitle(linkedItem == null ? null : linkedItem.getTitle());
            vo.setItemStatus(linkedItem == null ? null : linkedItem.getStatus());
            vo.setDescription(item.getDescription());
            vo.setContact(item.getContact());
            vo.setStatus(item.getStatus());
            vo.setClaimantId(item.getClaimantId() == null ? null : String.valueOf(item.getClaimantId()));
            vo.setClaimantName(claimant == null ? null : claimant.getNickname());
            vo.setPublisherId(item.getPublisherId() == null ? null : String.valueOf(item.getPublisherId()));
            vo.setPublisherName(publisher == null ? null : publisher.getNickname());
            vo.setReviewRemark(item.getRejectReason());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            vo.setApprovedAt(toMillis(item.getApprovedAt()));
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "审批认领申请")
    @PostMapping("/claims/{id}/status")
    public Result<Void> reviewClaim(@PathVariable("id") Long id, @RequestBody ReviewClaimReq req) {
        ClaimRequest current = claimRequestMapper.selectById(id);
        if (current == null) {
            return Result.success();
        }
        ClaimRequest item = new ClaimRequest();
        item.setId(id);
        item.setStatus(req.getStatus());
        item.setRejectReason(req.getRemark());
        item.setApprovedAt("approved".equals(req.getStatus()) ? toLocalDateTime(System.currentTimeMillis()) : null);
        claimRequestMapper.updateById(item);
        if (current.getItemId() != null && hasText(req.getStatus())) {
            Item update = new Item();
            update.setId(current.getItemId());
            if ("approved".equals(req.getStatus())) {
                update.setStatus("claimed");
                update.setClaimedBy(current.getClaimantId());
                update.setClaimedAt(toLocalDateTime(System.currentTimeMillis()));
            } else if ("rejected".equals(req.getStatus())) {
                update.setStatus("active");
            }
            itemMapper.updateById(update);
        }
        notifyClaimReview(current, req);
        return Result.success();
    }

    @Operation(summary = "举报列表")
    @GetMapping("/reports")
    public Result<List<AdminReportVO>> reports() {
        List<Report> items = reportMapper.selectList(new LambdaQueryWrapper<Report>().orderByDesc(Report::getId).last("LIMIT 100"));
        Map<Long, User> reporterMap = loadReportUserMap(items);
        Map<Long, Item> itemMap = loadReportItemMap(items);
        List<AdminReportVO> list = new ArrayList<>();
        for (Report item : items) {
            User reporter = item.getReporterId() == null ? null : reporterMap.get(item.getReporterId());
            Item targetItem = "item".equals(item.getTargetType()) ? itemMap.get(item.getTargetId()) : null;
            AdminReportVO vo = new AdminReportVO();
            vo.setId(item.getId());
            vo.setTargetType(item.getTargetType());
            vo.setTargetId(item.getTargetId());
            vo.setTargetTitle(targetItem == null ? null : targetItem.getTitle());
            vo.setReporterId(item.getReporterId() == null ? null : String.valueOf(item.getReporterId()));
            vo.setReporterName(reporter == null ? null : reporter.getNickname());
            vo.setReason(item.getReason());
            vo.setDescription(item.getDescription());
            vo.setEvidenceUrls(item.getEvidenceUrls());
            vo.setStatus(item.getStatus());
            vo.setResolution(item.getResolution());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            list.add(vo);
        }
        return Result.success(list);
    }

    @Operation(summary = "处理举报")
    @PostMapping("/reports/{id}/status")
    public Result<Void> reviewReport(@PathVariable("id") Long id, @RequestBody ReviewReportReq req) {
        Report current = reportMapper.selectById(id);
        if (current == null) {
            return Result.success();
        }
        Report item = new Report();
        item.setId(id);
        item.setStatus(req.getStatus());
        item.setResolution(req.getResolution());
        reportMapper.updateById(item);
        if ("item".equals(current.getTargetType()) && current.getTargetId() != null && hasText(req.getItemStatus())) {
            Item target = new Item();
            target.setId(current.getTargetId());
            target.setStatus(req.getItemStatus());
            itemMapper.updateById(target);
        }
        if (current.getReporterId() != null && req.getUserStatus() != null) {
            User reporter = new User();
            reporter.setId(current.getReporterId());
            reporter.setStatus(req.getUserStatus());
            userMapper.updateById(reporter);
        }
        return Result.success();
    }

    private long toMillis(java.time.LocalDateTime time) {
        return time == null ? 0L : time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
    }

    private java.time.LocalDateTime toLocalDateTime(Long millis) {
        if (millis == null || millis <= 0) {
            return null;
        }
        return java.time.LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(millis), ZoneId.systemDefault());
    }

    private long safeCurrent(Long current) {
        return current == null || current < 1 ? 1L : current;
    }

    private long safeSize(Long size) {
        if (size == null || size < 1) {
            return 10L;
        }
        return Math.min(size, 50L);
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private <T> AdminPageVO<T> toPageVO(Page<?> page, List<T> records) {
        AdminPageVO<T> vo = new AdminPageVO<>();
        vo.setTotal(page.getTotal());
        vo.setCurrent(page.getCurrent());
        vo.setSize(page.getSize());
        vo.setRecords(records);
        return vo;
    }

    private Map<Long, User> loadUsersByIds(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<User> users = userMapper.selectList(new LambdaQueryWrapper<User>().in(User::getId, ids));
        Map<Long, User> map = new HashMap<>();
        for (User user : users) {
            map.put(user.getId(), user);
        }
        return map;
    }

    private Map<Long, Item> loadItemsByIds(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Item> items = itemMapper.selectList(new LambdaQueryWrapper<Item>().in(Item::getId, ids));
        Map<Long, Item> map = new HashMap<>();
        for (Item item : items) {
            map.put(item.getId(), item);
        }
        return map;
    }

    private List<AdminTrendVO> buildTrends(int days) {
        List<AdminTrendVO> list = new ArrayList<>();
        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");
        for (int i = days - 1; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            LocalDateTime start = day.atStartOfDay();
            LocalDateTime end = day.plusDays(1).atStartOfDay();
            AdminTrendVO vo = new AdminTrendVO();
            vo.setDate(day.format(formatter));
            vo.setUserCount(userMapper.selectCount(new LambdaQueryWrapper<User>().ge(User::getCreatedAt, start).lt(User::getCreatedAt, end)));
            vo.setItemCount(itemMapper.selectCount(new LambdaQueryWrapper<Item>().ge(Item::getCreatedAt, start).lt(Item::getCreatedAt, end)));
            vo.setClaimCount(claimRequestMapper.selectCount(new LambdaQueryWrapper<ClaimRequest>().ge(ClaimRequest::getCreatedAt, start).lt(ClaimRequest::getCreatedAt, end)));
            vo.setReportCount(reportMapper.selectCount(new LambdaQueryWrapper<Report>().ge(Report::getCreatedAt, start).lt(Report::getCreatedAt, end)));
            list.add(vo);
        }
        return list;
    }

    private List<AdminAnnouncementVO> recentAnnouncements(int limit) {
        List<Announcement> items = announcementMapper.selectList(new LambdaQueryWrapper<Announcement>().orderByDesc(Announcement::getId).last("LIMIT " + limit));
        List<AdminAnnouncementVO> list = new ArrayList<>();
        for (Announcement item : items) {
            AdminAnnouncementVO vo = new AdminAnnouncementVO();
            vo.setId(item.getId());
            vo.setTitle(item.getTitle());
            vo.setContent(item.getContent());
            vo.setCover(item.getCover());
            vo.setStatus(item.getStatus());
            vo.setPriority(item.getPriority());
            vo.setPublishFrom(toMillis(item.getPublishFrom()));
            vo.setPublishTo(toMillis(item.getPublishTo()));
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            vo.setViewCount(item.getViewCount() == null ? 0 : item.getViewCount());
            list.add(vo);
        }
        return list;
    }

    private List<AdminItemVO> recentItems(int limit) {
        List<Item> items = itemMapper.selectList(new LambdaQueryWrapper<Item>().orderByDesc(Item::getId).last("LIMIT " + limit));
        Map<Long, User> userMap = loadUserMapByIds(items);
        Map<Long, List<String>> imageMap = loadItemImages(items);
        List<AdminItemVO> list = new ArrayList<>();
        for (Item item : items) {
            User publisher = userMap.get(item.getPublisherId());
            AdminItemVO vo = new AdminItemVO();
            vo.setId(item.getId());
            vo.setTitle(item.getTitle());
            vo.setType(item.getType());
            vo.setStatus(item.getStatus());
            vo.setPublisherId(item.getPublisherId() == null ? null : String.valueOf(item.getPublisherId()));
            vo.setPublisherName(publisher == null ? null : publisher.getNickname());
            vo.setLocation(item.getLocation());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            vo.setLostTime(toMillis(item.getLostTime()));
            vo.setLikeCount(item.getLikeCount() == null ? 0 : item.getLikeCount());
            vo.setImages(imageMap.getOrDefault(item.getId(), Collections.emptyList()));
            list.add(vo);
        }
        return list;
    }

    private List<AdminReportVO> recentReports(int limit) {
        List<Report> items = reportMapper.selectList(new LambdaQueryWrapper<Report>().orderByDesc(Report::getId).last("LIMIT " + limit));
        Map<Long, User> reporterMap = loadReportUserMap(items);
        Map<Long, Item> itemMap = loadReportItemMap(items);
        List<AdminReportVO> list = new ArrayList<>();
        for (Report item : items) {
            User reporter = item.getReporterId() == null ? null : reporterMap.get(item.getReporterId());
            Item targetItem = "item".equals(item.getTargetType()) ? itemMap.get(item.getTargetId()) : null;
            AdminReportVO vo = new AdminReportVO();
            vo.setId(item.getId());
            vo.setTargetType(item.getTargetType());
            vo.setTargetId(item.getTargetId());
            vo.setTargetTitle(targetItem == null ? null : targetItem.getTitle());
            vo.setReporterId(item.getReporterId() == null ? null : String.valueOf(item.getReporterId()));
            vo.setReporterName(reporter == null ? null : reporter.getNickname());
            vo.setReason(item.getReason());
            vo.setDescription(item.getDescription());
            vo.setEvidenceUrls(item.getEvidenceUrls());
            vo.setStatus(item.getStatus());
            vo.setResolution(item.getResolution());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            list.add(vo);
        }
        return list;
    }

    private Long defaultLong(Long value) {
        return value == null ? 0L : value;
    }

    private Map<Long, UserStat> loadUserStatMap(List<User> users) {
        List<Long> ids = new ArrayList<>();
        for (User user : users) {
            if (user.getId() != null) {
                ids.add(user.getId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<UserStat> stats = userStatMapper.selectList(new LambdaQueryWrapper<UserStat>().in(UserStat::getUserId, ids));
        Map<Long, UserStat> map = new HashMap<>();
        for (UserStat stat : stats) {
            map.put(stat.getUserId(), stat);
        }
        return map;
    }

    private Integer statValue(UserStat stat, java.util.function.Function<UserStat, Integer> getter) {
        if (stat == null) {
            return 0;
        }
        Integer value = getter.apply(stat);
        return value == null ? 0 : value;
    }

    private Map<Long, User> loadUserMapByIds(List<Item> items) {
        List<Long> ids = new ArrayList<>();
        for (Item item : items) {
            if (item.getPublisherId() != null) {
                ids.add(item.getPublisherId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<User> users = userMapper.selectList(new LambdaQueryWrapper<User>().in(User::getId, ids));
        Map<Long, User> map = new HashMap<>();
        for (User user : users) {
            map.put(user.getId(), user);
        }
        return map;
    }

    private Map<Long, Item> loadItemMapByIdsFromClaims(List<ClaimRequest> claims) {
        List<Long> ids = new ArrayList<>();
        for (ClaimRequest claim : claims) {
            if (claim.getItemId() != null) {
                ids.add(claim.getItemId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Item> items = itemMapper.selectList(new LambdaQueryWrapper<Item>().in(Item::getId, ids));
        Map<Long, Item> map = new HashMap<>();
        for (Item item : items) {
            map.put(item.getId(), item);
        }
        return map;
    }

    private Map<Long, User> loadUserMapByClaimUsers(List<ClaimRequest> claims) {
        List<Long> ids = new ArrayList<>();
        for (ClaimRequest claim : claims) {
            if (claim.getClaimantId() != null) {
                ids.add(claim.getClaimantId());
            }
            if (claim.getPublisherId() != null) {
                ids.add(claim.getPublisherId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<User> users = userMapper.selectList(new LambdaQueryWrapper<User>().in(User::getId, ids));
        Map<Long, User> map = new HashMap<>();
        for (User user : users) {
            map.put(user.getId(), user);
        }
        return map;
    }

    private void notifyClaimReview(ClaimRequest claim, ReviewClaimReq req) {
        if (claim.getItemId() == null || claim.getClaimantId() == null || claim.getPublisherId() == null) {
            return;
        }
        ChatSession session = chatSessionMapper.selectOne(new LambdaQueryWrapper<ChatSession>()
                .eq(ChatSession::getItemId, claim.getItemId())
                .eq(ChatSession::getInitiatorId, claim.getClaimantId())
                .eq(ChatSession::getOwnerId, claim.getPublisherId())
                .last("LIMIT 1"));
        if (session == null) {
            return;
        }
        String text = "approved".equals(req.getStatus())
                ? "你的认领申请已通过" + (hasText(req.getRemark()) ? "，备注：" + req.getRemark() : "")
                : "你的认领申请未通过" + (hasText(req.getRemark()) ? "，原因：" + req.getRemark() : "");
        chatService.sendSystemMessage(session.getId(), claim.getPublisherId(), text);
    }

    private Map<Long, User> loadReportUserMap(List<Report> reports) {
        List<Long> ids = new ArrayList<>();
        for (Report report : reports) {
            if (report.getReporterId() != null) {
                ids.add(report.getReporterId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<User> users = userMapper.selectList(new LambdaQueryWrapper<User>().in(User::getId, ids));
        Map<Long, User> map = new HashMap<>();
        for (User user : users) {
            map.put(user.getId(), user);
        }
        return map;
    }

    private Map<Long, Item> loadReportItemMap(List<Report> reports) {
        List<Long> ids = new ArrayList<>();
        for (Report report : reports) {
            if ("item".equals(report.getTargetType()) && report.getTargetId() != null) {
                ids.add(report.getTargetId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Item> items = itemMapper.selectList(new LambdaQueryWrapper<Item>().in(Item::getId, ids));
        Map<Long, Item> map = new HashMap<>();
        for (Item item : items) {
            map.put(item.getId(), item);
        }
        return map;
    }

    private Map<Long, List<String>> loadItemImages(List<Item> items) {
        List<Long> ids = new ArrayList<>();
        for (Item item : items) {
            if (item.getId() != null) {
                ids.add(item.getId());
            }
        }
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        List<ItemMedia> medias = itemMediaMapper.selectList(new LambdaQueryWrapper<ItemMedia>()
                .in(ItemMedia::getItemId, ids)
                .eq(ItemMedia::getType, "image")
                .orderByAsc(ItemMedia::getSort)
                .orderByAsc(ItemMedia::getId));
        Map<Long, List<String>> map = new HashMap<>();
        for (ItemMedia media : medias) {
            map.computeIfAbsent(media.getItemId(), key -> new ArrayList<>()).add(media.getUrl());
        }
        return map;
    }
}
