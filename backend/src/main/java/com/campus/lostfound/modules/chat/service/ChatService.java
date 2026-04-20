package com.campus.lostfound.modules.chat.service;

import com.campus.lostfound.modules.chat.dto.ChatMessageVO;
import com.campus.lostfound.modules.chat.dto.ChatSessionVO;
import com.campus.lostfound.modules.chat.dto.UnreadSummaryVO;

import java.util.List;
import java.util.Map;

public interface ChatService {

    ChatSessionVO getOrCreateSession(Long itemId, Long initiatorId, Long ownerId);

    ChatSessionVO getSession(Long sessionId, Long currentUserId);

    List<ChatSessionVO> listSessionsForUser(Long userId);

    ChatMessageVO sendMessage(Long sessionId, Long senderId, String content, String type, String imageUrl);

    ChatMessageVO sendSystemMessage(Long sessionId, Long senderId, String content);

    List<ChatMessageVO> listMessages(Long sessionId, int limit);

    /** @return 双方是否都已确认 */
    boolean confirmClaim(Long sessionId, Long userId);

    void deleteSession(Long sessionId, Long userId);

    long getMaxMsgId(Long sessionId);

    UnreadSummaryVO getUnreadSummary(Long userId, Map<String, Long> lastReadMsgIdMap, Map<String, Long> hiddenMap);

    Map<String, Integer> getPerSessionUnreadCounts(Long userId, Map<String, Long> lastReadMsgIdMap);
}
