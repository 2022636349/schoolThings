<template>
  <el-card class="table-card" shadow="never">
    <template #header>
      <div class="card-header">
        <div class="header-title">
          <span class="title-dot"></span>
          <span>系统公告发布</span>
        </div>
        <el-button type="primary" @click="openCreate">
          <el-icon class="mr-4">
            <Plus />
          </el-icon>新建公告
        </el-button>
      </div>
    </template>

    <el-table :data="rows" v-loading="loading" class="modern-table"
      :header-cell-style="{ background: '#f8f9fa', color: '#606266', fontWeight: 600 }">
      <el-table-column prop="id" label="ID" width="80" align="center" />
      <el-table-column prop="title" label="标题" min-width="180" show-overflow-tooltip />
      <el-table-column prop="priority" label="优先级" width="90" align="center">
        <template #default="scope">
          <span class="highlight-text">{{ scope.row.priority }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="100" align="center">
        <template #default="scope">
          <el-tag
            :type="scope.row.status === 'published' ? 'success' : scope.row.status === 'offline' ? 'info' : 'warning'"
            effect="light" size="small">
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
      <el-table-column prop="viewCount" label="浏览" width="80" align="center" />
      <el-table-column label="操作" width="220" fixed="right" align="center">
        <template #default="scope">
          <el-button link type="primary" size="small" @click="preview(scope.row)">预览</el-button>
          <el-button link type="primary" size="small" @click="openEdit(scope.row)">编辑</el-button>
          <el-button link type="danger" size="small" @click="remove(scope.row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 编辑弹窗 -->
    <el-dialog v-model="visible" width="720px" :close-on-click-modal="false" center>
      <template #header>
        <span class="dialog-title-bold">公告编辑</span>
      </template>
      <el-form label-width="90px" class="edit-form">
        <el-form-item label="标题">
          <el-input v-model="form.title" placeholder="请输入公告标题" />
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="form.content" type="textarea" :rows="10" placeholder="支持粘贴 HTML 或普通文本" />
        </el-form-item>
        <el-form-item label="封面">
          <el-input v-model="form.cover" placeholder="请输入封面图片URL" />
        </el-form-item>
        <el-form-item label="优先级">
          <el-input-number v-model="form.priority" :min="0" :precision="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status">
            <el-option label="草稿" value="draft" />
            <el-option label="已发布" value="published" />
            <el-option label="下线" value="offline" />
          </el-select>
        </el-form-item>
        <el-form-item label="发布时间">
          <el-date-picker v-model="form.publishFrom" type="datetime" value-format="x" placeholder="不限制"
            style="width: 100%;" />
        </el-form-item>
        <el-form-item label="下线时间">
          <el-date-picker v-model="form.publishTo" type="datetime" value-format="x" placeholder="不限制"
            style="width: 100%;" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button @click="previewForm">预览</el-button>
        <el-button type="primary" @click="save">保存</el-button>
      </template>
    </el-dialog>

    <!-- 预览弹窗 -->
    <el-dialog v-model="previewVisible" width="720px" :close-on-click-modal="false" class="detail-dialog" center>
      <template #header>
        <span class="dialog-title-bold">公告预览</span>
      </template>
      <div v-if="previewRow" class="detail-content">
        <div class="post-profile-card">
          <div class="post-basic-info">
            <div class="info-row">
              <span class="label">标题：</span>
              <span class="value title-text">{{ previewRow.title }}</span>
            </div>
            <div class="info-row">
              <span class="label">状态：</span>
              <el-tag
                :type="previewRow.status === 'published' ? 'success' : previewRow.status === 'offline' ? 'info' : 'warning'"
                size="small" effect="dark">
                {{ statusLabel(previewRow.status) }}
              </el-tag>
            </div>
            <div class="info-row">
              <span class="label">优先级：</span>
              <span class="value">{{ previewRow.priority }}</span>
            </div>
          </div>
        </div>

        <div class="stats-grid">
          <div class="stat-item">
            <div class="stat-label">发布时间</div>
            <div class="stat-value text">{{ formatTime(previewRow.publishFrom) }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">下线时间</div>
            <div class="stat-value text">{{ formatTime(previewRow.publishTo) }}</div>
          </div>
          <div class="stat-item highlight">
            <div class="stat-label">浏览量</div>
            <div class="stat-value primary">{{ (previewRow as any).viewCount || 0 }}</div>
          </div>
        </div>

        <div class="preview">
          <el-image v-if="previewRow.cover" :src="previewRow.cover" fit="cover" class="cover" />
          <div class="content" v-html="previewRow.content"></div>
        </div>
      </div>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
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

.highlight-text {
  color: #409eff;
  font-weight: 600;
}

.edit-form {
  padding-top: 10px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #606266;
}

.preview {
  padding: 10px 0;
}

.preview-title {
  margin: 0 0 16px;
  font-size: 22px;
  font-weight: 600;
  color: #303133;
  line-height: 1.4;
}

.cover {
  width: 100%;
  height: 220px;
  border-radius: 8px;
  margin-bottom: 16px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.meta {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #909399;
  font-size: 13px;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 1px solid #ebeef5;
}

.meta-item {
  position: relative;
}

.meta-item:not(:last-child)::after {
  content: '';
  position: absolute;
  right: -8px;
  top: 50%;
  transform: translateY(-50%);
  width: 1px;
  height: 12px;
  background-color: #dcdfe6;
}

.content {
  line-height: 1.8;
  white-space: pre-wrap;
  color: #606266;
  font-size: 15px;
}

:deep(.content img) {
  max-width: 100%;
  border-radius: 8px;
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

.detail-content {
  padding: 10px 5px;
}

.post-profile-card {
  display: flex;
  padding: 24px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  border-radius: 12px;
  border: 1px solid #ebeef5;
  margin-bottom: 24px;
  align-items: center;
}

.post-icon-wrapper {
  flex-shrink: 0;
}

.post-icon {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409eff 0%, #79bbff 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  font-weight: bold;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
}

.post-basic-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-row {
  display: flex;
  align-items: center;
  font-size: 15px;
}

.info-row .label {
  color: #909399;
  width: 70px;
  flex-shrink: 0;
}

.info-row .value {
  color: #303133;
  font-weight: 500;
}

.title-text {
  font-size: 18px;
  font-weight: 600;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.stat-item {
  background: #fff;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 16px;
  text-align: center;
  transition: all 0.3s ease;
}

.stat-item:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
  border-color: #dcdfe6;
}

.stat-label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
}

.stat-value {
  font-size: 20px;
  font-weight: bold;
  color: #303133;
}

.stat-value.text {
  font-size: 14px;
  font-weight: normal;
}

.stat-value.primary {
  color: #409eff;
}

.stat-item.highlight {
  background-color: #ecf5ff;
  border-color: #b3d8ff;
}

.mr-4 {
  margin-right: 4px;
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