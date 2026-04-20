package com.campus.lostfound.modules.admin.dto;

import lombok.Data;

import java.util.List;

@Data
public class DashboardStatsVO {
    private Long userCount;
    private Long itemCount;
    private Long claimCount;
    private Long reportCount;
    private Long pendingClaimCount;
    private Long pendingReportCount;
    private List<AdminTrendVO> trends;
    private List<AdminAnnouncementVO> recentAnnouncements;
    private List<AdminItemVO> recentItems;
    private List<AdminReportVO> recentReports;
}
