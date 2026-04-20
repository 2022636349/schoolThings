<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>反馈管理</span>
        <el-button type="primary" @click="loadRows">刷新</el-button>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="userName" label="用户" width="140" />
      <el-table-column prop="content" label="反馈内容" min-width="260" show-overflow-tooltip />
      <el-table-column label="处理结果" min-width="180" show-overflow-tooltip>
        <template #default="scope">{{ scope.row.result || '未处理' }}</template>
      </el-table-column>
      <el-table-column label="提交时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="openEdit(scope.row)">处理</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <el-dialog v-model="visible" title="反馈处理" width="520px">
    <el-form label-width="80px">
      <el-form-item label="内容">
        <el-input :model-value="currentRow?.content" type="textarea" :rows="4" disabled />
      </el-form-item>
      <el-form-item label="结果">
        <el-input v-model="result" type="textarea" :rows="4" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" @click="save">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { adminApi, type AdminFeedback } from '../api/admin'

const rows = ref<AdminFeedback[]>([])
const loading = ref(false)
const visible = ref(false)
const currentRow = ref<AdminFeedback | null>(null)
const result = ref('')

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
  await adminApi.updateFeedbackResult(currentRow.value.id, result.value)
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
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
