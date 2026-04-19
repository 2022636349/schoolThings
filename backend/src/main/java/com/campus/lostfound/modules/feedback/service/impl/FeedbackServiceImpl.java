package com.campus.lostfound.modules.feedback.service.impl;

import com.campus.lostfound.modules.feedback.entity.Feedback;
import com.campus.lostfound.modules.feedback.mapper.FeedbackMapper;
import com.campus.lostfound.modules.feedback.service.FeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class FeedbackServiceImpl implements FeedbackService {
    private final FeedbackMapper feedbackMapper;

    @Override
    public void create(Long userId, String content) {
        Feedback feedback = new Feedback();
        feedback.setUserId(userId);
        feedback.setUserName(userId == null ? "anonymous" : String.valueOf(userId));
        feedback.setModule("feedback");
        feedback.setAction("submit");
        feedback.setTarget("app_feedback");
        feedback.setParams(content);
        feedback.setResult("success");
        feedbackMapper.insert(feedback);
    }
}
