<template>
  <div class="layout">
    <aside class="sidebar">
      <div class="logo">失物招领后台</div>
      <el-menu :default-active="$route.path" router>
        <el-menu-item index="/dashboard">仪表盘</el-menu-item>
        <el-menu-item index="/users">用户管理</el-menu-item>
        <el-menu-item index="/items">帖子管理</el-menu-item>
        <el-menu-item index="/announcements">公告管理</el-menu-item>
        <el-menu-item index="/claims">认领申请</el-menu-item>
        <el-menu-item index="/reports">举报管理</el-menu-item>
        <el-menu-item index="/feedbacks">反馈管理</el-menu-item>
        <el-menu-item index="/chat-sessions">会话查看</el-menu-item>
      </el-menu>
    </aside>
    <div class="main">
      <header class="header">
        <span>{{ userStore.username || '管理员' }}<span v-if="userStore.role">（{{ userStore.role }}）</span></span>
        <el-button link @click="passwordVisible = true">修改密码</el-button>
        <el-button link type="danger" @click="logout">退出</el-button>
      </header>
      <main class="content">
        <router-view />
      </main>
    </div>
  </div>

  <el-dialog v-model="passwordVisible" title="修改密码" width="420px">
    <el-form label-width="90px">
      <el-form-item label="原密码">
        <el-input v-model="oldPassword" type="password" show-password />
      </el-form-item>
      <el-form-item label="新密码">
        <el-input v-model="newPassword" type="password" show-password />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="passwordVisible = false">取消</el-button>
      <el-button type="primary" @click="changePassword">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '../../stores/user'
import { adminApi } from '../../api/admin'

const router = useRouter()
const userStore = useUserStore()
const passwordVisible = ref(false)
const oldPassword = ref('')
const newPassword = ref('')

const logout = () => {
  userStore.logout()
  router.replace('/login')
}

const changePassword = async () => {
  await adminApi.changePassword({ oldPassword: oldPassword.value, newPassword: newPassword.value })
  ElMessage.success('密码修改成功，请重新登录')
  passwordVisible.value = false
  oldPassword.value = ''
  newPassword.value = ''
  logout()
}
</script>

<style scoped>
.layout { display: flex; min-height: 100vh; }
.sidebar { width: 220px; background: #001529; color: #fff; }
.logo { height: 56px; display:flex; align-items:center; justify-content:center; font-weight:700; }
.main { flex:1; background:#f5f7fa; }
.header { height:56px; background:#fff; display:flex; align-items:center; justify-content:flex-end; padding:0 20px; gap:12px; }
.content { padding:20px; }
</style>
