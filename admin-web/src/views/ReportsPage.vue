<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>举报管理</span>
        <el-button type="primary" @click="loadRows">刷新</el-button>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="targetType" label="目标类型" width="100">
        <template #default="scope">
          <el-tag>{{ scope.row.targetType === 'item' ? '帖子' : scope.row.targetType }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="targetTitle" label="目标内容" min-width="180" show-overflow-tooltip />
      <el-table-column prop="reporterName" label="举报人" width="120" />
      <el-table-column prop="description" label="说明" min-width="200" show-overflow-tooltip />
      <el-table-column label="状态" width="110">
        <template #default="scope">
          <el-tag :type="scope.row.status === 'resolved' ? 'success' : scope.row.status === 'rejected' ? 'danger' : 'warning'">
            {{ scope.row.status }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button size="small" type="success" @click="openReview(scope.row, 'resolved')">已处理</el-button>
          <el-button size="small" type="danger" @click="openReview(scope.row, 'rejected')">驳回</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <el-dialog v-model="detailVisible" title="举报详情" width="680px">
    <el-descriptions v-if="currentRow" :column="2" border>
      <el-descriptions-item label="举报ID">{{ currentRow.id }}</el-descriptions-item>
      <el-descriptions-item label="目标类型">{{ currentRow.targetType }}</el-descriptions-item>
      <el-descriptions-item label="目标ID">{{ currentRow.targetId }}</el-descriptions-item>
      <el-descriptions-item label="目标标题">{{ currentRow.targetTitle || '-' }}</el-descriptions-item>
      <el-descriptions-item label="举报人">{{ currentRow.reporterName || currentRow.reporterId }}</el-descriptions-item>
      <el-descriptions-item label="举报原因">{{ currentRow.reason || '-' }}</el-descriptions-item>
      <el-descriptions-item label="创建时间">{{ formatTime(currentRow.createdAt) }}</el-descriptions-item>
      <el-descriptions-item label="处理结果">{{ currentRow.resolution || '-' }}</el-descriptions-item>
      <el-descriptions-item label="证据" :span="2">{{ currentRow.evidenceUrls || '-' }}</el-descriptions-item>
      <el-descriptions-item label="举报说明" :span="2">{{ currentRow.description || '-' }}</el-descriptions-item>
    </el-descriptions>
  </el-dialog>

  <el-dialog v-model="reviewVisible" :title="reviewForm.status === 'resolved' ? '处理举报' : '驳回举报'" width="520px">
    <el-form label-width="100px">
      <el-form-item label="处理备注">
        <el-input v-model="reviewForm.resolution" type="textarea" :rows="4" placeholder="处理结果说明" />
      </el-form-item>
      <el-form-item label="帖子状态" v-if="currentRow?.targetType === 'item'">
        <el-select v-model="reviewForm.itemStatus" clearable placeholder="可选">
          <el-option label="active" value="active" />
          <el-option label="warning" value="warning" />
          <el-option label="offline" value="offline" />
        </el-select>
      </el-form-item>
      <el-form-item label="举报人状态">
        <el-select v-model="reviewForm.userStatus" clearable placeholder="可选">
          <el-option label="正常" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="reviewVisible = false">取消</el-button>
      <el-button type="primary" @click="submitReview">确认</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { adminApi, type AdminReport } from '../api/admin'

const rows = ref<AdminReport[]>([])
const loading = ref(false)
const detailVisible = ref(false)
const reviewVisible = ref(false)
const currentRow = ref<AdminReport | null>(null)
const reviewForm = reactive({
  id: 0,
  status: 'resolved',
  resolution: '',
  itemStatus: undefined as string | undefined,
  userStatus: undefined as number | undefined
})

const loadRows = async () => {
  loading.value = true
  try {
    rows.value = await adminApi.reports()
  } finally {
    loading.value = false
  }
}

const showDetail = (row: AdminReport) => {
  currentRow.value = row
  detailVisible.value = true
}

const openReview = (row: AdminReport, status: string) => {
  currentRow.value = row
  reviewForm.id = row.id
  reviewForm.status = status
  reviewForm.resolution = row.resolution || ''
  reviewForm.itemStatus = undefined
  reviewForm.userStatus = undefined
  reviewVisible.value = true
}

const submitReview = async () => {
  await adminApi.reviewReport(reviewForm.id, {
    status: reviewForm.status,
    resolution: reviewForm.resolution,
    itemStatus: reviewForm.itemStatus,
    userStatus: reviewForm.userStatus
  })
  reviewVisible.value = false
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
