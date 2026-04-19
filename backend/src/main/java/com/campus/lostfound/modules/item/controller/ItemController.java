package com.campus.lostfound.modules.item.controller;

import com.campus.lostfound.common.result.Result;
import com.campus.lostfound.common.util.UserContext;
import com.campus.lostfound.modules.item.dto.CreateItemReq;
import com.campus.lostfound.modules.item.dto.ItemCardVO;
import com.campus.lostfound.modules.item.dto.ItemPageVO;
import com.campus.lostfound.modules.item.service.ItemService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "物品", description = "失物招领物品 CRUD / 点赞 / 搜索")
@RestController
@RequestMapping("/items")
@RequiredArgsConstructor
public class ItemController {

    private final ItemService itemService;

    @Operation(summary = "按类型分页列表")
    @GetMapping
    public Result<ItemPageVO> list(
            @RequestParam(value = "type", defaultValue = "all") String type,
            @RequestParam(value = "lastId", required = false) Long lastId,
            @RequestParam(value = "limit", defaultValue = "10") int limit) {
        return Result.success(itemService.listByType(type, lastId, limit));
    }

    @Operation(summary = "按分类分页列表")
    @GetMapping("/category")
    public Result<ItemPageVO> listByCategory(
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "lastId", required = false) Long lastId,
            @RequestParam(value = "limit", defaultValue = "20") int limit) {
        return Result.success(itemService.listByCategory(category, lastId, limit));
    }

    @Operation(summary = "我发布的物品")
    @GetMapping("/mine")
    public Result<ItemPageVO> listMine(
            @RequestParam(value = "lastId", required = false) Long lastId,
            @RequestParam(value = "limit", defaultValue = "20") int limit) {
        Long uid = UserContext.require();
        return Result.success(itemService.listMine(uid, lastId, limit));
    }

    @Operation(summary = "关键词搜索")
    @GetMapping("/search")
    public Result<List<ItemCardVO>> search(
            @RequestParam("keyword") String keyword,
            @RequestParam(value = "limit", defaultValue = "30") int limit) {
        return Result.success(itemService.search(keyword, limit));
    }

    @Operation(summary = "热门推荐")
    @GetMapping("/hot")
    public Result<List<ItemCardVO>> hot(@RequestParam(value = "limit", defaultValue = "5") int limit) {
        return Result.success(itemService.listHot(limit));
    }

    @Operation(summary = "失物处理预警")
    @GetMapping("/warning")
    public Result<List<ItemCardVO>> warning(@RequestParam(value = "limit", defaultValue = "20") int limit) {
        return Result.success(itemService.listWarning(limit));
    }

    @Operation(summary = "我点赞的物品")
    @GetMapping("/liked")
    public Result<List<ItemCardVO>> liked(@RequestParam(value = "limit", defaultValue = "50") int limit) {
        Long uid = UserContext.require();
        return Result.success(itemService.listLiked(uid, limit));
    }

    @Operation(summary = "详情")
    @GetMapping("/{id}")
    public Result<ItemCardVO> detail(@PathVariable("id") Long id) {
        return Result.success(itemService.detail(id));
    }

    @Operation(summary = "发布")
    @PostMapping
    public Result<ItemCardVO> create(@RequestBody @Valid CreateItemReq req) {
        Long uid = UserContext.require();
        return Result.success(itemService.createItem(uid, req));
    }

    @Operation(summary = "编辑")
    @PutMapping("/{id}")
    public Result<ItemCardVO> update(@PathVariable("id") Long id, @RequestBody @Valid CreateItemReq req) {
        Long uid = UserContext.require();
        return Result.success(itemService.updateItem(id, uid, req));
    }

    @Operation(summary = "删除")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable("id") Long id) {
        Long uid = UserContext.require();
        itemService.deleteItem(id, uid);
        return Result.success();
    }

    @Operation(summary = "更新自己帖子状态")
    @PostMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable("id") Long id, @RequestBody UpdateStatusReq req) {
        Long uid = UserContext.require();
        itemService.updateStatus(id, uid, req.getStatus());
        return Result.success();
    }

    @Operation(summary = "点赞切换")
    @PostMapping("/{id}/like")
    public Result<Map<String, Object>> toggleLike(@PathVariable("id") Long id) {
        Long uid = UserContext.require();
        boolean liked = itemService.toggleLike(id, uid);
        Map<String, Object> m = new HashMap<>();
        m.put("liked", liked);
        return Result.success(m);
    }

    @Operation(summary = "当前用户是否点赞过")
    @GetMapping("/{id}/liked")
    public Result<Boolean> hasLiked(@PathVariable("id") Long id) {
        Long uid = UserContext.require();
        return Result.success(itemService.hasLiked(id, uid));
    }

    @Data
    public static class UpdateStatusReq {
        private String status;
    }

    @Data
    public static class LikeResp {
        private boolean liked;
        private Integer count;
    }
}
