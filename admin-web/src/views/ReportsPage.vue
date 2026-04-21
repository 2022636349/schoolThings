<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>异议处理</span>
        <el-button type="primary" @click="loadRows">刷新</el-button>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="targetType" label="目标类型" width="100">
        <template #default="scope">
          <el-tag>{{ scope.row.targetType === 'item' ? '帖子异议' : scope.row.targetType }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="targetTitle" label="目标内容" min-width="180" show-overflow-tooltip />
      <el-table-column prop="reporterStudentNo" label="发起方学号" width="140" />
      <el-table-column prop="publisherStudentNo" label="发帖方学号" width="140" />
      <el-table-column prop="claimantStudentNo" label="认领方学号" width="140" />
      <el-table-column prop="description" label="异议说明" min-width="220" show-overflow-tooltip />
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
          <el-button size="small" type="success" @click="openReview(scope.row, 'resolved')">处理</el-button>
          <el-button size="small" type="danger" @click="openReview(scope.row, 'rejected')">驳回</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <el-dialog v-model="detailVisible" title="异议详情" width="820px">
    <el-descriptions v-if="currentRow" :column="2" border>
      <el-descriptions-item label="异议ID">{{ currentRow.id }}</el-descriptions-item>
      <el-descriptions-item label="目标类型">{{ currentRow.targetType }}</el-descriptions-item>
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

  <el-dialog v-model="reviewVisible" :title="reviewForm.status === 'resolved' ? '处理异议' : '驳回异议'" width="680px">
    <el-form label-width="120px">
      <el-form-item label="处理备注">
        <el-input v-model="reviewForm.resolution" type="textarea" :rows="4" placeholder="处理结果说明" />
      </el-form-item>
      <el-form-item label="帖子状态" v-if="currentRow?.targetType === 'item'">
        <el-select v-model="reviewForm.itemStatus" clearable placeholder="可选">
          <el-option label="active" value="active" />
          <el-option label="warning" value="warning" />
          <el-option label="offline" value="offline" />
          <el-option label="claimed" value="claimed" />
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
  reporterHeartDelta: 0,
  reporterFraudDelta: 0,
  publisherHeartDelta: 0,
  publisherFraudDelta: 0,
  claimantHeartDelta: 0,
  claimantFraudDelta: 0
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
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
