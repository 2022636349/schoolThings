package com.campus.lostfound.modules.user.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("user_stat")
public class UserStat implements Serializable {

    @TableId
    private Long userId;

    private Integer heartValue;
    private Integer fraudValue;
    private Integer postCount;
    private Integer claimCount;
    private Integer returnCount;
    private Integer likeReceived;
    private LocalDateTime updatedAt;
}
