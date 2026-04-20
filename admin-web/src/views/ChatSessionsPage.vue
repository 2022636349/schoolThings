<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>会话查看</span>
        <el-button type="primary" @click="loadRows">刷新</el-button>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="会话ID" width="90" />
      <el-table-column prop="itemTitle" label="关联帖子" min-width="180" show-overflow-tooltip />
      <el-table-column prop="initiatorName" label="发起人" width="140" />
      <el-table-column prop="ownerName" label="发布者" width="140" />
      <el-table-column prop="lastMessage" label="最后消息" min-width="240" show-overflow-tooltip />
      <el-table-column label="最后时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.lastMessageAt) }}</template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
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
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
