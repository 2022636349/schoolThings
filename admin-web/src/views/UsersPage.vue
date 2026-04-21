<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>用户管理</span>
        <div class="toolbar">
          <el-input v-model="query.keyword" clearable placeholder="搜索学号/昵称/手机号" style="width: 240px" @keyup.enter="loadRows(1)" />
          <el-select v-model="query.status" clearable placeholder="状态" style="width: 120px">
            <el-option label="正常" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
          <el-button type="primary" @click="loadRows(1)">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </div>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="studentNo" label="学号" min-width="130" />
      <el-table-column prop="nickname" label="昵称" min-width="120" />
      <el-table-column prop="phone" label="手机号" min-width="140" />
      <el-table-column label="注册时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.createdAt) }}</template>
      </el-table-column>
      <el-table-column prop="heartValue" label="热心值" width="90" />
      <el-table-column prop="fraudValue" label="异常值" width="90" />
      <el-table-column prop="postCount" label="发布数" width="90" />
      <el-table-column label="状态" width="90">
        <template #default="scope">
          <el-tag :type="scope.row.status === 1 ? 'success' : 'danger'">
            {{ scope.row.status === 1 ? '正常' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="showDetail(scope.row)">详情</el-button>
          <el-button size="small" @click="toggleStatus(scope.row)">
            {{ scope.row.status === 1 ? '禁用' : '恢复' }}
          </el-button>
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

  <el-dialog v-model="detailVisible" title="用户详情" width="520px">
    <el-descriptions v-if="currentRow" :column="2" border>
      <el-descriptions-item label="ID">{{ currentRow.id }}</el-descriptions-item>
      <el-descriptions-item label="学号">{{ currentRow.studentNo }}</el-descriptions-item>
      <el-descriptions-item label="昵称">{{ currentRow.nickname }}</el-descriptions-item>
      <el-descriptions-item label="手机号">{{ currentRow.phone || '-' }}</el-descriptions-item>
      <el-descriptions-item label="状态">{{ currentRow.status === 1 ? '正常' : '禁用' }}</el-descriptions-item>
      <el-descriptions-item label="注册时间">{{ formatTime(currentRow.createdAt) }}</el-descriptions-item>
      <el-descriptions-item label="热心值">{{ currentRow.heartValue }}</el-descriptions-item>
      <el-descriptions-item label="异常值">{{ currentRow.fraudValue }}</el-descriptions-item>
      <el-descriptions-item label="发布数">{{ currentRow.postCount }}</el-descriptions-item>
      <el-descriptions-item label="归还数">{{ currentRow.returnCount }}</el-descriptions-item>
      <el-descriptions-item label="获赞数">{{ currentRow.likeReceived }}</el-descriptions-item>
    </el-descriptions>
  </el-dialog>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { adminApi, type AdminUser } from '../api/admin'

const rows = ref<AdminUser[]>([])
const loading = ref(false)
const total = ref(0)
const detailVisible = ref(false)
const currentRow = ref<AdminUser | null>(null)
const query = reactive({
  keyword: '',
  status: undefined as number | undefined,
  current: 1,
  size: 10
})

const loadRows = async (page?: number) => {
  if (typeof page === 'number') {
    query.current = page
  }
  loading.value = true
  try {
    const data = await adminApi.users(query)
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const resetQuery = async () => {
  query.keyword = ''
  query.status = undefined
  query.current = 1
  query.size = 10
  await loadRows(1)
}

const toggleStatus = async (row: AdminUser) => {
  const next = row.status === 1 ? 0 : 1
  await adminApi.updateUserStatus(row.id, next)
  await loadRows()
}

const showDetail = (row: AdminUser) => {
  currentRow.value = row
  detailVisible.value = true
}

const formatTime = (value: number) => {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

onMounted(() => loadRows(1))
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.toolbar { display: flex; gap: 12px; align-items: center; }
.pager { display: flex; justify-content: flex-end; margin-top: 16px; }
</style>
