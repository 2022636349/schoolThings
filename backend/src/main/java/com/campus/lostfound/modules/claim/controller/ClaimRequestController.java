package com.campus.lostfound.modules.claim.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.claim.dto.ClaimRequestVO;
import com.campus.lostfound.modules.claim.dto.CreateClaimRequestReq;
import com.campus.lostfound.modules.claim.service.ClaimRequestService;
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

@Tag(name = "认领申请", description = "提交和查看认领申请")
@RestController
@RequestMapping("/claim-requests")
@RequiredArgsConstructor
public class ClaimRequestController {
    private final ClaimRequestService claimRequestService;

    @Operation(summary = "提交认领申请")
    @PostMapping
    public Result<ClaimRequestVO> create(@RequestBody @Valid CreateClaimRequestReq req) {
        Long uid = UserContext.require();
        return Result.success(claimRequestService.create(uid, req.getItemId(), req.getDescription()));
    }

    @Operation(summary = "查看我的认领申请")
    @GetMapping("/mine")
    public Result<List<ClaimRequestVO>> listMine() {
        Long uid = UserContext.require();
        return Result.success(claimRequestService.listMine(uid));
    }
}
