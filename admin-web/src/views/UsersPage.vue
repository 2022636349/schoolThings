<template>
  <el-card class="table-card" shadow="never">
    <template #header>
      <div class="card-header">
        <div class="header-title">
          <span class="title-dot"></span>
          <span>用户管理</span>
        </div>
        <div class="toolbar">
          <el-input v-model="query.keyword" clearable placeholder="搜索学号/昵称/手机号" class="search-input"
            @keyup.enter="loadRows(1)">
            <template #prefix>
              <el-icon>
                <Search />
              </el-icon>
            </template>
          </el-input>
          <el-select v-model="query.status" clearable placeholder="账号状态" class="status-select">
            <el-option label="正常" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
          <el-button type="primary" @click="loadRows(1)">
            <el-icon class="mr-4">
              <Search />
            </el-icon>查询
          </el-button>
          <el-button @click="resetQuery">重置</el-button>
        </div>
      </div>
    </template>

    <el-table :data="rows" v-loading="loading" class="modern-table"
      :header-cell-style="{ background: '#f8f9fa', color: '#606266', fontWeight: 600 }">
      <el-table-column prop="id" label="ID" width="80" align="center" />
      <el-table-column prop="studentNo" label="学号" min-width="130" />
      <el-table-column prop="nickname" label="昵称" min-width="120">
        <template #default="scope">
          <div class="user-nickname">{{ scope.row.nickname }}</div>
        </template>
      </el-table-column>
      <el-table-column prop="phone" label="手机号" min-width="140" />
      <el-table-column label="注册时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.createdAt) }}</template>
      </el-table-column>
      <el-table-column prop="heartValue" label="热心值" width="90" align="center">
        <template #default="scope">
          <span>{{ scope.row.heartValue }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="fraudValue" label="异常值" width="90" align="center">
        <template #default="scope">
          <span :class="scope.row.fraudValue > 0 ? 'danger-text' : ''">{{ scope.row.fraudValue }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="postCount" label="发布数" width="90" align="center" />
      <el-table-column label="状态" width="100" align="center">
        <template #default="scope">
          <el-tag :type="scope.row.status === 1 ? 'success' : 'danger'" effect="light" size="small">
            {{ scope.row.status === 1 ? '正常' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" fixed="right" align="center">
        <template #default="scope">
          <el-button link type="primary" size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button link type="warning" size="small" @click="toggleStatus(scope.row)">
            {{ scope.row.status === 1 ? '禁用' : '恢复' }}
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pager">
      <el-pagination v-model:current-page="query.current" v-model:page-size="query.size"
        layout="total, prev, pager, next, sizes" :page-sizes="[10, 20, 50]" :total="total" @current-change="loadRows"
        @size-change="() => loadRows(1)" />
    </div>
  </el-card>

  <!-- 详情弹窗 -->
  <el-dialog v-model="detailVisible" width="700px" :close-on-click-modal="false" class="detail-dialog" center>
    <template #header>
      <span class="dialog-title-bold">用户详情</span>
    </template>
    <div v-if="currentRow" class="detail-content">
      <!-- 顶部用户卡片 -->
      <div class="user-profile-card">
        <div class="avatar-wrapper">
          <div class="avatar-placeholder">
            {{ currentRow.nickname.charAt(0).toUpperCase() }}
          </div>
        </div>
        <div class="user-basic-info">
          <div class="info-row">
            <span class="label">昵称：</span>
            <span class="value nickname-text">{{ currentRow.nickname }}</span>
          </div>
          <div class="info-row">
            <span class="label">学号：</span>
            <span class="value">{{ currentRow.studentNo }}</span>
          </div>
          <div class="info-row">
            <span class="label">手机号：</span>
            <span class="value">{{ currentRow.phone || '-' }}</span>
          </div>
          <div class="info-row">
            <span class="label">状态：</span>
            <el-tag :type="currentRow.status === 1 ? 'success' : 'danger'" size="small" effect="dark">
              {{ currentRow.status === 1 ? '正常' : '禁用' }}
            </el-tag>
          </div>
        </div>
      </div>

      <!-- 底部数据网格 -->
      <div class="stats-grid">
        <div class="stat-item">
          <div class="stat-label">注册时间</div>
          <div class="stat-value text">{{ formatTime(currentRow.createdAt) }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">发布帖子</div>
          <div class="stat-value">{{ currentRow.postCount }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">归还物品</div>
          <div class="stat-value">{{ currentRow.returnCount }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">获得点赞</div>
          <div class="stat-value">{{ currentRow.likeReceived }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">当前热心值</div>
          <div class="stat-value primary">{{ currentRow.heartValue }}</div>
        </div>
        <div class="stat-item" :class="{ 'danger-border': currentRow.fraudValue > 0 }">
          <div class="stat-label">异常记录</div>
          <div class="stat-value" :class="currentRow.fraudValue > 0 ? 'danger' : ''">{{ currentRow.fraudValue }}</div>
        </div>
      </div>
    </div>
  </el-dialog>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { adminApi, type AdminUser } from '../api/admin'

const rows = ref<AdminUser[]>([])
const loading = ref(false)
const total = ref(0)
const detailVisible = ref(false)
const currentRow = ref<AdminUser | null>(null)
const query = reactive({
  keyword: '',
  status: undefined as number | undefined,
  current: 1,
  size: 10
})

const loadRows = async (page?: number) => {
  if (typeof page === 'number') {
    query.current = page
  }
  loading.value = true
  try {
    const data = await adminApi.users(query)
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const resetQuery = async () => {
  query.keyword = ''
  query.status = undefined
  query.current = 1
  query.size = 10
  await loadRows(1)
}

const toggleStatus = async (row: AdminUser) => {
  const next = row.status === 1 ? 0 : 1
  await adminApi.updateUserStatus(row.id, next)
  await loadRows()
}

const showDetail = (row: AdminUser) => {
  currentRow.value = row
  detailVisible.value = true
}

const formatTime = (value: number) => {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

onMounted(() => loadRows(1))
</script>

<style scoped>
.table-card {
  border-radius: 12px;
  border: none;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.header-title {
  display: flex;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.title-dot {
  width: 4px;
  height: 16px;
  background: #409eff;
  border-radius: 2px;
  margin-right: 8px;
}

.toolbar {
  display: flex;
  gap: 12px;
  align-items: center;
}

.search-input {
  width: 240px;
}

.status-select {
  width: 130px;
}

.modern-table {
  --el-table-tr-bg-color: #fff;
  --el-table-header-bg-color: #f8f9fa;
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-table--border th),
:deep(.el-table--border td) {
  border-right: none;
}

:deep(.el-table--border::after),
:deep(.el-table--border::before) {
  background-color: transparent;
}

:deep(.el-table th) {
  border-bottom: 1px solid #ebeef5;
}

:deep(.el-table td) {
  border-bottom: 1px solid #ebeef5;
}

.user-nickname {
  font-weight: 500;
  color: #303133;
}

.danger-text {
  color: #f56c6c;
  font-weight: 600;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 24px;
}

.dialog-title-bold {
  font-size: 16px;
  font-weight: 700;
  color: #303133;
}

.mr-4 {
  margin-right: 4px;
}

.detail-content {
  padding: 10px 5px;
}

.user-profile-card {
  display: flex;
  gap: 24px;
  padding: 24px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  border-radius: 12px;
  border: 1px solid #ebeef5;
  margin-bottom: 24px;
  align-items: center;
}

.avatar-wrapper {
  flex-shrink: 0;
}

.avatar-placeholder {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409eff 0%, #79bbff 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  font-weight: bold;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
  font-family: 'Helvetica Neue', Helvetica, sans-serif;
}

.user-basic-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-row {
  display: flex;
  align-items: center;
  font-size: 15px;
}

.label {
  color: #909399;
  width: 70px;
  flex-shrink: 0;
}

.value {
  color: #303133;
  font-weight: 500;
}

.nickname-text {
  font-size: 18px;
  color: #303133;
  font-weight: 600;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.stat-item {
  background: #fff;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 16px;
  text-align: center;
  transition: all 0.3s ease;
}

.stat-item:hover {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
  border-color: #dcdfe6;
}

.stat-label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
}

.stat-value {
  font-size: 20px;
  font-weight: bold;
  color: #303133;
  font-family: 'Helvetica Neue', Helvetica, sans-serif;
}

.stat-value.text {
  font-size: 14px;
  font-weight: normal;
}

.stat-item.danger-border {
  border-color: #fde2e2;
  background-color: #fef0f0;
}

.stat-item.danger-border .stat-value {
  color: #f56c6c;
}

@media (max-width: 600px) {
  .user-profile-card {
    flex-direction: column;
    text-align: center;
  }

  .info-row {
    justify-content: center;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.title-dot {
  background: #000000 !important;
}

:deep(.toolbar .el-button--primary) {
  background: #fff !important;
  border: 1px solid #333 !important;
  color: #333 !important;
  border-radius: 10px !important;
}
:deep(.toolbar .el-button--primary:hover) {
  background: #f9f9f9 !important;
  border-color: #000 !important;
  color: #000 !important;
}

:deep(.toolbar .el-button:not(.el-button--primary)) {
  background: #f7f8fa !important;
  border: 1px solid #dcdfe6 !important;
  color: #666 !important;
  border-radius: 10px !important;
}
:deep(.toolbar .el-button:not(.el-button--primary):hover) {
  background: #f2f3f5 !important;
  border-color: #c0c4cc !important;
  color: #333 !important;
}
</style>