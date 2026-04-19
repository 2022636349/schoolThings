package com.campus.lostfound.modules.claim.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.modules.claim.dto.ClaimRequestVO;
import com.campus.lostfound.modules.claim.entity.ClaimRequest;
import com.campus.lostfound.modules.claim.mapper.ClaimRequestMapper;
import com.campus.lostfound.modules.claim.service.ClaimRequestService;
import com.campus.lostfound.modules.item.entity.Item;
import com.campus.lostfound.modules.item.service.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ClaimRequestServiceImpl implements ClaimRequestService {
    private final ClaimRequestMapper claimRequestMapper;
    private final ItemService itemService;

    @Override
    public ClaimRequestVO create(Long claimantId, Long itemId, String description) {
        Item item = itemService.getById(itemId);
        if (item == null) {
            throw new BusinessException(ResultCode.ITEM_NOT_FOUND);
        }
        ClaimRequest existing = claimRequestMapper.selectOne(new LambdaQueryWrapper<ClaimRequest>()
                .eq(ClaimRequest::getItemId, itemId)
                .eq(ClaimRequest::getClaimantId, claimantId)
                .eq(ClaimRequest::getStatus, "pending")
                .last("LIMIT 1"));
        if (existing != null) {
            throw new BusinessException(ResultCode.CLAIM_ALREADY_EXISTS);
        }
        ClaimRequest req = new ClaimRequest();
        req.setItemId(itemId);
        req.setClaimantId(claimantId);
        req.setPublisherId(item.getPublisherId());
        req.setDescription(description);
        req.setStatus("pending");
        req.setCreatedAt(LocalDateTime.now());
        req.setUpdatedAt(LocalDateTime.now());
        claimRequestMapper.insert(req);
        return toVO(req);
    }

    @Override
    public List<ClaimRequestVO> listMine(Long claimantId) {
        List<ClaimRequest> list = claimRequestMapper.selectList(new LambdaQueryWrapper<ClaimRequest>()
                .eq(ClaimRequest::getClaimantId, claimantId)
                .orderByDesc(ClaimRequest::getId));
        List<ClaimRequestVO> result = new ArrayList<>();
        for (ClaimRequest item : list) {
            result.add(toVO(item));
        }
        return result;
    }

    private ClaimRequestVO toVO(ClaimRequest item) {
        ClaimRequestVO vo = new ClaimRequestVO();
        vo.setId(item.getId());
        vo.setItemId(item.getItemId());
        vo.setClaimantId(item.getClaimantId() == null ? null : String.valueOf(item.getClaimantId()));
        vo.setPublisherId(item.getPublisherId() == null ? null : String.valueOf(item.getPublisherId()));
        vo.setDescription(item.getDescription());
        vo.setStatus(item.getStatus());
        Item linked = itemService.getById(item.getItemId());
        if (linked != null) {
            vo.setItemTitle(linked.getTitle());
            vo.setItemStatus(linked.getStatus());
        }
        vo.setCreatedAt(item.getCreatedAt() == null ? 0L : item.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        return vo;
    }
}
