<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>认领申请管理</span>
        <el-button type="primary" @click="loadRows">刷新</el-button>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="itemTitle" label="关联帖子" min-width="180" show-overflow-tooltip />
      <el-table-column prop="claimantName" label="申请人" width="120" />
      <el-table-column prop="publisherName" label="发布者" width="120" />
      <el-table-column prop="description" label="说明" min-width="200" show-overflow-tooltip />
      <el-table-column label="状态" width="110">
        <template #default="scope">
          <el-tag :type="scope.row.status === 'approved' ? 'success' : scope.row.status === 'rejected' ? 'danger' : 'warning'">
            {{ scope.row.status }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button size="small" type="success" @click="openReview(scope.row, 'approved')">通过</el-button>
          <el-button size="small" type="danger" @click="openReview(scope.row, 'rejected')">驳回</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <el-dialog v-model="detailVisible" title="认领申请详情" width="640px">
    <el-descriptions v-if="currentRow" :column="2" border>
      <el-descriptions-item label="申请ID">{{ currentRow.id }}</el-descriptions-item>
      <el-descriptions-item label="帖子ID">{{ currentRow.itemId }}</el-descriptions-item>
      <el-descriptions-item label="帖子标题">{{ currentRow.itemTitle || '-' }}</el-descriptions-item>
      <el-descriptions-item label="帖子状态">{{ currentRow.itemStatus || '-' }}</el-descriptions-item>
      <el-descriptions-item label="申请人">{{ currentRow.claimantName || currentRow.claimantId }}</el-descriptions-item>
      <el-descriptions-item label="发布者">{{ currentRow.publisherName || currentRow.publisherId }}</el-descriptions-item>
      <el-descriptions-item label="联系方式">{{ currentRow.contact || '-' }}</el-descriptions-item>
      <el-descriptions-item label="申请时间">{{ formatTime(currentRow.createdAt) }}</el-descriptions-item>
      <el-descriptions-item label="审批时间">{{ formatTime(currentRow.approvedAt) }}</el-descriptions-item>
      <el-descriptions-item label="审批备注" :span="2">{{ currentRow.reviewRemark || '-' }}</el-descriptions-item>
      <el-descriptions-item label="申请说明" :span="2">{{ currentRow.description || '-' }}</el-descriptions-item>
    </el-descriptions>
  </el-dialog>

  <el-dialog v-model="reviewVisible" :title="reviewForm.status === 'approved' ? '通过申请' : '驳回申请'" width="480px">
    <el-form label-width="80px">
      <el-form-item label="审批备注">
        <el-input v-model="reviewForm.remark" type="textarea" :rows="4" placeholder="选填" />
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
import { adminApi, type AdminClaim } from '../api/admin'

const rows = ref<AdminClaim[]>([])
const loading = ref(false)
const detailVisible = ref(false)
const reviewVisible = ref(false)
const currentRow = ref<AdminClaim | null>(null)
const reviewForm = reactive({
  id: 0,
  status: 'approved',
  remark: ''
})

const loadRows = async () => {
  loading.value = true
  try {
    rows.value = await adminApi.claims()
  } finally {
    loading.value = false
  }
}

const showDetail = (row: AdminClaim) => {
  currentRow.value = row
  detailVisible.value = true
}

const openReview = (row: AdminClaim, status: string) => {
  reviewForm.id = row.id
  reviewForm.status = status
  reviewForm.remark = row.reviewRemark || ''
  reviewVisible.value = true
}

const submitReview = async () => {
  await adminApi.reviewClaim(reviewForm.id, reviewForm.status, reviewForm.remark)
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
