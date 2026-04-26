package com.campus.lostfound.modules.feedback.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.lostfound.modules.feedback.dto.FeedbackVO;
import com.campus.lostfound.modules.feedback.entity.Feedback;
import com.campus.lostfound.modules.feedback.mapper.FeedbackMapper;
import com.campus.lostfound.modules.feedback.service.FeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

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
        feedback.setResult("pending");
        feedbackMapper.insert(feedback);
    }

    @Override
    public List<FeedbackVO> listMine(Long userId) {
        List<Feedback> list = feedbackMapper.selectList(new LambdaQueryWrapper<Feedback>()
                .eq(Feedback::getUserId, userId)
                .eq(Feedback::getModule, "feedback")
                .eq(Feedback::getAction, "submit")
                .orderByDesc(Feedback::getId));
        List<FeedbackVO> result = new ArrayList<>();
        for (Feedback item : list) {
            FeedbackVO vo = new FeedbackVO();
            vo.setId(item.getId());
            vo.setContent(item.getParams());
            vo.setReply(item.getErrorMsg());
            vo.setCreatedAt(toMillis(item.getCreatedAt()));
            result.add(vo);
        }
        return result;
    }

    private long toMillis(LocalDateTime time) {
        return time == null ? 0L : time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
    }
}
