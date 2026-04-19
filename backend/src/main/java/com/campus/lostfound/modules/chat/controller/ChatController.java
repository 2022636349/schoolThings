package com.campus.lostfound.modules.chat.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.chat.dto.ChatMessageVO;
import com.campus.lostfound.modules.chat.dto.ChatSessionVO;
import com.campus.lostfound.modules.chat.dto.UnreadSummaryVO;
import com.campus.lostfound.modules.chat.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "聊天", description = "会话 / 消息 / 未读 / 确认归还")
@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @Operation(summary = "获取或创建会话（与物品主人）")
    @PostMapping("/sessions")
    public Result<ChatSessionVO> getOrCreate(@RequestBody GetOrCreateReq req) {
        Long uid = UserContext.require();
        return Result.success(chatService.getOrCreateSession(req.getItemId(), uid, req.getOwnerId()));
    }

    @Operation(summary = "会话详情")
    @GetMapping("/sessions/{sessionId}")
    public Result<ChatSessionVO> detail(@PathVariable("sessionId") Long sessionId) {
        Long uid = UserContext.require();
        return Result.success(chatService.getSession(sessionId, uid));
    }

    @Operation(summary = "当前用户的全部会话")
    @GetMapping("/sessions")
    public Result<List<ChatSessionVO>> mySessions() {
        Long uid = UserContext.require();
        return Result.success(chatService.listSessionsForUser(uid));
    }

    @Operation(summary = "删除会话（连同消息）")
    @DeleteMapping("/sessions/{sessionId}")
    public Result<Void> delete(@PathVariable("sessionId") Long sessionId) {
        Long uid = UserContext.require();
        chatService.deleteSession(sessionId, uid);
        return Result.success();
    }

    @Operation(summary = "发送消息")
    @PostMapping("/sessions/{sessionId}/messages")
    public Result<ChatMessageVO> send(@PathVariable("sessionId") Long sessionId,
                                      @RequestBody SendMessageReq req) {
        Long uid = UserContext.require();
        return Result.success(chatService.sendMessage(sessionId, uid, req.getContent(), req.getType(), req.getImageUrl()));
    }

    @Operation(summary = "消息列表")
    @GetMapping("/sessions/{sessionId}/messages")
    public Result<List<ChatMessageVO>> listMessages(@PathVariable("sessionId") Long sessionId,
                                                    @RequestParam(value = "limit", defaultValue = "50") int limit) {
        return Result.success(chatService.listMessages(sessionId, limit));
    }

    @Operation(summary = "确认归还（双方都确认后自动标记物品为已认领）")
    @PostMapping("/sessions/{sessionId}/confirm-claim")
    public Result<Map<String, Object>> confirmClaim(@PathVariable("sessionId") Long sessionId) {
        Long uid = UserContext.require();
        boolean both = chatService.confirmClaim(sessionId, uid);
        Map<String, Object> m = new HashMap<>();
        m.put("bothConfirmed", both);
        return Result.success(m);
    }

    @Operation(summary = "当前会话最大消息 id（用作轮询游标）")
    @GetMapping("/sessions/{sessionId}/max-msg-id")
    public Result<Long> maxMsgId(@PathVariable("sessionId") Long sessionId) {
        return Result.success(chatService.getMaxMsgId(sessionId));
    }

    @Operation(summary = "全局未读汇总")
    @PostMapping("/unread/summary")
    public Result<UnreadSummaryVO> unreadSummary(@RequestBody UnreadReq req) {
        Long uid = UserContext.require();
        Map<String, Long> lastRead = req.getLastReadMsgIds() == null ? Map.of() : req.getLastReadMsgIds();
        Map<String, Long> hidden = req.getHidden() == null ? Map.of() : req.getHidden();
        return Result.success(chatService.getUnreadSummary(uid, lastRead, hidden));
    }

    @Operation(summary = "各会话未读数")
    @PostMapping("/unread/counts")
    public Result<Map<String, Integer>> unreadCounts(@RequestBody UnreadReq req) {
        Long uid = UserContext.require();
        Map<String, Long> lastRead = req.getLastReadMsgIds() == null ? Map.of() : req.getLastReadMsgIds();
        return Result.success(chatService.getPerSessionUnreadCounts(uid, lastRead));
    }

    @Data
    public static class GetOrCreateReq {
        private Long itemId;
        private Long ownerId;
    }

    @Data
    public static class SendMessageReq {
        private String content;
        /** text / image / item-card / system */
        private String type;
        private String imageUrl;
    }

    @Data
    public static class UnreadReq {
        /** sessionId(string) → 已读到的 msgId */
        private Map<String, Long> lastReadMsgIds;
        /** sessionId(string) → 软删除时间戳（毫秒），<= 该时间的消息不计入未读 */
        private Map<String, Long> hidden;
    }
}
