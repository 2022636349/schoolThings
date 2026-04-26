<template>
  <el-card class="table-card" shadow="never">
    <template #header>
      <div class="card-header">
        <div class="header-title">
          <span class="title-dot"></span>
          <span>即时会话监控</span>
        </div>
        <el-button type="primary" @click="loadRows">
          <el-icon class="mr-4">
            <Refresh />
          </el-icon>刷新
        </el-button>
      </div>
    </template>

    <el-table :data="rows" v-loading="loading" class="modern-table"
      :header-cell-style="{ background: '#f8f9fa', color: '#606266', fontWeight: 600 }">
      <el-table-column prop="id" label="会话ID" width="90" align="center" />
      <el-table-column prop="itemTitle" label="关联帖子" min-width="180" show-overflow-tooltip />
      <el-table-column prop="initiatorName" label="发起人" width="140" align="center" />
      <el-table-column prop="ownerName" label="发布者" width="140" align="center" />
      <el-table-column prop="lastMessage" label="最后消息" min-width="240" show-overflow-tooltip />
      <el-table-column label="最后时间" min-width="170" align="center">
        <template #default="scope">{{ formatTime(scope.row.lastMessageAt) }}</template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { adminApi, type AdminChatSession } from '../api/admin'

const rows = ref<AdminChatSession[]>([])
const loading = ref(false)

const loadRows = async () => {
  loading.value = true
  try {
    rows.value = await adminApi.chatSessions()
  } finally {
    loading.value = false
  }
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