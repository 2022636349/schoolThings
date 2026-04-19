package com.campus.lostfound.modules.announcement.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.lostfound.modules.announcement.dto.AnnouncementVO;
import com.campus.lostfound.modules.announcement.entity.Announcement;
import com.campus.lostfound.modules.announcement.mapper.AnnouncementMapper;
import com.campus.lostfound.modules.announcement.service.AnnouncementService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AnnouncementServiceImpl implements AnnouncementService {
    private final AnnouncementMapper announcementMapper;

    @Override
    public List<AnnouncementVO> listPublished(int limit) {
        LocalDateTime now = LocalDateTime.now();
        List<Announcement> list = announcementMapper.selectList(new LambdaQueryWrapper<Announcement>()
                .eq(Announcement::getStatus, "published")
                .and(w -> w.isNull(Announcement::getPublishFrom).or().le(Announcement::getPublishFrom, now))
                .and(w -> w.isNull(Announcement::getPublishTo).or().ge(Announcement::getPublishTo, now))
                .orderByDesc(Announcement::getPriority)
                .orderByDesc(Announcement::getId)
                .last("LIMIT " + Math.min(Math.max(limit, 1), 10)));
        List<AnnouncementVO> result = new ArrayList<>();
        for (Announcement item : list) {
            result.add(toVO(item));
        }
        return result;
    }

    @Override
    public AnnouncementVO detail(Long id) {
        Announcement item = announcementMapper.selectById(id);
        return item == null ? null : toVO(item);
    }

    private AnnouncementVO toVO(Announcement item) {
        AnnouncementVO vo = new AnnouncementVO();
        vo.setId(item.getId());
        vo.setTitle(item.getTitle());
        vo.setContent(item.getContent());
        vo.setCover(item.getCover());
        vo.setPriority(item.getPriority());
        vo.setCreatedAt(item.getCreatedAt() == null ? 0L : item.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        return vo;
    }
}
