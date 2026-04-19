package com.campus.lostfound.modules.announcement.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.modules.announcement.dto.AnnouncementVO;
import com.campus.lostfound.modules.announcement.service.AnnouncementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "公告", description = "公告列表和详情")
@RestController
@RequestMapping("/announcements")
@RequiredArgsConstructor
public class AnnouncementController {
    private final AnnouncementService announcementService;

    @Operation(summary = "已发布公告列表")
    @GetMapping
    public Result<List<AnnouncementVO>> list(@RequestParam(value = "limit", defaultValue = "5") int limit) {
        return Result.success(announcementService.listPublished(limit));
    }

    @Operation(summary = "公告详情")
    @GetMapping("/{id}")
    public Result<AnnouncementVO> detail(@PathVariable("id") Long id) {
        return Result.success(announcementService.detail(id));
    }
}
