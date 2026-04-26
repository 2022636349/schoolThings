<template>
  <el-card class="table-card" shadow="never">
    <template #header>
      <div class="card-header">
        <div class="header-title">
          <span class="title-dot"></span>
          <span>意见反馈中心</span>
          <el-tag class="pending-count" type="warning" effect="light">未回复 {{ pendingCount }}</el-tag>
        </div>
        <div class="toolbar">
          <el-segmented v-model="replyFilter" :options="replyOptions" />
          <el-button type="primary" @click="loadRows">
            <el-icon class="mr-4">
              <Refresh />
            </el-icon>刷新
          </el-button>
        </div>
      </div>
    </template>

    <el-table :data="filteredRows" v-loading="loading" class="modern-table"
      :header-cell-style="{ background: '#f8f9fa', color: '#606266', fontWeight: 600 }">
      <el-table-column prop="id" label="ID" width="80" align="center" />
      <el-table-column prop="userName" label="用户" width="140" align="center" />
      <el-table-column prop="content" label="反馈内容" min-width="260" show-overflow-tooltip />
      <el-table-column label="管理员回复" min-width="220" show-overflow-tooltip align="center">
        <template #default="scope">
          <el-tag v-if="!scope.row.result" type="warning" effect="light">未回复</el-tag>
          <span v-else class="highlight-text">{{ scope.row.result }}</span>
        </template>
      </el-table-column>
      <el-table-column label="提交时间" min-width="170" align="center">
        <template #default="scope">{{ formatTime(scope.row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right" align="center">
        <template #default="scope">
          <el-button link type="primary" size="small" @click="openEdit(scope.row)">
            {{ scope.row.result ? '修改回复' : '回复' }}
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 处理弹窗 -->
    <el-dialog v-model="visible" width="520px" :close-on-click-modal="false" center>
      <template #header>
        <span class="dialog-title-bold">反馈处理</span>
      </template>
      <el-form label-width="80px" class="edit-form">
        <el-form-item label="内容">
          <el-input :model-value="currentRow?.content" type="textarea" :rows="4" disabled />
        </el-form-item>
        <el-form-item label="回复">
          <el-input v-model="result" type="textarea" :rows="4" placeholder="请输入会同步给用户查看的回复内容" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" @click="save">保存回复</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { adminApi, type AdminFeedback } from '../api/admin'

const rows = ref<AdminFeedback[]>([])
const loading = ref(false)
const visible = ref(false)
const currentRow = ref<AdminFeedback | null>(null)
const result = ref('')
const replyFilter = ref('pending')
const replyOptions = [
  { label: '未回复', value: 'pending' },
  { label: '已回复', value: 'replied' },
  { label: '全部', value: 'all' }
]

const pendingCount = computed(() => rows.value.filter(item => !item.result).length)

const filteredRows = computed(() => {
  const source = replyFilter.value === 'all'
    ? rows.value
    : rows.value.filter(item => replyFilter.value === 'pending' ? !item.result : !!item.result)
  return [...source].sort((a, b) => {
    if (!a.result && b.result) return -1
    if (a.result && !b.result) return 1
    return b.id - a.id
  })
})

const loadRows = async () => {
  loading.value = true
  try {
    rows.value = await adminApi.feedbacks()
  } finally {
    loading.value = false
  }
}

const openEdit = (row: AdminFeedback) => {
  currentRow.value = row
  result.value = row.result || ''
  visible.value = true
}

const save = async () => {
  if (!currentRow.value) return
  await adminApi.updateFeedbackResult(currentRow.value.id, result.value.trim())
  visible.value = false
  await loadRows()
}

const formatTime = (value: number) => {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

onMounted(loadRows)
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
  gap: 16px;
  flex-wrap: wrap;
}

.header-title {
  display: flex;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  gap: 8px;
}

.pending-count {
  margin-left: 4px;
  font-weight: 500;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.title-dot {
  width: 4px;
  height: 16px;
  background: #409eff;
  border-radius: 2px;
  margin-right: 8px;
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

.dialog-title-bold {
  font-size: 16px;
  font-weight: 700;
  color: #303133;
}

.edit-form {
  padding-top: 10px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #606266;
}

.mr-4 {
  margin-right: 4px;
}

.title-dot {
  background: #000000 !important;
}

:deep(.card-header .el-button--primary) {
  background: #fff !important;
  border: 1px solid #333 !important;
  color: #333 !important;
  border-radius: 10px !important;
}
:deep(.card-header .el-button--primary:hover) {
  background: #f9f9f9 !important;
  border-color: #000 !important;
  color: #000 !important;
}
</style>
