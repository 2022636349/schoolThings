package com.campus.lostfound.modules.chat.service.impl;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.modules.chat.dto.ChatMessageVO;
import com.campus.lostfound.modules.chat.dto.ChatSessionVO;
import com.campus.lostfound.modules.chat.dto.UnreadSummaryVO;
import com.campus.lostfound.modules.chat.entity.ChatMessage;
import com.campus.lostfound.modules.chat.entity.ChatSession;
import com.campus.lostfound.modules.chat.mapper.ChatMessageMapper;
import com.campus.lostfound.modules.chat.mapper.ChatSessionMapper;
import com.campus.lostfound.modules.chat.service.ChatService;
import com.campus.lostfound.modules.item.entity.Item;
import com.campus.lostfound.modules.item.service.ItemService;
import com.campus.lostfound.modules.user.entity.User;
import com.campus.lostfound.modules.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private final ChatSessionMapper sessionMapper;
    private final ChatMessageMapper messageMapper;
    private final UserService userService;
    private final ItemService itemService;

    @Override
    @Transactional
    public ChatSessionVO getOrCreateSession(Long itemId, Long initiatorId, Long ownerId) {
        ChatSession existing = sessionMapper.selectOne(new LambdaQueryWrapper<ChatSession>()
                .eq(ChatSession::getItemId, itemId)
                .eq(ChatSession::getInitiatorId, initiatorId));
        if (existing != null) {
            return toVO(existing, initiatorId);
        }
        ChatSession s = new ChatSession();
        s.setItemId(itemId);
        s.setInitiatorId(initiatorId);
        s.setOwnerId(ownerId);
        s.setInitiatorConfirmed(0);
        s.setOwnerConfirmed(0);
        s.setCreatedAt(LocalDateTime.now());
        s.setUpdatedAt(LocalDateTime.now());
        sessionMapper.insert(s);
        return toVO(s, initiatorId);
    }

    @Override
    public ChatSessionVO getSession(Long sessionId, Long currentUserId) {
        ChatSession s = sessionMapper.selectById(sessionId);
        if (s == null) return null;
        if (!s.getInitiatorId().equals(currentUserId) && !s.getOwnerId().equals(currentUserId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权访问该会话");
        }
        return toVO(s, currentUserId);
    }

    @Override
    public List<ChatSessionVO> listSessionsForUser(Long userId) {
        List<ChatSession> list = sessionMapper.selectList(new QueryWrapper<ChatSession>()
                .eq("initiator_id", userId).or().eq("owner_id", userId));
        list.sort((a, b) -> {
            LocalDateTime la = a.getLastMessageAt();
            LocalDateTime lb = b.getLastMessageAt();
            long ta = la == null ? 0 : la.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
            long tb = lb == null ? 0 : lb.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
            return Long.compare(tb, ta);
        });
        return buildSessionVOs(list, userId);
    }

    @Override
    @Transactional
    public ChatMessageVO sendMessage(Long sessionId, Long senderId, String content, String type, String imageUrl) {
        ChatSession s = sessionMapper.selectById(sessionId);
        if (s == null) throw new BusinessException(ResultCode.FAIL, "会话不存在");
        if (!s.getInitiatorId().equals(senderId) && !s.getOwnerId().equals(senderId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权发送消息");
        }
        ChatMessage m = new ChatMessage();
        m.setSessionId(sessionId);
        m.setSenderId(senderId);
        m.setType(StrUtil.blankToDefault(type, "text"));
        m.setContent(content);
        m.setReadFlag(0);
        m.setRecalled(0);
        m.setCreatedAt(LocalDateTime.now());
        messageMapper.insert(m);

        // 更新会话摘要
        String preview;
        if ("image".equals(m.getType())) {
            preview = "[图片]";
        } else if ("item-card".equals(m.getType())) {
            preview = "[物品卡片]";
        } else if ("system".equals(m.getType())) {
            preview = StrUtil.blankToDefault(content, "[系统消息]");
        } else {
            preview = content.length() > 30 ? content.substring(0, 30) + "..." : content;
        }
        ChatSession upd = new ChatSession();
        upd.setId(sessionId);
        upd.setLastMessage(preview);
        upd.setLastMessageAt(LocalDateTime.now());
        upd.setUpdatedAt(LocalDateTime.now());
        sessionMapper.updateById(upd);

        return toMsgVO(m, imageUrl);
    }

    @Override
    @Transactional
    public ChatMessageVO sendSystemMessage(Long sessionId, Long senderId, String content) {
        return sendMessage(sessionId, senderId, content, "system", null);
    }

    @Override
    public List<ChatMessageVO> listMessages(Long sessionId, int limit) {
        if (limit <= 0) limit = 50;
        if (limit > 200) limit = 200;
        List<ChatMessage> list = messageMapper.selectList(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, sessionId)
                .orderByDesc(ChatMessage::getId)
                .last("LIMIT " + limit));
        // 反转为时间升序
        Collections.reverse(list);
        List<ChatMessageVO> vos = new ArrayList<>();
        for (ChatMessage m : list) {
            vos.add(toMsgVO(m, null));
        }
        return vos;
    }

    @Override
    @Transactional
    public boolean confirmClaim(Long sessionId, Long userId) {
        ChatSession s = sessionMapper.selectById(sessionId);
        if (s == null) return false;
        boolean isInit = s.getInitiatorId().equals(userId);
        boolean isOwner = s.getOwnerId().equals(userId);
        if (!isInit && !isOwner) {
            throw new BusinessException(ResultCode.FORBIDDEN);
        }
        ChatSession upd = new ChatSession();
        upd.setId(sessionId);
        if (isInit) upd.setInitiatorConfirmed(1);
        if (isOwner) upd.setOwnerConfirmed(1);
        upd.setUpdatedAt(LocalDateTime.now());
        sessionMapper.updateById(upd);

        ChatSession after = sessionMapper.selectById(sessionId);
        boolean both = after.getInitiatorConfirmed() != null && after.getInitiatorConfirmed() == 1
                && after.getOwnerConfirmed() != null && after.getOwnerConfirmed() == 1;
        if (both) {
            // 双方确认 → 标记物品已认领
            itemService.markClaimed(after.getItemId(), after.getInitiatorId());
        }
        return both;
    }

    @Override
    @Transactional
    public void deleteSession(Long sessionId, Long userId) {
        ChatSession s = sessionMapper.selectById(sessionId);
        if (s == null) return;
        if (!s.getInitiatorId().equals(userId) && !s.getOwnerId().equals(userId)) {
            throw new BusinessException(ResultCode.FORBIDDEN);
        }
        messageMapper.delete(new LambdaQueryWrapper<ChatMessage>().eq(ChatMessage::getSessionId, sessionId));
        sessionMapper.deleteById(sessionId);
    }

    @Override
    public long getMaxMsgId(Long sessionId) {
        ChatMessage m = messageMapper.selectOne(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, sessionId)
                .orderByDesc(ChatMessage::getId)
                .last("LIMIT 1"));
        return m == null ? 0L : m.getId();
    }

    @Override
    public UnreadSummaryVO getUnreadSummary(Long userId, Map<String, Long> lastReadMsgIdMap, Map<String, Long> hiddenMap) {
        UnreadSummaryVO vo = new UnreadSummaryVO();
        vo.setCount(0);
        vo.setLatest("");
        List<ChatSession> sessions = sessionMapper.selectList(new QueryWrapper<ChatSession>()
                .eq("initiator_id", userId).or().eq("owner_id", userId));
        if (sessions.isEmpty()) return vo;

        long latestMsgId = 0;
        int total = 0;
        String latestContent = "";

        Map<String, Long> lrMap = lastReadMsgIdMap == null ? Collections.emptyMap() : lastReadMsgIdMap;
        Map<String, Long> hiMap = hiddenMap == null ? Collections.emptyMap() : hiddenMap;

        for (ChatSession s : sessions) {
            String sid = String.valueOf(s.getId());
            Long hide = hiMap.getOrDefault(sid, 0L);
            long lt = s.getLastMessageAt() == null ? 0 :
                    s.getLastMessageAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
            if (hide > 0 && lt <= hide) continue;

            long lastReadMsgId = lrMap.getOrDefault(sid, 0L);
            List<ChatMessage> newMsgs = messageMapper.selectList(new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getSessionId, s.getId())
                    .gt(ChatMessage::getId, lastReadMsgId)
                    .ne(ChatMessage::getSenderId, userId)
                    .orderByDesc(ChatMessage::getId)
                    .last("LIMIT 50"));
            for (ChatMessage m : newMsgs) {
                total++;
                if (m.getId() > latestMsgId) {
                    latestMsgId = m.getId();
                    if ("image".equals(m.getType())) {
                        latestContent = "[图片]";
                    } else if ("item-card".equals(m.getType())) {
                        latestContent = "[物品卡片]";
                    } else if ("system".equals(m.getType())) {
                        latestContent = StrUtil.blankToDefault(m.getContent(), "[系统消息]");
                    } else {
                        latestContent = m.getContent();
                    }
                }
            }
        }
        vo.setCount(total);
        vo.setLatest(latestContent);
        return vo;
    }

    @Override
    public Map<String, Integer> getPerSessionUnreadCounts(Long userId, Map<String, Long> lastReadMsgIdMap) {
        Map<String, Integer> result = new HashMap<>();
        List<ChatSession> sessions = sessionMapper.selectList(new QueryWrapper<ChatSession>()
                .eq("initiator_id", userId).or().eq("owner_id", userId));
        Map<String, Long> lrMap = lastReadMsgIdMap == null ? Collections.emptyMap() : lastReadMsgIdMap;
        for (ChatSession s : sessions) {
            String sid = String.valueOf(s.getId());
            long lastReadMsgId = lrMap.getOrDefault(sid, 0L);
            Long c = messageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getSessionId, s.getId())
                    .gt(ChatMessage::getId, lastReadMsgId)
                    .ne(ChatMessage::getSenderId, userId));
            result.put(sid, c == null ? 0 : c.intValue());
        }
        return result;
    }

    // ==== 辅助 ====

    private List<ChatSessionVO> buildSessionVOs(List<ChatSession> sessions, Long currentUserId) {
        if (sessions.isEmpty()) return new ArrayList<>();
        Set<Long> peerIds = new HashSet<>();
        Set<Long> itemIds = new HashSet<>();
        for (ChatSession s : sessions) {
            peerIds.add(s.getInitiatorId().equals(currentUserId) ? s.getOwnerId() : s.getInitiatorId());
            if (s.getItemId() != null) itemIds.add(s.getItemId());
        }
        Map<String, User> userMap = userService.batchGetByIds(new ArrayList<>(peerIds));
        Map<Long, Item> itemMap = new HashMap<>();
        if (!itemIds.isEmpty()) {
            List<Item> items = itemService.listByIds(itemIds);
            for (Item it : items) itemMap.put(it.getId(), it);
        }
        List<ChatSessionVO> result = new ArrayList<>();
        for (ChatSession s : sessions) {
            ChatSessionVO vo = toVO(s, currentUserId);
            Long peerId = s.getInitiatorId().equals(currentUserId) ? s.getOwnerId() : s.getInitiatorId();
            User peer = userMap.get(String.valueOf(peerId));
            if (peer != null) {
                vo.setPeerName(peer.getNickname());
                vo.setPeerAvatar(peer.getAvatar());
            }
            Item it = s.getItemId() == null ? null : itemMap.get(s.getItemId());
            if (it != null) {
                vo.setItemTitle(it.getTitle());
                vo.setItemStatus(it.getStatus());
                vo.setItemType(it.getType());
            }
            result.add(vo);
        }
        return result;
    }

    private ChatSessionVO toVO(ChatSession s, Long currentUserId) {
        ChatSessionVO vo = new ChatSessionVO();
        vo.setSessionId(String.valueOf(s.getId()));
        vo.setItemId(s.getItemId());
        vo.setInitiatorId(String.valueOf(s.getInitiatorId()));
        vo.setOwnerId(String.valueOf(s.getOwnerId()));
        vo.setLastMessage(s.getLastMessage());
        vo.setLastTime(s.getLastMessageAt() == null ? null :
                s.getLastMessageAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        vo.setInitiatorConfirmed(s.getInitiatorConfirmed());
        vo.setOwnerConfirmed(s.getOwnerConfirmed());
        return vo;
    }

    private ChatMessageVO toMsgVO(ChatMessage m, String imageUrl) {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setMsgId(m.getId());
        vo.setSessionId(String.valueOf(m.getSessionId()));
        vo.setSenderId(String.valueOf(m.getSenderId()));
        vo.setContent(m.getContent());
        vo.setMessageType(m.getType());
        if ("image".equals(m.getType())) {
            vo.setImageUrl(imageUrl != null ? imageUrl : m.getContent());
        }
        vo.setSendTime(m.getCreatedAt() == null ? 0L :
                m.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        return vo;
    }
}
