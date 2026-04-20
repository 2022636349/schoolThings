<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>公告管理</span>
        <el-button type="primary" @click="openCreate">新建公告</el-button>
      </div>
    </template>
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="title" label="标题" min-width="180" show-overflow-tooltip />
      <el-table-column prop="priority" label="优先级" width="90" />
      <el-table-column label="状态" width="100">
        <template #default="scope">
          <el-tag :type="scope.row.status === 'published' ? 'success' : scope.row.status === 'offline' ? 'info' : 'warning'">
            {{ statusLabel(scope.row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="发布时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.publishFrom) }}</template>
      </el-table-column>
      <el-table-column label="下线时间" min-width="170">
        <template #default="scope">{{ formatTime(scope.row.publishTo) }}</template>
      </el-table-column>
      <el-table-column prop="viewCount" label="浏览" width="80" />
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="preview(scope.row)">预览</el-button>
          <el-button size="small" type="primary" @click="openEdit(scope.row)">编辑</el-button>
          <el-button size="small" type="danger" @click="remove(scope.row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="visible" title="公告编辑" width="720px">
      <el-form label-width="90px">
        <el-form-item label="标题">
          <el-input v-model="form.title" />
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="form.content" type="textarea" :rows="10" placeholder="支持粘贴 HTML 或普通文本" />
        </el-form-item>
        <el-form-item label="封面">
          <el-input v-model="form.cover" />
        </el-form-item>
        <el-form-item label="优先级">
          <el-input-number v-model="form.priority" :min="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status">
            <el-option label="草稿" value="draft" />
            <el-option label="已发布" value="published" />
            <el-option label="下线" value="offline" />
          </el-select>
        </el-form-item>
        <el-form-item label="发布时间">
          <el-date-picker v-model="form.publishFrom" type="datetime" value-format="x" placeholder="不限制" />
        </el-form-item>
        <el-form-item label="下线时间">
          <el-date-picker v-model="form.publishTo" type="datetime" value-format="x" placeholder="不限制" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button @click="previewForm">预览</el-button>
        <el-button type="primary" @click="save">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="previewVisible" title="公告预览" width="720px">
      <div v-if="previewRow" class="preview">
        <h2>{{ previewRow.title }}</h2>
        <el-image v-if="previewRow.cover" :src="previewRow.cover" fit="cover" class="cover" />
        <div class="meta">
          {{ statusLabel(previewRow.status) }} · 优先级 {{ previewRow.priority }} · {{ formatTime(previewRow.publishFrom) }}
        </div>
        <div class="content" v-html="previewRow.content"></div>
      </div>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessageBox } from 'element-plus'
import { adminApi, type AdminAnnouncement } from '../api/admin'

interface AnnouncementForm {
  id?: number
  title: string
  content: string
  cover: string
  priority: number
  status: string
  publishFrom?: number
  publishTo?: number
}

const rows = ref<AdminAnnouncement[]>([])
const loading = ref(false)
const visible = ref(false)
const previewVisible = ref(false)
const previewRow = ref<AnnouncementForm | AdminAnnouncement | null>(null)
const form = reactive<AnnouncementForm>({
  id: undefined,
  title: '',
  content: '',
  cover: '',
  priority: 0,
  status: 'draft',
  publishFrom: undefined,
  publishTo: undefined
})

const loadRows = async () => {
  loading.value = true
  try {
    rows.value = await adminApi.announcements()
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  form.id = undefined
  form.title = ''
  form.content = ''
  form.cover = ''
  form.priority = 0
  form.status = 'draft'
  form.publishFrom = undefined
  form.publishTo = undefined
}

const openCreate = () => {
  resetForm()
  visible.value = true
}

const openEdit = (row: AdminAnnouncement) => {
  form.id = row.id
  form.title = row.title
  form.content = row.content || ''
  form.cover = row.cover || ''
  form.priority = row.priority || 0
  form.status = row.status || 'draft'
  form.publishFrom = row.publishFrom || undefined
  form.publishTo = row.publishTo || undefined
  visible.value = true
}

const save = async () => {
  await adminApi.saveAnnouncement(form)
  visible.value = false
  await loadRows()
}

const remove = async (id: number) => {
  await ElMessageBox.confirm('确认删除该公告吗？', '提示', { type: 'warning' })
  await adminApi.deleteAnnouncement(id)
  await loadRows()
}

const preview = (row: AdminAnnouncement) => {
  previewRow.value = row
  previewVisible.value = true
}

const previewForm = () => {
  previewRow.value = { ...form }
  previewVisible.value = true
}

const statusLabel = (status: string) => {
  if (status === 'published') return '已发布'
  if (status === 'offline') return '下线'
  return '草稿'
}

const formatTime = (value?: number) => {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

onMounted(loadRows)
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.preview h2 { margin: 0 0 12px; }
.cover { width: 100%; height: 220px; border-radius: 8px; margin-bottom: 12px; }
.meta { color: #909399; font-size: 13px; margin-bottom: 16px; }
.content { line-height: 1.7; white-space: pre-wrap; }
</style>
