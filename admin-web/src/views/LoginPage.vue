<template>
  <div class="login-page">
    <el-card class="login-card">
      <h2>后台登录</h2>
      <el-form @submit.prevent>
        <el-form-item>
          <el-input v-model="username" placeholder="管理员账号" />
        </el-form-item>
        <el-form-item>
          <el-input v-model="password" type="password" placeholder="密码" show-password />
        </el-form-item>
        <el-button type="primary" style="width: 100%" :loading="loading" @click="handleLogin">登录</el-button>
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
  background: #f5f7fa;
}
.login-card {
  width: 360px;
}
</style>
