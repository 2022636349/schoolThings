package com.campus.lostfound.modules.item.service.impl;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.campus.lostfound.common.exception.BusinessException;
import com.campus.lostfound.common.result.ResultCode;
import com.campus.lostfound.modules.item.dto.CreateItemReq;
import com.campus.lostfound.modules.item.dto.ItemCardVO;
import com.campus.lostfound.modules.item.dto.ItemPageVO;
import com.campus.lostfound.modules.item.dto.MediaDTO;
import com.campus.lostfound.modules.item.entity.Item;
import com.campus.lostfound.modules.item.entity.ItemLike;
import com.campus.lostfound.modules.item.entity.ItemMedia;
import com.campus.lostfound.modules.item.mapper.ItemLikeMapper;
import com.campus.lostfound.modules.item.mapper.ItemMapper;
import com.campus.lostfound.modules.item.mapper.ItemMediaMapper;
import com.campus.lostfound.modules.item.service.ItemService;
import com.campus.lostfound.modules.user.entity.User;
import com.campus.lostfound.modules.user.mapper.UserStatMapper;
import com.campus.lostfound.modules.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class ItemServiceImpl extends ServiceImpl<ItemMapper, Item> implements ItemService {

    private final ItemMediaMapper itemMediaMapper;
    private final ItemLikeMapper itemLikeMapper;
    private final UserService userService;
    private final UserStatMapper userStatMapper;

    @Override
    @Transactional
    public ItemCardVO createItem(Long publisherId, CreateItemReq req) {
        Item item = new Item();
        item.setPublisherId(publisherId);
        item.setType(req.getType());
        item.setTitle(StrUtil.blankToDefault(req.getTitle(),
                req.getDescription().length() > 20
                        ? req.getDescription().substring(0, 20)
                        : req.getDescription()));
        item.setDescription(req.getDescription());
        item.setCategoryName(StrUtil.blankToDefault(req.getCategory(), "其他"));
        item.setLocation(req.getLocation());
        if (req.getLostTime() != null && req.getLostTime() > 0) {
            item.setLostTime(LocalDateTime.ofInstant(
                    java.time.Instant.ofEpochMilli(req.getLostTime()),
                    ZoneId.systemDefault()));
        }
        item.setStatus("active");
        item.setViewCount(0);
        item.setLikeCount(0);
        item.setWarningExpireAt(LocalDateTime.now().plusDays(15));
        item.setAuditStatus(1);
        this.save(item);

        if (req.getMediaList() != null) {
            int sort = 0;
            for (MediaDTO m : req.getMediaList()) {
                ItemMedia media = new ItemMedia();
                media.setItemId(item.getId());
                media.setType(StrUtil.blankToDefault(m.getType(), "image"));
                media.setUrl(m.getUrl());
                media.setSort(sort++);
                media.setCreatedAt(LocalDateTime.now());
                itemMediaMapper.insert(media);
            }
        }

        userStatMapper.incrementPost(publisherId);
        return detail(item.getId());
    }

    @Override
    public ItemPageVO listByType(String type, Long lastId, int limit) {
        LambdaQueryWrapper<Item> qw = new LambdaQueryWrapper<>();
        if (!"all".equalsIgnoreCase(type)) {
            qw.eq(Item::getType, type);
        }
        if (lastId != null && lastId > 0) {
            qw.lt(Item::getId, lastId);
        }
        qw.orderByDesc(Item::getId).last("LIMIT " + sanitizeLimit(limit));
        List<Item> items = this.list(qw);
        return assemblePage(items, limit);
    }

    @Override
    public ItemPageVO listByCategory(String category, Long lastId, int limit) {
        LambdaQueryWrapper<Item> qw = new LambdaQueryWrapper<>();
        if (StrUtil.isNotBlank(category)) {
            qw.eq(Item::getCategoryName, category);
        }
        if (lastId != null && lastId > 0) {
            qw.lt(Item::getId, lastId);
        }
        qw.orderByDesc(Item::getId).last("LIMIT " + sanitizeLimit(limit));
        List<Item> items = this.list(qw);
        return assemblePage(items, limit);
    }

    @Override
    public ItemPageVO listMine(Long userId, Long lastId, int limit) {
        LambdaQueryWrapper<Item> qw = new LambdaQueryWrapper<Item>()
                .eq(Item::getPublisherId, userId);
        if (lastId != null && lastId > 0) {
            qw.lt(Item::getId, lastId);
        }
        qw.orderByDesc(Item::getId).last("LIMIT " + sanitizeLimit(limit));
        List<Item> items = this.list(qw);
        return assemblePage(items, limit);
    }

    @Override
    public ItemCardVO detail(Long itemId) {
        Item item = this.getById(itemId);
        if (item == null) throw new BusinessException(ResultCode.ITEM_NOT_FOUND);
        return enrich(Collections.singletonList(item)).get(0);
    }

    @Override
    @Transactional
    public ItemCardVO updateItem(Long itemId, Long currentUserId, CreateItemReq req) {
        Item item = this.getById(itemId);
        if (item == null) throw new BusinessException(ResultCode.ITEM_NOT_FOUND);
        if (!item.getPublisherId().equals(currentUserId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权编辑他人物品");
        }
        Item upd = new Item();
        upd.setId(itemId);
        upd.setType(req.getType());
        upd.setTitle(StrUtil.blankToDefault(req.getTitle(), item.getTitle()));
        upd.setDescription(req.getDescription());
        upd.setCategoryName(StrUtil.blankToDefault(req.getCategory(), "其他"));
        upd.setLocation(req.getLocation());
        upd.setContact(req.getContact());
        if (req.getLostTime() != null && req.getLostTime() > 0) {
            upd.setLostTime(LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(req.getLostTime()), ZoneId.systemDefault()));
        } else {
            upd.setLostTime(null);
        }
        this.updateById(upd);

        itemMediaMapper.delete(new LambdaQueryWrapper<ItemMedia>().eq(ItemMedia::getItemId, itemId));
        if (req.getMediaList() != null) {
            int sort = 0;
            for (MediaDTO m : req.getMediaList()) {
                ItemMedia media = new ItemMedia();
                media.setItemId(itemId);
                media.setType(StrUtil.blankToDefault(m.getType(), "image"));
                media.setUrl(m.getUrl());
                media.setSort(sort++);
                media.setCreatedAt(LocalDateTime.now());
                itemMediaMapper.insert(media);
            }
        }
        return detail(itemId);
    }

    @Override
    public ItemCardVO toVO(Item item) {
        return enrich(Collections.singletonList(item)).get(0);
    }

    @Override
    @Transactional
    public void updateStatus(Long itemId, Long currentUserId, String status) {
        Item item = this.getById(itemId);
        if (item == null) throw new BusinessException(ResultCode.ITEM_NOT_FOUND);
        if (!item.getPublisherId().equals(currentUserId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权操作他人物品");
        }
        Item upd = new Item();
        upd.setId(itemId);
        upd.setStatus(status);
        if ("claimed".equals(status)) {
            upd.setClaimedBy(currentUserId);
            upd.setClaimedAt(LocalDateTime.now());
        } else {
            upd.setClaimedBy(null);
            upd.setClaimedAt(null);
        }
        this.updateById(upd);
    }

    @Override
    @Transactional
    public void deleteItem(Long itemId, Long currentUserId) {
        Item item = this.getById(itemId);
        if (item == null) throw new BusinessException(ResultCode.ITEM_NOT_FOUND);
        if (!item.getPublisherId().equals(currentUserId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权删除他人物品");
        }
        this.removeById(itemId);
        // 媒体与点赞明细级联删除（物理删）
        itemMediaMapper.delete(new LambdaQueryWrapper<ItemMedia>().eq(ItemMedia::getItemId, itemId));
        itemLikeMapper.delete(new LambdaQueryWrapper<ItemLike>().eq(ItemLike::getItemId, itemId));
    }

    @Override
    public List<ItemCardVO> search(String keyword, int limit) {
        if (StrUtil.isBlank(keyword)) return Collections.emptyList();
        // 简单 LIKE（若开启 FULLTEXT 可改 MATCH AGAINST）
        QueryWrapper<Item> qw = new QueryWrapper<>();
        qw.and(w -> w.like("title", keyword).or().like("description", keyword))
                .orderByDesc("id")
                .last("LIMIT " + sanitizeLimit(limit));
        List<Item> items = this.list(qw);
        return enrich(items);
    }

    @Override
    public List<ItemCardVO> listHot(int limit) {
        LambdaQueryWrapper<Item> qw = new LambdaQueryWrapper<Item>()
                .orderByDesc(Item::getLikeCount)
                .orderByDesc(Item::getViewCount)
                .orderByDesc(Item::getId)
                .last("LIMIT " + sanitizeLimit(limit));
        List<Item> items = this.list(qw);
        return enrich(items);
    }

    @Override
    public List<ItemCardVO> listWarning(int limit) {
        LambdaQueryWrapper<Item> qw = new LambdaQueryWrapper<Item>()
                .and(w -> w.eq(Item::getStatus, "warning")
                        .or().le(Item::getWarningExpireAt, LocalDateTime.now()))
                .orderByAsc(Item::getWarningExpireAt)
                .orderByDesc(Item::getId)
                .last("LIMIT " + sanitizeLimit(limit));
        List<Item> items = this.list(qw);
        return enrich(items);
    }

    @Override
    public List<ItemCardVO> listLiked(Long userId, int limit) {
        List<ItemLike> likes = itemLikeMapper.selectList(new LambdaQueryWrapper<ItemLike>()
                .eq(ItemLike::getUserId, userId)
                .orderByDesc(ItemLike::getId)
                .last("LIMIT " + sanitizeLimit(limit)));
        if (likes.isEmpty()) return new ArrayList<>();
        List<Long> itemIds = new ArrayList<>();
        for (ItemLike like : likes) {
            itemIds.add(like.getItemId());
        }
        List<Item> items = this.listByIds(itemIds);
        List<ItemCardVO> cards = enrich(items);
        cards.sort((a, b) -> Integer.compare(itemIds.indexOf(a.getItemId()), itemIds.indexOf(b.getItemId())));
        return cards;
    }

    @Override
    @Transactional
    public boolean toggleLike(Long itemId, Long userId) {
        ItemLike existing = itemLikeMapper.selectOne(new LambdaQueryWrapper<ItemLike>()
                .eq(ItemLike::getItemId, itemId).eq(ItemLike::getUserId, userId));
        if (existing != null) {
            itemLikeMapper.deleteById(existing.getId());
            baseMapper.adjustLikeCount(itemId, -1);
            return false;
        }
        ItemLike like = new ItemLike();
        like.setItemId(itemId);
        like.setUserId(userId);
        like.setCreatedAt(LocalDateTime.now());
        try {
            itemLikeMapper.insert(like);
            baseMapper.adjustLikeCount(itemId, 1);
        } catch (DuplicateKeyException e) {
            // 并发插入，忽略
        }
        return true;
    }

    @Override
    public boolean hasLiked(Long itemId, Long userId) {
        Long count = itemLikeMapper.selectCount(new LambdaQueryWrapper<ItemLike>()
                .eq(ItemLike::getItemId, itemId).eq(ItemLike::getUserId, userId));
        return count != null && count > 0;
    }

    @Override
    @Transactional
    public void markClaimed(Long itemId, Long claimedByUserId) {
        Item item = this.getById(itemId);
        if (item == null) return;
        if ("claimed".equals(item.getStatus())) return;
        Item upd = new Item();
        upd.setId(itemId);
        upd.setStatus("claimed");
        upd.setClaimedBy(claimedByUserId);
        upd.setClaimedAt(LocalDateTime.now());
        this.updateById(upd);
        userStatMapper.incrementClaim(claimedByUserId);
        if (item.getPublisherId() != null && !item.getPublisherId().equals(claimedByUserId)) {
            userStatMapper.incrementReturn(item.getPublisherId());
        }
    }

    // ==== 私有辅助方法 ====

    private ItemPageVO assemblePage(List<Item> items, int limit) {
        List<ItemCardVO> list = enrich(items);
        ItemPageVO page = new ItemPageVO();
        page.setList(list);
        page.setHasMore(items.size() >= limit);
        page.setLastId(items.isEmpty() ? null : items.get(items.size() - 1).getId());
        return page;
    }

    /**
     * 批量补齐发布者信息 + 媒体列表
     */
    private List<ItemCardVO> enrich(List<Item> items) {
        if (items == null || items.isEmpty()) return new ArrayList<>();

        Set<Long> publisherIds = new HashSet<>();
        List<Long> itemIds = new ArrayList<>();
        for (Item it : items) {
            publisherIds.add(it.getPublisherId());
            itemIds.add(it.getId());
        }

        // 发布者 map
        Map<String, User> userMap = userService.batchGetByIds(new ArrayList<>(publisherIds));

        // 媒体 map: itemId → list
        Map<Long, List<MediaDTO>> mediaMap = new HashMap<>();
        if (!itemIds.isEmpty()) {
            List<ItemMedia> medias = itemMediaMapper.selectList(new LambdaQueryWrapper<ItemMedia>()
                    .in(ItemMedia::getItemId, itemIds)
                    .orderByAsc(ItemMedia::getSort));
            for (ItemMedia m : medias) {
                MediaDTO dto = new MediaDTO();
                dto.setType(m.getType());
                dto.setUrl(m.getUrl());
                mediaMap.computeIfAbsent(m.getItemId(), k -> new ArrayList<>()).add(dto);
            }
        }

        List<ItemCardVO> result = new ArrayList<>();
        for (Item it : items) {
            ItemCardVO vo = new ItemCardVO();
            vo.setItemId(it.getId());
            vo.setType(it.getType());
            vo.setTitle(it.getTitle());
            vo.setDescription(it.getDescription());
            vo.setLocation(it.getLocation());
            String baseText = StrUtil.blankToDefault(it.getTitle(), it.getDescription());
            if (StrUtil.isNotBlank(it.getDescription()) && !it.getDescription().equals(baseText)) {
                baseText = baseText + "\n" + it.getDescription();
            }
            vo.setText(StrUtil.isNotBlank(it.getLocation())
                    ? baseText + "\n地点：" + it.getLocation()
                    : baseText);
            vo.setPublishTime(toMillis(it.getCreatedAt()));
            vo.setPublishId(String.valueOf(it.getPublisherId()));
            User publisher = userMap.get(String.valueOf(it.getPublisherId()));
            vo.setPublisherName(publisher != null ? publisher.getNickname() : "匿名用户");
            vo.setPublisherAvatar(publisher != null ? publisher.getAvatar() : null);
            vo.setMediaList(mediaMap.getOrDefault(it.getId(), Collections.emptyList()));
            vo.setCategory(StrUtil.blankToDefault(it.getCategoryName(), "其他"));
            vo.setLikeCount(it.getLikeCount() == null ? 0 : it.getLikeCount());
            vo.setStatus(StrUtil.blankToDefault(it.getStatus(), "active"));
            vo.setClaimedBy(it.getClaimedBy() == null ? null : String.valueOf(it.getClaimedBy()));
            vo.setLostTime(toMillis(it.getLostTime()));
            result.add(vo);
        }
        return result;
    }

    private long toMillis(LocalDateTime t) {
        return t == null ? 0L : t.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
    }

    private int sanitizeLimit(int limit) {
        if (limit <= 0) return 10;
        return Math.min(limit, 50);
    }
}
