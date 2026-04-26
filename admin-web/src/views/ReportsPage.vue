<template>
  <el-card class="table-card" shadow="never">
    <template #header>
      <div class="card-header">
        <div class="header-title">
          <span class="title-dot"></span>
          <span>举报投诉处理</span>
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
      <el-table-column prop="id" label="ID" width="80" align="center" />
      <el-table-column prop="targetType" label="目标类型" width="110" align="center">
        <template #default="scope">
          <el-tag size="small" effect="light">
            {{ scope.row.targetType === 'item' ? '帖子异议' : scope.row.targetType }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="targetTitle" label="目标内容" min-width="180" show-overflow-tooltip />
      <el-table-column prop="reporterStudentNo" label="发起方学号" width="140" align="center" />
      <el-table-column prop="publisherStudentNo" label="发帖方学号" width="140" align="center" />
      <el-table-column prop="claimantStudentNo" label="认领方学号" width="140" align="center" />
      <el-table-column prop="description" label="异议说明" min-width="220" show-overflow-tooltip />
      <el-table-column label="状态" width="110" align="center">
        <template #default="scope">
          <el-tag
            :type="scope.row.status === 'resolved' ? 'success' : scope.row.status === 'rejected' ? 'danger' : 'warning'"
            effect="light" size="small">
            {{ statusText(scope.row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220" fixed="right" align="center">
        <template #default="scope">
          <el-button link type="primary" size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button link type="success" size="small" @click="openReview(scope.row, 'resolved')">处理</el-button>
          <el-button link type="danger" size="small" @click="openReview(scope.row, 'rejected')">驳回</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" width="820px" :close-on-click-modal="false" center>
      <template #header>
        <span class="dialog-title-bold">异议详情</span>
      </template>
      <el-descriptions v-if="currentRow" :column="2" border class="detail-desc">
        <el-descriptions-item label="异议ID">{{ currentRow.id }}</el-descriptions-item>
        <el-descriptions-item label="目标类型">{{ targetTypeText(currentRow.targetType) }}</el-descriptions-item>
        <el-descriptions-item label="目标标题">{{ currentRow.targetTitle || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起方学号">{{ currentRow.reporterStudentNo || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起方昵称">{{ currentRow.reporterName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起方电话">{{ currentRow.reporterPhone || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发帖方学号">{{ currentRow.publisherStudentNo || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发帖方昵称">{{ currentRow.publisherName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发帖方电话">{{ currentRow.publisherPhone || '-' }}</el-descriptions-item>
        <el-descriptions-item label="认领方学号">{{ currentRow.claimantStudentNo || '-' }}</el-descriptions-item>
        <el-descriptions-item label="认领方昵称">{{ currentRow.claimantName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="认领方电话">{{ currentRow.claimantPhone || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起方热心值">{{ currentRow.reporterHeartValue }}</el-descriptions-item>
        <el-descriptions-item label="发起方异常次数">{{ currentRow.reporterFraudValue }}</el-descriptions-item>
        <el-descriptions-item label="发帖方热心值">{{ currentRow.publisherHeartValue }}</el-descriptions-item>
        <el-descriptions-item label="发帖方异常次数">{{ currentRow.publisherFraudValue }}</el-descriptions-item>
        <el-descriptions-item label="认领方热心值">{{ currentRow.claimantHeartValue }}</el-descriptions-item>
        <el-descriptions-item label="认领方异常次数">{{ currentRow.claimantFraudValue }}</el-descriptions-item>
        <el-descriptions-item label="异议原因">{{ currentRow.reason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ formatTime(currentRow.createdAt) }}</el-descriptions-item>
        <el-descriptions-item label="处理结果" :span="2">{{ currentRow.resolution || '-' }}</el-descriptions-item>
        <el-descriptions-item label="证据" :span="2">{{ currentRow.evidenceUrls || '-' }}</el-descriptions-item>
        <el-descriptions-item label="异议说明" :span="2">{{ currentRow.description || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 处理弹窗 -->
    <el-dialog v-model="reviewVisible" width="680px" :close-on-click-modal="false" class="detail-dialog" center>
      <template #header>
        <span class="dialog-title-bold">{{ reviewForm.status === 'resolved' ? '处理异议' : '驳回异议' }}</span>
      </template>
      <el-form label-width="120px" class="review-form">
        <el-form-item label="处理备注">
          <el-input v-model="reviewForm.resolution" type="textarea" :rows="4" placeholder="处理结果说明" />
        </el-form-item>
        <el-form-item label="帖子状态" v-if="currentRow?.targetType === 'item'">
          <el-select v-model="reviewForm.itemStatus" clearable placeholder="可选">
            <el-option label="正常" value="active" />
            <el-option label="预警" value="warning" />
            <el-option label="已下架" value="offline" />
            <el-option label="已认领" value="claimed" />
          </el-select>
        </el-form-item>
        <el-divider>发起方调整</el-divider>
        <el-form-item label="热心值">
          <el-input-number v-model="reviewForm.reporterHeartDelta" :min="-1" :max="1" />
        </el-form-item>
        <el-form-item label="异常次数">
          <el-input-number v-model="reviewForm.reporterFraudDelta" :min="-1" :max="1" />
        </el-form-item>
        <el-divider>发帖方调整</el-divider>
        <el-form-item label="热心值">
          <el-input-number v-model="reviewForm.publisherHeartDelta" :min="-1" :max="1" />
        </el-form-item>
        <el-form-item label="异常次数">
          <el-input-number v-model="reviewForm.publisherFraudDelta" :min="-1" :max="1" />
        </el-form-item>
        <el-divider>认领方调整</el-divider>
        <el-form-item label="热心值">
          <el-input-number v-model="reviewForm.claimantHeartDelta" :min="-1" :max="1" />
        </el-form-item>
        <el-form-item label="异常次数">
          <el-input-number v-model="reviewForm.claimantFraudDelta" :min="-1" :max="1" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="reviewVisible = false">取消</el-button>
        <el-button type="primary" @click="submitReview">确认</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
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
  reporterHeartDelta: 0,
  reporterFraudDelta: 0,
  publisherHeartDelta: 0,
  publisherFraudDelta: 0,
  claimantHeartDelta: 0,
  claimantFraudDelta: 0
})

const statusText = (status: string) => {
  if (status === 'pending') return '待处理'
  if (status === 'resolved') return '已处理'
  if (status === 'rejected') return '已驳回'
  return status
}

const targetTypeText = (type: string) => {
  if (type === 'item') return '帖子'
  return type
}

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
  reviewForm.reporterHeartDelta = 0
  reviewForm.reporterFraudDelta = 0
  reviewForm.publisherHeartDelta = 0
  reviewForm.publisherFraudDelta = 0
  reviewForm.claimantHeartDelta = 0
  reviewForm.claimantFraudDelta = 0
  reviewVisible.value = true
}

const submitReview = async () => {
  await adminApi.reviewReport(reviewForm.id, {
    status: reviewForm.status,
    resolution: reviewForm.resolution,
    itemStatus: reviewForm.itemStatus,
    reporterHeartDelta: reviewForm.reporterHeartDelta,
    reporterFraudDelta: reviewForm.reporterFraudDelta,
    publisherHeartDelta: reviewForm.publisherHeartDelta,
    publisherFraudDelta: reviewForm.publisherFraudDelta,
    claimantHeartDelta: reviewForm.claimantHeartDelta,
    claimantFraudDelta: reviewForm.claimantFraudDelta
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

.review-form {
  padding-top: 10px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #606266;
}

.mr-4 {
  margin-right: 4px;
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

:deep(.detail-desc) {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.detail-desc .el-descriptions-item__label) {
  font-weight: 600;
  background: #f8f9fa;
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