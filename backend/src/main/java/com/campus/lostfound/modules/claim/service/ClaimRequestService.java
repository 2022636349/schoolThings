package com.campus.lostfound.modules.claim.service;

import com.campus.lostfound.modules.claim.dto.ClaimRequestVO;

import java.util.List;

public interface ClaimRequestService {
    ClaimRequestVO create(Long claimantId, Long itemId, String description);
    List<ClaimRequestVO> listMine(Long claimantId);
}
