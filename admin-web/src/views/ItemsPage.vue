<template>
  <el-card class="table-card" shadow="never">
    <template #header>
      <div class="card-header">
        <div class="header-title">
          <span class="title-dot"></span>
          <span>寻物拾物帖子</span>
        </div>
        <div class="toolbar">
          <el-input v-model="query.keyword" clearable placeholder="搜索标题/描述/地点" class="search-input"
            @keyup.enter="loadRows(1)">
            <template #prefix>
              <el-icon>
                <Search />
              </el-icon>
            </template>
          </el-input>
          <el-select v-model="query.type" clearable placeholder="类型" class="select-input">
            <el-option label="失物招领" value="lost" />
            <el-option label="寻物启事" value="found" />
          </el-select>
          <el-select v-model="query.status" clearable placeholder="状态" class="select-input">
            <el-option label="正常" value="active" />
            <el-option label="预警" value="warning" />
            <el-option label="已下架" value="offline" />
            <el-option label="已认领" value="claimed" />
          </el-select>
          <el-button type="primary" @click="loadRows(1)">
            <el-icon class="mr-4">
              <Search />
            </el-icon>查询
          </el-button>
          <el-button @click="resetQuery">重置</el-button>
          <el-button type="danger" plain :disabled="selectedIds.length === 0" @click="batchDelete">
            <el-icon class="mr-4">
              <Delete />
            </el-icon>批量删除
          </el-button>
        </div>
      </div>
    </template>

    <el-table :data="rows" v-loading="loading" @selection-change="onSelectionChange" class="modern-table"
      :header-cell-style="{ background: '#f8f9fa', color: '#606266', fontWeight: 600 }">
      <el-table-column type="selection" width="48" />
      <el-table-column prop="id" label="ID" width="80" align="center" />
      <el-table-column prop="title" label="标题" min-width="160" show-overflow-tooltip />
      <el-table-column label="类型" width="110" align="center">
        <template #default="scope">
          <el-tag effect="light" size="small">{{ scope.row.type === 'lost' ? '失物招领' : '寻物启事' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="publisherName" label="发布者" width="100" />
      <el-table-column prop="location" label="地点" min-width="100" show-overflow-tooltip />
      <el-table-column label="发布时间" min-width="160">
        <template #default="scope">{{ formatTime(scope.row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="110" align="center">
        <template #default="scope">
          <el-tag :type="tagType(scope.row.status)" effect="light" size="small">
            {{ statusText(scope.row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="likeCount" label="点赞" width="80" align="center">
        <template #default="scope">
          <span class="highlight-text">{{ scope.row.likeCount }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="330" fixed="right" align="center">
        <template #default="scope">
          <el-button link type="primary" size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button link type="info" size="small" @click="setStatus(scope.row.id, 'offline')">下架</el-button>
          <el-button link type="warning" size="small" @click="setStatus(scope.row.id, 'warning')">预警</el-button>
          <el-button link type="success" size="small" @click="setStatus(scope.row.id, 'active')">恢复</el-button>
          <el-button link type="danger" size="small" @click="removeItem(scope.row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pager">
      <el-pagination v-model:current-page="query.current" v-model:page-size="query.size"
        layout="total, prev, pager, next, sizes" :page-sizes="[10, 20, 50]" :total="total" @current-change="loadRows"
        @size-change="() => loadRows(1)" />
    </div>
  </el-card>

  <el-dialog v-model="detailVisible" width="760px" :close-on-click-modal="false" class="detail-dialog" center>
    <template #header>
      <span class="dialog-title-bold">帖子详情</span>
    </template>
    <div v-if="currentRow" class="detail-content">

      <!-- 顶部帖子信息卡片 -->
      <div class="post-profile-card">
        <div class="post-basic-info">
          <div class="info-row">
            <span class="label">标题：</span>
            <span class="value title-text">{{ currentRow.title }}</span>
          </div>
          <div class="info-row">
            <span class="label">类型：</span>
            <span class="value">{{ currentRow.type === 'lost' ? '失物招领' : '寻物启事' }}</span>
          </div>
          <div class="info-row">
            <span class="label">状态：</span>
            <el-tag :type="tagType(currentRow.status)" size="small" effect="dark">{{ statusText(currentRow.status)
            }}</el-tag>
          </div>
          <div class="info-row">
            <span class="label">发布者：</span>
            <span class="value">{{ currentRow.publisherName || currentRow.publisherId }}</span>
          </div>
        </div>
      </div>

      <!-- 数据网格 -->
      <div class="stats-grid">
        <div class="stat-item">
          <div class="stat-label">ID</div>
          <div class="stat-value">{{ currentRow.id }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">地点</div>
          <div class="stat-value text">{{ currentRow.location || '-' }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">发布时间</div>
          <div class="stat-value text">{{ formatTime(currentRow.createdAt) }}</div>
        </div>
        <div class="stat-item">
          <div class="stat-label">丢失/拾取时间</div>
          <div class="stat-value text">{{ formatTime(currentRow.lostTime) }}</div>
        </div>
        <div class="stat-item highlight">
          <div class="stat-label">点赞数</div>
          <div class="stat-value primary">{{ currentRow.likeCount }}</div>
        </div>
      </div>

      <!-- 图片区域 -->
      <div class="images" v-if="currentRow.images.length">
        <div class="image-label">帖子图片：</div>
        <el-image v-for="url in currentRow.images" :key="url" :src="url" fit="cover" class="image"
          :preview-src-list="currentRow.images" />
      </div>

    </div>
  </el-dialog>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessageBox } from 'element-plus'
import { Search, Delete } from '@element-plus/icons-vue'
import { adminApi, type AdminItem } from '../api/admin'

const rows = ref<AdminItem[]>([])
const loading = ref(false)
const total = ref(0)
const detailVisible = ref(false)
const currentRow = ref<AdminItem | null>(null)
const selectedIds = ref<number[]>([])
const query = reactive({
  keyword: '',
  type: '',
  status: '',
  current: 1,
  size: 10
})

const statusText = (status: string) => {
  if (status === 'active') return '正常'
  if (status === 'warning') return '预警'
  if (status === 'offline') return '已下架'
  if (status === 'claimed') return '已认领'
  return status
}

const loadRows = async (page?: number) => {
  if (typeof page === 'number') {
    query.current = page
  }
  loading.value = true
  try {
    const data = await adminApi.items(query)
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const resetQuery = async () => {
  query.keyword = ''
  query.type = ''
  query.status = ''
  query.current = 1
  query.size = 10
  await loadRows(1)
}

const onSelectionChange = (list: AdminItem[]) => {
  selectedIds.value = list.map(item => item.id)
}

const showDetail = (row: AdminItem) => {
  currentRow.value = row
  detailVisible.value = true
}

const setStatus = async (id: number, status: string) => {
  await adminApi.updateItemStatus(id, status)
  await loadRows()
}

const removeItem = async (id: number) => {
  await ElMessageBox.confirm('确认删除该帖子吗？', '提示', { type: 'warning' })
  await adminApi.deleteItem(id)
  await loadRows()
}

const batchDelete = async () => {
  await ElMessageBox.confirm(`确认删除选中的 ${selectedIds.value.length} 条帖子吗？`, '提示', { type: 'warning' })
  await adminApi.batchDeleteItems(selectedIds.value)
  selectedIds.value = []
  await loadRows(1)
}

const formatTime = (value: number) => {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

const tagType = (status: string) => {
  if (status === 'active') return 'success'
  if (status === 'warning') return 'warning'
  if (status === 'offline') return 'info'
  return 'danger'
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
  flex-wrap: wrap;
}

.search-input {
  width: 240px;
}

.select-input {
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

.highlight-text {
  color: #409eff;
  font-weight: 600;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 24px;
}

.detail-dialog {
  --el-dialog-header-font-size: 16px;
  --el-dialog-header-font-weight: 600;
}

.dialog-title-bold {
  font-size: 16px;
  font-weight: 700;
  color: #303133;
}

.detail-content {
  padding: 10px 5px;
}

.post-profile-card {
  display: flex;
  padding: 24px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  border-radius: 12px;
  border: 1px solid #ebeef5;
  margin-bottom: 24px;
  align-items: center;
}

.post-icon-wrapper {
  flex-shrink: 0;
}

.post-icon {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409eff 0%, #79bbff 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: bold;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
  white-space: normal;
  word-break: break-all;
  padding: 6px;
  line-height: 1.2;
}

.post-basic-info {
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

.info-row .label {
  color: #909399;
  width: 70px;
  flex-shrink: 0;
}

.info-row .value {
  color: #303133;
  font-weight: 500;
}

.title-text {
  font-size: 18px;
  font-weight: 600;
  white-space: normal;
  word-break: break-all;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  margin-bottom: 24px;
  background: #fff;
  padding: 20px;
  border-radius: 12px;
  border: 1px solid #ebeef5;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px dashed #ebeef5;
  font-size: 14px;
  transition: none;
}

.stat-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.stat-item:hover {
  transform: none;
  box-shadow: none;
}

.stat-item:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
  border-color: #dcdfe6;
}

.stat-label {
  font-weight: 600;
  color: #303133;
  min-width: 90px;
}

.stat-value {
  color: #606266;
  text-align: right;
  flex: 1;
  padding-left: 16px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.stat-value.text {
  font-size: 14px;
  font-weight: normal;
}

.stat-value.primary {
  color: #409eff;
  font-weight: 500;
}

.stat-value.text {
  color: #909399;
  font-size: 13px;
}

.images {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  margin-top: 20px;
  align-items: flex-start;
}

.image-label {
  width: 100%;
  font-weight: 600;
  color: #606266;
  margin-bottom: 8px;
}

.image {
  width: 120px;
  height: 120px;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #ebeef5;
}

.mr-4 {
  margin-right: 4px;
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

:deep(.toolbar .el-button:not(.el-button--primary):not(.el-button--danger)) {
  background: #f7f8fa !important;
  border: 1px solid #dcdfe6 !important;
  color: #666 !important;
  border-radius: 10px !important;
}
:deep(.toolbar .el-button:not(.el-button--primary):not(.el-button--danger):hover) {
  background: #f2f3f5 !important;
  border-color: #c0c4cc !important;
  color: #333 !important;
}

:deep(.toolbar .el-button--danger) {
  border-radius: 10px !important;
}
</style>