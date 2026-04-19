package com.campus.lostfound.modules.item.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.campus.lostfound.modules.item.entity.Item;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface ItemMapper extends BaseMapper<Item> {

    @Update("UPDATE item SET like_count = GREATEST(0, like_count + #{delta}) WHERE id = #{id} AND deleted = 0")
    int adjustLikeCount(@Param("id") Long id, @Param("delta") int delta);
}
