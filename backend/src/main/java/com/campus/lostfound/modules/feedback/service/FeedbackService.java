package com.campus.lostfound.modules.feedback.service;

import com.campus.lostfound.modules.feedback.dto.FeedbackVO;

import java.util.List;

public interface FeedbackService {
    void create(Long userId, String content);
    List<FeedbackVO> listMine(Long userId);
}
