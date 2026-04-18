/**
 * 物品分类枚举
 * 发布/筛选/搜索共用
 */
export const ITEM_CATEGORIES: string[] = [
  '数码', '证件', '卡类', '衣物', '钥匙', '书籍', '其他'
];

export const CATEGORY_ALL = '全部';

/**
 * 根据 ItemInfo 的 type + status 字段推导实际展示状态
 * 兼容旧数据（老数据 type='claimed' 但无 status 字段）
 */
export type DisplayStatus = 'active' | 'pending' | 'claimed' | 'warning' | 'offline';

export function deriveStatus(type: string, status: string | null | undefined): DisplayStatus {
  if (status && status.length > 0) {
    if (status === 'active' || status === 'pending' || status === 'claimed'
      || status === 'warning' || status === 'offline') {
      return status;
    }
  }
  // 旧数据兜底：type === 'claimed' 视为已认领
  if (type === 'claimed') return 'claimed';
  return 'active';
}

/**
 * 获取展示标签（考虑 type 方向）
 *   type='lost' + status='active' → '寻物中'
 *   type='find' + status='active' → '招领中'
 *   status='claimed' + type='lost' → '已找到'
 *   status='claimed' + type='find' → '已认领'
 */
export function getStatusLabel(type: string, status: DisplayStatus): string {
  if (status === 'warning') return '处理预警';
  if (status === 'offline') return '已下架';
  if (status === 'pending') return '申请待确认';
  if (status === 'claimed') {
    return type === 'lost' ? '已找到' : '已认领';
  }
  // active
  return type === 'lost' ? '寻物中' : '招领中';
}

export function getStatusColor(status: DisplayStatus): string {
  if (status === 'warning') return '#FF9500';
  if (status === 'offline') return '#999999';
  if (status === 'pending') return '#AF52DE';
  if (status === 'claimed') return '#4CAF50';
  return '#4E8FDF';
}

export function getStatusBg(status: DisplayStatus): string {
  if (status === 'warning') return '#FFF3E0';
  if (status === 'offline') return '#F0F0F0';
  if (status === 'pending') return '#F3EEFF';
  if (status === 'claimed') return '#E8F5E9';
  return '#EBF3FF';
}
