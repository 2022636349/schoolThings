package com.campus.lostfound.modules.report.service;

import com.campus.lostfound.modules.report.dto.ReportVO;

import java.util.List;

public interface ReportService {
    ReportVO create(Long reporterId, String targetType, Long targetId, String description);
    List<ReportVO> listMine(Long reporterId);
}
