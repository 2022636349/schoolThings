<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>帖子管理</span>
        <div class="toolbar">
          <el-input v-model="query.keyword" clearable placeholder="搜索标题/描述/地点" style="width: 240px" @keyup.enter="loadRows(1)" />
          <el-select v-model="query.type" clearable placeholder="类型" style="width: 120px">
            <el-option label="失物招领" value="lost" />
            <el-option label="寻物启事" value="found" />
          </el-select>
          <el-select v-model="query.status" clearable placeholder="状态" style="width: 120px">
            <el-option label="active" value="active" />
            <el-option label="warning" value="warning" />
            <el-option label="offline" value="offline" />
            <el-option label="claimed" value="claimed" />
          </el-select>
          <el-button type="primary" @click="loadRows(1)">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
          <el-button type="danger" plain :disabled="selectedIds.length === 0" @click="batchDelete">批量删除</el-button>
        </div>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading" @selection-change="onSelectionChange">
      <el-table-column type="selection" width="48" />
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="title" label="标题" min-width="180" show-overflow-tooltip />
      <el-table-column label="类型" width="110">
        <template #default="scope">
          <el-tag>{{ scope.row.type === 'lost' ? '失物招领' : '寻物启事' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="publisherName" label="发布者" width="120" />
      <el-table-column prop="location" label="地点" min-width="140" show-overflow-tooltip />
      <el-table-column label="发布时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="110">
        <template #default="scope">
          <el-tag :type="tagType(scope.row.status)">{{ scope.row.status }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="likeCount" label="点赞" width="80" />
      <el-table-column label="操作" width="280" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button size="small" @click="setStatus(scope.row.id, 'offline')">下架</el-button>
          <el-button size="small" type="warning" @click="setStatus(scope.row.id, 'warning')">预警</el-button>
          <el-button size="small" type="success" @click="setStatus(scope.row.id, 'active')">恢复</el-button>
          <el-button size="small" type="danger" @click="removeItem(scope.row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pager">
      <el-pagination
        v-model:current-page="query.current"
        v-model:page-size="query.size"
        layout="total, prev, pager, next, sizes"
        :page-sizes="[10, 20, 50]"
        :total="total"
        @current-change="loadRows"
        @size-change="() => loadRows(1)"
      />
    </div>
  </el-card>

  <el-dialog v-model="detailVisible" title="帖子详情" width="760px">
    <template v-if="currentRow">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="ID">{{ currentRow.id }}</el-descriptions-item>
        <el-descriptions-item label="标题">{{ currentRow.title }}</el-descriptions-item>
        <el-descriptions-item label="类型">{{ currentRow.type }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ currentRow.status }}</el-descriptions-item>
        <el-descriptions-item label="发布者">{{ currentRow.publisherName || currentRow.publisherId }}</el-descriptions-item>
        <el-descriptions-item label="地点">{{ currentRow.location || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发布时间">{{ formatTime(currentRow.createdAt) }}</el-descriptions-item>
        <el-descriptions-item label="丢失/拾取时间">{{ formatTime(currentRow.lostTime) }}</el-descriptions-item>
        <el-descriptions-item label="点赞数">{{ currentRow.likeCount }}</el-descriptions-item>
      </el-descriptions>
      <div class="images" v-if="currentRow.images.length">
        <el-image v-for="url in currentRow.images" :key="url" :src="url" fit="cover" class="image" :preview-src-list="currentRow.images" />
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessageBox } from 'element-plus'
import { adminApi, type AdminItem } from '../api/admin'

const rows = ref<AdminItem[]>([])
const loading = ref(false)
const total = ref(0)
const detailVisible = ref(false)
const currentRow = ref<AdminItem | null>(null)
const selectedIds = ref<number[]>([])
const query = reactive({
  keyword: '',
  type: '',
  status: '',
  current: 1,
  size: 10
})

const loadRows = async (page?: number) => {
  if (typeof page === 'number') {
    query.current = page
  }
  loading.value = true
  try {
    const data = await adminApi.items(query)
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const resetQuery = async () => {
  query.keyword = ''
  query.type = ''
  query.status = ''
  query.current = 1
  query.size = 10
  await loadRows(1)
}

const onSelectionChange = (list: AdminItem[]) => {
  selectedIds.value = list.map(item => item.id)
}

const showDetail = (row: AdminItem) => {
  currentRow.value = row
  detailVisible.value = true
}

const setStatus = async (id: number, status: string) => {
  await adminApi.updateItemStatus(id, status)
  await loadRows()
}

const removeItem = async (id: number) => {
  await ElMessageBox.confirm('确认删除该帖子吗？', '提示', { type: 'warning' })
  await adminApi.deleteItem(id)
  await loadRows()
}

const batchDelete = async () => {
  await ElMessageBox.confirm(`确认删除选中的 ${selectedIds.value.length} 条帖子吗？`, '提示', { type: 'warning' })
  await adminApi.batchDeleteItems(selectedIds.value)
  selectedIds.value = []
  await loadRows(1)
}

const formatTime = (value: number) => {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

const tagType = (status: string) => {
  if (status === 'active') return 'success'
  if (status === 'warning') return 'warning'
  if (status === 'offline') return 'info'
  return 'danger'
}

onMounted(() => loadRows(1))
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
.pager { display: flex; justify-content: flex-end; margin-top: 16px; }
.images { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 16px; }
.image { width: 120px; height: 120px; border-radius: 8px; overflow: hidden; }
</style>
