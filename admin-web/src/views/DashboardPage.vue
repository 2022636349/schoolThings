<template>
  <div class="dashboard-container" v-loading="loading">
    <!-- 顶部统计卡片 -->
    <el-row :gutter="20">
      <el-col :span="6" v-for="(card, index) in cards" :key="card.label">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-info">
              <div class="stat-label">{{ card.label }}</div>
              <div class="stat-value">{{ card.value.toLocaleString() }}</div>
            </div>
            <div class="stat-icon-wrapper" :class="'icon-bg-' + index">
              <el-icon v-if="index === 0">
                <User />
              </el-icon>
              <el-icon v-if="index === 1">
                <Document />
              </el-icon>
              <el-icon v-if="index === 2">
                <Warning />
              </el-icon>
              <el-icon v-if="index === 3">
                <Clock />
              </el-icon>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 趋势分析图表 (替代原来的表格) -->
    <el-card shadow="never" class="main-card mt-20">
      <template #header>
        <div class="section-header">
          <div class="header-title">
            <span class="title-dot"></span>
            <span>近 7 天趋势分析</span>
          </div>
          <el-button type="primary" variant="outline" plain @click="exportData">
            <el-icon class="mr-4">
              <Download />
            </el-icon>导出报告
          </el-button>
        </div>
      </template>
      <!-- 图表容器 -->
      <div ref="trendChartRef" style="width: 100%; height: 350px;"></div>
    </el-card>

    <!-- 底部列表 -->
    <el-row :gutter="20" class="mt-20">
      <el-col :span="8">
        <el-card shadow="never" class="list-card">
          <template #header>
            <div class="list-header">最近公告</div>
          </template>
          <div v-for="item in stats.recentAnnouncements" :key="item.id" class="list-row">
            <span class="list-title">{{ item.title }}</span>
            <el-tag size="small" round>{{ item.status === 'published' ? '已发布' : item.status === 'draft' ? '草稿' : '已下线'
            }}</el-tag>
          </div>
          <el-empty v-if="!stats.recentAnnouncements.length" :image-size="60" description="暂无公告" />
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="list-card">
          <template #header>
            <div class="list-header">最近帖子</div>
          </template>
          <div v-for="item in stats.recentItems" :key="item.id" class="list-row">
            <span class="list-title">{{ item.title }}</span>
            <el-tag size="small"
              :type="item.status === 'active' ? 'success' : item.status === 'warning' ? 'warning' : 'info'" round>
              {{ item.status === 'active' ? '正常' : item.status === 'warning' ? '预警' : item.status === 'offline' ? '已下架'
                :
                item.status === 'claimed' ? '已认领' : item.status }}
            </el-tag>
          </div>
          <el-empty v-if="!stats.recentItems.length" :image-size="60" description="暂无帖子" />
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="list-card">
          <template #header>
            <div class="list-header">最近举报</div>
          </template>
          <div v-for="item in stats.recentReports" :key="item.id" class="list-row">
            <span class="list-title">{{ item.targetTitle || `目标#${item.targetId}` }}</span>
            <el-tag size="small"
              :type="item.status === 'pending' ? 'warning' : item.status === 'resolved' ? 'success' : 'danger'" round>
              {{ item.status === 'pending' ? '待处理' : item.status === 'resolved' ? '已处理' : '已驳回' }}
            </el-tag>
          </div>
          <el-empty v-if="!stats.recentReports.length" :image-size="60" description="暂无举报" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref, nextTick, onUnmounted } from 'vue'
import { ElMessageBox, ElMessage } from 'element-plus'
import { User, Document, Warning, Clock, Download } from '@element-plus/icons-vue'
import { adminApi, type DashboardStats, type DashboardTrend } from '../api/admin'
import * as echarts from 'echarts'

const loading = ref(false)
const trendRows = ref<DashboardTrend[]>([])
const trendChartRef = ref<HTMLElement | null>(null)
let trendChartInstance: echarts.ECharts | null = null

const stats = reactive<DashboardStats>({
  userCount: 0,
  itemCount: 0,
  reportCount: 0,
  pendingReportCount: 0,
  trends: [],
  recentAnnouncements: [],
  recentItems: [],
  recentReports: []
})

const cards = reactive([
  { label: '用户总数', value: 0 },
  { label: '帖子总数', value: 0 },
  { label: '举报数', value: 0 },
  { label: '待处理举报', value: 0 }
])

const asNumber = (value: number | string | null | undefined) => {
  if (value === null || value === undefined) return 0
  return Number(value) || 0
}

// 初始化图表
const initChart = () => {
  if (!trendChartRef.value) return

  // 如果实例已存在，先销毁再重建
  if (trendChartInstance) {
    trendChartInstance.dispose()
  }

  trendChartInstance = echarts.init(trendChartRef.value)

  const dates = trendRows.value.map(item => item.date)
  const userCounts = trendRows.value.map(item => item.userCount)
  const itemCounts = trendRows.value.map(item => item.itemCount)

  const option = {
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      borderColor: '#e4e7ed',
      textStyle: { color: '#606266' },
      axisPointer: { type: 'shadow' }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: dates,
      axisLine: { lineStyle: { color: '#dcdfe6' } },
      axisLabel: { color: '#909399' }
    },
    yAxis: {
      type: 'value',
      axisLine: { show: false },
      axisTick: { show: false },
      splitLine: { lineStyle: { type: 'dashed', color: '#ebeef5' } },
      axisLabel: { color: '#909399' }
    },
    series: [
      {
        name: '新增用户',
        type: 'line',
        smooth: true,
        data: userCounts,
        symbol: 'circle',
        symbolSize: 6,
        itemStyle: { color: '#409EFF' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(64, 158, 255, 0.2)' },
            { offset: 1, color: 'rgba(64, 158, 255, 0.01)' }
          ])
        },
        lineStyle: { width: 3 }
      },
      {
        name: '新增帖子',
        type: 'line',
        smooth: true,
        data: itemCounts,
        symbol: 'circle',
        symbolSize: 6,
        itemStyle: { color: '#67C23A' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(103, 194, 58, 0.2)' },
            { offset: 1, color: 'rgba(103, 194, 58, 0.01)' }
          ])
        },
        lineStyle: { width: 3 }
      }
    ]
  }

  trendChartInstance.setOption(option)
}

const loadData = async () => {
  loading.value = true
  try {
    const data = await adminApi.dashboardStats()
    Object.assign(stats, data)
    trendRows.value = data.trends || []
    cards[0].value = asNumber(data.userCount)
    cards[1].value = asNumber(data.itemCount)
    cards[2].value = asNumber(data.reportCount)
    cards[3].value = asNumber(data.pendingReportCount)

    // 数据加载完成后初始化图表
    await nextTick()
    initChart()
  } catch (error) {
    ElMessage.error('仪表盘数据加载失败')
    console.error('dashboardStats failed', error)
  } finally {
    loading.value = false
  }
}

const exportData = async () => {
  const content = await adminApi.exportOverview()
  await ElMessageBox.alert(`<pre style="white-space:pre-wrap; background:#f4f4f5; padding:12px; border-radius:4px; font-family:monospace;">${content}</pre>`, '导出结果', { dangerouslyUseHTMLString: true, customClass: 'wide-box' })
}

// 监听窗口大小变化，重绘图表
const handleResize = () => {
  trendChartInstance?.resize()
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  trendChartInstance?.dispose()
})
</script>

<style scoped>
.dashboard-container {
  padding: 24px;
  background-color: #f5f7fa;
  min-height: 100vh;
}

.stat-card {
  border-radius: 12px;
  border: none;
  transition: transform 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
}

.stat-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-bottom: 8px;
  font-weight: 500;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  font-family: 'Helvetica Neue', Helvetica, sans-serif;
}

.stat-icon-wrapper {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
}

.icon-bg-0 {
  background-color: #ecf5ff;
  color: #409eff;
}

.icon-bg-1 {
  background-color: #f0f9eb;
  color: #67c23a;
}

.icon-bg-2 {
  background-color: #fef0f0;
  color: #f56c6c;
}

.icon-bg-3 {
  background-color: #fdf6ec;
  color: #e6a23c;
}

.main-card {
  border-radius: 12px;
  border: none;
}

.section-header {
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
  height: 18px;
  background: #409eff;
  border-radius: 2px;
  margin-right: 10px;
}

.list-card {
  border-radius: 12px;
  border: none;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.list-header {
  font-weight: 600;
  font-size: 15px;
  color: #303133;
}

.list-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 0;
  border-bottom: 1px solid #f2f6fc;
  transition: background 0.2s;
}

.list-row:hover {
  background-color: #f5f7fa;
  padding-left: 8px;
  padding-right: 8px;
  margin: 0 -8px;
  border-radius: 6px;
}

.list-row:last-child {
  border-bottom: none;
}

.list-title {
  font-size: 14px;
  color: #606266;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  padding-right: 12px;
}

:deep(.el-card__body) {
  flex: 1;
  overflow-y: auto;
}

:deep(.el-card__header) {
  padding: 18px 20px;
  border-bottom: 1px solid #f2f6fc;
  background-color: #fff;
}

.mt-20 {
  margin-top: 20px;
}

.mr-4 {
  margin-right: 4px;
}

.title-dot {
  background: #000000 !important;
}

:deep(.main-card .el-button--primary) {
  background-color: #ffffff !important;
  border: 1px solid #333333 !important;
  color: #333333 !important;
  border-radius: 18px !important;
}

:deep(.main-card .el-button--primary:hover) {
  background-color: #fafafa !important;
  border-color: #000 !important;
  color: #000 !important;
}
</style>