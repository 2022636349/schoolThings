package com.campus.lostfound.modules.feedback.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.feedback.dto.CreateFeedbackReq;
import com.campus.lostfound.modules.feedback.service.FeedbackService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "反馈", description = "提交用户反馈")
@RestController
@RequestMapping("/feedback")
@RequiredArgsConstructor
public class FeedbackController {
    private final FeedbackService feedbackService;

    @Operation(summary = "提交反馈")
    @PostMapping
    public Result<Void> create(@RequestBody @Valid CreateFeedbackReq req) {
        feedbackService.create(UserContext.get(), req.getContent());
        return Result.success();
    }
}
