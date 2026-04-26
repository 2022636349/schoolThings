<template>
  <div class="login-page">
    <el-card class="login-card" :body-style="{ padding: '2.5rem 2rem' }">
      <div class="brand">
        <div class="brand-icon">
          <img :src="myLogo" class="vite" alt="My Logo" style="width: 40px;" />
        </div>
        <div>
          <div class="brand-title">失物招领管理系统</div>
          <div class="brand-sub">Lost &amp; Found Admin</div>
        </div>
      </div>
      <el-divider style="margin: 1.5rem 0" />
      <el-form @submit.prevent label-width="100px" label-position="left">
        <el-form-item label="管理员账号">
          <el-input v-model="username" placeholder="请输入账号" />
        </el-form-item>
        <el-form-item label="登录密码">
          <el-input v-model="password" type="password" placeholder="请输入密码" show-password />
        </el-form-item>
        <el-button class="custom-login-btn" type="primary" style="width: 100%; margin-top: 0.5rem" :loading="loading"
          @click="handleLogin">
          登 录
        </el-button>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '../stores/user'
import { adminApi } from '../api/admin'
import myLogo from '../assets/logo.png'

const router = useRouter()
const userStore = useUserStore()
const username = ref('admin')
const password = ref('admin123')
const loading = ref(false)

const handleLogin = async () => {
  if (!username.value || !password.value) {
    ElMessage.error('请输入账号密码')
    return
  }
  loading.value = true
  try {
    const resp = await adminApi.login({ username: username.value, password: password.value })
    userStore.login(resp.token, resp.username, resp.role || 'ADMIN')
    ElMessage.success('登录成功')
    router.replace('/dashboard')
  } catch {
    ElMessage.error('登录失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #f5f7fa 0%, #e4eaf5 100%);
}

.login-card {
  width: 460px;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.brand {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 10px 0;
}

.brand-icon {
  width: 44px;
  height: 44px;
  background: #ffffff;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.brand-icon svg {
  width: 24px;
  height: 24px;
}

.brand-title {
  font-size: 18px;
  font-weight: 600;
  color: #1a1a1a;
}

.brand-sub {
  font-size: 13px;
  color: #909399;
  margin-top: 2px;
}

.footer-tip {
  font-size: 12px;
  color: #c0c4cc;
  text-align: center;
  margin-top: 1.25rem;
}

.custom-login-btn {
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  background: #3d3d3d;
  border-color: #3d3d3d;
}

.custom-login-btn:hover {
  background: #5c5f63 !important;
  border-color: #5c5f63 !important;
}

.custom-login-btn:active {
  background: #000000 !important;
  border-color: #000000 !important;
}
</style>