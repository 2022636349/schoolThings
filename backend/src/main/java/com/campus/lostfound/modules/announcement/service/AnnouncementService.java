package com.campus.lostfound.modules.announcement.service;

import com.campus.lostfound.modules.announcement.dto.AnnouncementVO;

import java.util.List;

public interface AnnouncementService {
    List<AnnouncementVO> listPublished(int limit);
    AnnouncementVO detail(Long id);
}
