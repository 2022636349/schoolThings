package com.campus.lostfound.modules.user.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.campus.lostfound.modules.user.entity.UserStat;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface UserStatMapper extends BaseMapper<UserStat> {

    /** 发布计数 +1（不存在时由业务层初始化） */
    @Update("INSERT INTO user_stat(user_id, post_count, updated_at) VALUES(#{uid}, 1, NOW()) " +
            "ON DUPLICATE KEY UPDATE post_count = post_count + 1, updated_at = NOW()")
    int incrementPost(@Param("uid") Long userId);

    @Update("INSERT INTO user_stat(user_id, claim_count, updated_at) VALUES(#{uid}, 1, NOW()) " +
            "ON DUPLICATE KEY UPDATE claim_count = claim_count + 1, updated_at = NOW()")
    int incrementClaim(@Param("uid") Long userId);

    @Update("INSERT INTO user_stat(user_id, return_count, updated_at) VALUES(#{uid}, 1, NOW()) " +
            "ON DUPLICATE KEY UPDATE return_count = return_count + 1, updated_at = NOW()")
    int incrementReturn(@Param("uid") Long userId);
}
