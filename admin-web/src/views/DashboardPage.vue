<template>
  <div class="page" v-loading="loading">
    <el-row :gutter="16">
      <el-col :span="4" v-for="card in cards" :key="card.label">
        <el-card>
          <div class="stat-label">{{ card.label }}</div>
          <div class="stat-value">{{ card.value }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 16px;">
      <template #header>
        <div class="section-header">
          <span>近 7 天趋势</span>
          <el-button text @click="exportData">导出概览</el-button>
        </div>
      </template>
      <el-table :data="trendRows" border size="small">
        <el-table-column prop="date" label="日期" width="100" />
        <el-table-column prop="userCount" label="新增用户" />
        <el-table-column prop="itemCount" label="新增帖子" />
        <el-table-column prop="claimCount" label="新增认领" />
        <el-table-column prop="reportCount" label="新增举报" />
      </el-table>
    </el-card>

    <el-row :gutter="16" style="margin-top: 16px;">
      <el-col :span="8">
        <el-card>
          <template #header>最近公告</template>
          <div v-for="item in stats.recentAnnouncements" :key="item.id" class="list-row">
            <span>{{ item.title }}</span>
            <span>{{ item.status }}</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card>
          <template #header>最近帖子</template>
          <div v-for="item in stats.recentItems" :key="item.id" class="list-row">
            <span>{{ item.title }}</span>
            <span>{{ item.status }}</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card>
          <template #header>最近举报</template>
          <div v-for="item in stats.recentReports" :key="item.id" class="list-row">
            <span>{{ item.targetTitle || `目标#${item.targetId}` }}</span>
            <span>{{ item.status }}</span>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessageBox, ElMessage } from 'element-plus'
import { adminApi, type DashboardStats, type DashboardTrend } from '../api/admin'

const loading = ref(false)
const trendRows = ref<DashboardTrend[]>([])
const stats = reactive<DashboardStats>({
  userCount: 0,
  itemCount: 0,
  claimCount: 0,
  reportCount: 0,
  pendingClaimCount: 0,
  pendingReportCount: 0,
  trends: [],
  recentAnnouncements: [],
  recentItems: [],
  recentReports: []
})
const cards = reactive([
  { label: '用户总数', value: 0 },
  { label: '帖子总数', value: 0 },
  { label: '认领申请', value: 0 },
  { label: '举报数', value: 0 },
  { label: '待处理认领', value: 0 },
  { label: '待处理举报', value: 0 }
])

const asNumber = (value: number | string | null | undefined) => {
  if (value === null || value === undefined) return 0
  return Number(value) || 0
}

const loadData = async () => {
  loading.value = true
  try {
    const data = await adminApi.dashboardStats()
    Object.assign(stats, data)
    trendRows.value = data.trends || []
    cards[0].value = asNumber(data.userCount)
    cards[1].value = asNumber(data.itemCount)
    cards[2].value = asNumber(data.claimCount)
    cards[3].value = asNumber(data.reportCount)
    cards[4].value = asNumber(data.pendingClaimCount)
    cards[5].value = asNumber(data.pendingReportCount)
  } catch (error) {
    ElMessage.error('仪表盘数据加载失败')
    console.error('dashboardStats failed', error)
  } finally {
    loading.value = false
  }
}

const exportData = async () => {
  const content = await adminApi.exportOverview()
  await ElMessageBox.alert(`<pre style="white-space:pre-wrap">${content}</pre>`, '导出结果', { dangerouslyUseHTMLString: true })
}

onMounted(loadData)
</script>

<style scoped>
.stat-label { color:#909399; }
.stat-value { font-size: 28px; font-weight: 700; margin-top: 8px; }
.section-header { display: flex; justify-content: space-between; align-items: center; }
.list-row { display: flex; justify-content: space-between; gap: 12px; padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
</style>
