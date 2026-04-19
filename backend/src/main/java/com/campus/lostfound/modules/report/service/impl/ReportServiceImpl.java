package com.campus.lostfound.modules.report.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.lostfound.modules.report.dto.ReportVO;
import com.campus.lostfound.modules.report.entity.Report;
import com.campus.lostfound.modules.report.mapper.ReportMapper;
import com.campus.lostfound.modules.report.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {
    private final ReportMapper reportMapper;

    @Override
    public ReportVO create(Long reporterId, String targetType, Long targetId, String description) {
        Report report = new Report();
        report.setTargetType(targetType);
        report.setTargetId(targetId);
        report.setReporterId(reporterId);
        report.setReason("user_submit");
        report.setDescription(description);
        report.setStatus("pending");
        report.setCreatedAt(LocalDateTime.now());
        report.setUpdatedAt(LocalDateTime.now());
        reportMapper.insert(report);
        return toVO(report);
    }

    @Override
    public List<ReportVO> listMine(Long reporterId) {
        List<Report> list = reportMapper.selectList(new LambdaQueryWrapper<Report>()
                .eq(Report::getReporterId, reporterId)
                .orderByDesc(Report::getId));
        List<ReportVO> result = new ArrayList<>();
        for (Report report : list) {
            result.add(toVO(report));
        }
        return result;
    }

    private ReportVO toVO(Report report) {
        ReportVO vo = new ReportVO();
        vo.setId(report.getId());
        vo.setTargetType(report.getTargetType());
        vo.setTargetId(report.getTargetId());
        vo.setReporterId(report.getReporterId() == null ? null : String.valueOf(report.getReporterId()));
        vo.setDescription(report.getDescription());
        vo.setStatus(report.getStatus());
        vo.setCreatedAt(report.getCreatedAt() == null ? 0L : report.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        return vo;
    }
}
