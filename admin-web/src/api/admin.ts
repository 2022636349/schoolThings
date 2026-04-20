import http from './http'

export interface AdminPage<T> {
  total: number
  current: number
  size: number
  records: T[]
}

export interface DashboardTrend {
  date: string
  userCount: number
  itemCount: number
  claimCount: number
  reportCount: number
}

export interface DashboardStats {
  userCount: number
  itemCount: number
  claimCount: number
  reportCount: number
  pendingClaimCount: number
  pendingReportCount: number
  trends: DashboardTrend[]
  recentAnnouncements: AdminAnnouncement[]
  recentItems: AdminItem[]
  recentReports: AdminReport[]
}

export interface AdminUser {
  id: number
  studentNo: string
  nickname: string
  phone: string
  status: number
  createdAt: number
  heartValue: number
  fraudValue: number
  postCount: number
  claimCount: number
  returnCount: number
  likeReceived: number
}

export interface AdminItem {
  id: number
  title: string
  type: string
  status: string
  publisherId: string
  publisherName: string
  location: string
  createdAt: number
  lostTime: number
  likeCount: number
  images: string[]
}

export interface AdminAnnouncement {
  id: number
  title: string
  content: string
  cover: string
  status: string
  priority: number
  publishFrom: number
  publishTo: number
  createdAt: number
  viewCount: number
}

export interface AdminClaim {
  id: number
  itemId: number
  itemTitle: string
  itemStatus: string
  description: string
  contact: string
  status: string
  claimantId: string
  claimantName: string
  publisherId: string
  publisherName: string
  reviewRemark: string
  createdAt: number
  approvedAt: number
}

export interface AdminReport {
  id: number
  targetType: string
  targetId: number
  targetTitle: string
  reporterId: string
  reporterName: string
  reason: string
  description: string
  evidenceUrls: string
  status: string
  resolution: string
  createdAt: number
}

export interface AdminFeedback {
  id: number
  userId: string
  userName: string
  content: string
  result: string
  createdAt: number
}

export interface AdminChatSession {
  id: number
  itemId: number
  itemTitle: string
  initiatorId: string
  initiatorName: string
  ownerId: string
  ownerName: string
  lastMessage: string
  lastMessageAt: number
}

export interface AdminProfile {
  id: number
  username: string
  nickname: string
  role: string
}

export interface AdminLoginResp {
  token: string
  username: string
  role?: string
}

export const adminApi = {
  login(data: { username: string; password: string }): Promise<AdminLoginResp> {
    return http.post('/admin/auth/login', data) as unknown as Promise<AdminLoginResp>
  },
  profile(): Promise<AdminProfile> {
    return http.get('/admin/profile') as unknown as Promise<AdminProfile>
  },
  changePassword(data: { oldPassword: string; newPassword: string }): Promise<void> {
    return http.post('/admin/profile/password', data) as unknown as Promise<void>
  },
  dashboardStats(): Promise<DashboardStats> {
    return http.get('/admin/dashboard/stats') as unknown as Promise<DashboardStats>
  },
  users(params?: { keyword?: string; status?: number; current?: number; size?: number }): Promise<AdminPage<AdminUser>> {
    return http.get('/admin/users', { params }) as unknown as Promise<AdminPage<AdminUser>>
  },
  updateUserStatus(id: number, status: number): Promise<void> {
    return http.post(`/admin/users/${id}/status`, { status }) as unknown as Promise<void>
  },
  items(params?: { keyword?: string; type?: string; status?: string; current?: number; size?: number }): Promise<AdminPage<AdminItem>> {
    return http.get('/admin/items', { params }) as unknown as Promise<AdminPage<AdminItem>>
  },
  updateItemStatus(id: number, status: string): Promise<void> {
    return http.post(`/admin/items/${id}/status`, { status }) as unknown as Promise<void>
  },
  deleteItem(id: number): Promise<void> {
    return http.delete(`/admin/items/${id}`) as unknown as Promise<void>
  },
  batchDeleteItems(ids: number[]): Promise<void> {
    return http.post('/admin/items/batch-delete', { ids }) as unknown as Promise<void>
  },
  announcements(): Promise<AdminAnnouncement[]> {
    return http.get('/admin/announcements') as unknown as Promise<AdminAnnouncement[]>
  },
  saveAnnouncement(data: { id?: number; title: string; content: string; cover?: string; priority?: number; status?: string; publishFrom?: number; publishTo?: number }): Promise<void> {
    return http.post('/admin/announcements', data) as unknown as Promise<void>
  },
  deleteAnnouncement(id: number): Promise<void> {
    return http.delete(`/admin/announcements/${id}`) as unknown as Promise<void>
  },
  feedbacks(): Promise<AdminFeedback[]> {
    return http.get('/admin/feedbacks') as unknown as Promise<AdminFeedback[]>
  },
  updateFeedbackResult(id: number, result: string): Promise<void> {
    return http.post(`/admin/feedbacks/${id}/result`, { result }) as unknown as Promise<void>
  },
  chatSessions(): Promise<AdminChatSession[]> {
    return http.get('/admin/chat/sessions') as unknown as Promise<AdminChatSession[]>
  },
  exportOverview(): Promise<string> {
    return http.get('/admin/export/overview') as unknown as Promise<string>
  },
  claims(): Promise<AdminClaim[]> {
    return http.get('/admin/claims') as unknown as Promise<AdminClaim[]>
  },
  reviewClaim(id: number, status: string, remark?: string): Promise<void> {
    return http.post(`/admin/claims/${id}/status`, { status, remark }) as unknown as Promise<void>
  },
  reports(): Promise<AdminReport[]> {
    return http.get('/admin/reports') as unknown as Promise<AdminReport[]>
  },
  reviewReport(id: number, data: { status: string; resolution?: string; itemStatus?: string; userStatus?: number }): Promise<void> {
    return http.post(`/admin/reports/${id}/status`, data) as unknown as Promise<void>
  }
}