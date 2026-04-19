package com.campus.lostfound.modules.report.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.report.dto.CreateReportReq;
import com.campus.lostfound.modules.report.dto.ReportVO;
import com.campus.lostfound.modules.report.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "举报", description = "提交和查看举报")
@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {
    private final ReportService reportService;

    @Operation(summary = "提交举报")
    @PostMapping
    public Result<ReportVO> create(@RequestBody @Valid CreateReportReq req) {
        Long uid = UserContext.require();
        return Result.success(reportService.create(uid, req.getTargetType(), req.getTargetId(), req.getDescription()));
    }

    @Operation(summary = "查看我的举报")
    @GetMapping("/mine")
    public Result<List<ReportVO>> listMine() {
        Long uid = UserContext.require();
        return Result.success(reportService.listMine(uid));
    }
}
