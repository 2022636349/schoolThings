export const ITEM_CATEGORIES: string[] = [
  '数码', '证件', '卡类', '衣物', '钥匙', '书籍', '其他'
];

export const CATEGORY_ALL = '全部';

export type DisplayStatus = 'active' | 'pending' | 'claimed' | 'warning' | 'offline';

export function deriveStatus(type: string, status: string | null | undefined): DisplayStatus {
  if (status && status.length > 0) {
    if (status === 'active' || status === 'pending' || status === 'claimed'
      || status === 'warning' || status === 'offline') {
      return status;
    }
  }

  if (type === 'claimed') return 'claimed';
  return 'active';
}

export function getStatusLabel(type: string, status: DisplayStatus): string {
  if (status === 'warning') return '处理预警';
  if (status === 'offline') return '已下架';
  if (status === 'pending') return '申请待确认';
  if (status === 'claimed') return '已认领';

  return type === 'found' ? '招领中' : '寻物中';
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
