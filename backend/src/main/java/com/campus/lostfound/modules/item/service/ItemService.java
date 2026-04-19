package com.campus.lostfound.modules.item.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.campus.lostfound.modules.item.dto.CreateItemReq;
import com.campus.lostfound.modules.item.dto.ItemCardVO;
import com.campus.lostfound.modules.item.dto.ItemPageVO;
import com.campus.lostfound.modules.item.entity.Item;

import java.util.List;

public interface ItemService extends IService<Item> {

    ItemCardVO createItem(Long publisherId, CreateItemReq req);

    ItemPageVO listByType(String type, Long lastId, int limit);

    ItemPageVO listByCategory(String category, Long lastId, int limit);

    ItemPageVO listMine(Long userId, Long lastId, int limit);

    ItemCardVO detail(Long itemId);

    ItemCardVO updateItem(Long itemId, Long currentUserId, CreateItemReq req);

    void deleteItem(Long itemId, Long currentUserId);

    void updateStatus(Long itemId, Long currentUserId, String status);

    List<ItemCardVO> search(String keyword, int limit);

    List<ItemCardVO> listHot(int limit);

    List<ItemCardVO> listWarning(int limit);

    List<ItemCardVO> listLiked(Long userId, int limit);

    /** @return 最新点赞状态 */
    boolean toggleLike(Long itemId, Long userId);

    boolean hasLiked(Long itemId, Long userId);

    /** 将物品标记为已认领（聊天双方确认后） */
    void markClaimed(Long itemId, Long claimedByUserId);

    /** 将 Item 转换为 VO（用于聊天窗口展示） */
    ItemCardVO toVO(Item item);
}
