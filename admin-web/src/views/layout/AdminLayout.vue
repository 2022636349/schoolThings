<template>
  <div class="layout-wrapper">
    <aside class="sidebar-container">
      <div class="sidebar-logo">
        <img src="/src/assets/logo.png" class="sidebar-logo-img" />
        <span>失物招领管理系统</span>
      </div>

      <el-scrollbar>
        <el-menu :default-active="$route.path" router background-color="#001529" text-color="#b8bec5"
          active-text-color="#ffffff" class="custom-menu">
          <el-menu-item index="/dashboard">
            <el-icon>
              <DataLine />
            </el-icon>
            <span>仪表盘概览</span>
          </el-menu-item>

          <div class="menu-divider">管理模块</div>

          <el-menu-item index="/users">
            <el-icon>
              <User />
            </el-icon>
            <span>用户管理</span>
          </el-menu-item>
          <el-menu-item index="/items">
            <el-icon>
              <Collection />
            </el-icon>
            <span>寻物拾物帖子</span>
          </el-menu-item>
          <el-menu-item index="/announcements">
            <el-icon>
              <Notification />
            </el-icon>
            <span>系统公告发布</span>
          </el-menu-item>

          <div class="menu-divider">运维反馈</div>

          <el-menu-item index="/reports">
            <el-icon>
              <Warning />
            </el-icon>
            <span>举报投诉处理</span>
          </el-menu-item>
          <el-menu-item index="/feedbacks">
            <el-icon>
              <ChatDotSquare />
            </el-icon>
            <span>意见反馈中心</span>
          </el-menu-item>
          <el-menu-item index="/chat-sessions">
            <el-icon>
              <ChatLineRound />
            </el-icon>
            <span>即时会话监控</span>
          </el-menu-item>
        </el-menu>
      </el-scrollbar>
    </aside>

    <div class="main-container">
      <header class="main-header">
        <div class="header-left">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item>后台管理</el-breadcrumb-item>
            <el-breadcrumb-item>{{ activeMenuName }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>

        <div class="header-right">
          <div class="user-profile">
            <el-avatar :size="32" class="user-avatar">
              {{ (userStore.username || '管').substring(0, 1) }}
            </el-avatar>
            <div class="user-info">
              <span class="username">{{ userStore.username || '管理员' }}</span>
              <span class="role-tag" v-if="userStore.role">{{ userStore.role }}</span>
            </div>
          </div>

          <div class="action-buttons">
            <el-tooltip content="修改密码" placement="bottom">
              <el-button circle @click="passwordVisible = true">
                <el-icon>
                  <Lock />
                </el-icon>
              </el-button>
            </el-tooltip>
            <el-tooltip content="退出系统" placement="bottom">
              <el-button circle type="danger" plain @click="logout">
                <el-icon>
                  <SwitchButton />
                </el-icon>
              </el-button>
            </el-tooltip>
          </div>
        </div>
      </header>

      <main class="main-content">
        <router-view v-slot="{ Component }">
          <transition name="fade-transform" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>
    </div>
  </div>

  <el-dialog v-model="passwordVisible" width="420px" :close-on-click-modal="false" align-center class="pwd-dialog">
  <template #header>
    <div class="pwd-dialog-header">
      <el-icon><Lock /></el-icon>
      <span>安全中心 - 修改密码</span>
    </div>
  </template>

  <el-form label-position="top" class="pwd-form">
    <el-form-item label="当前原密码">
      <el-input v-model="oldPassword" type="password" show-password placeholder="请输入原始登录密码" size="default" />
    </el-form-item>
    <el-form-item label="设置新密码">
      <el-input v-model="newPassword" type="password" show-password placeholder="建议使用8位以上字母数字组合" size="default" />
    </el-form-item>
  </el-form>

  <template #footer>
    <div class="pwd-dialog-footer">
      <el-button @click="passwordVisible = false">取消返回</el-button>
      <el-button type="primary" @click="changePassword" class="confirm-btn">
        确认更新密码
      </el-button>
    </div>
  </template>
</el-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  DataLine, User, Collection, Notification,
  Warning, ChatDotSquare, ChatLineRound,
  Lock, SwitchButton
} from '@element-plus/icons-vue'
import { useUserStore } from '../../stores/user'
import { adminApi } from '../../api/admin'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const passwordVisible = ref(false)
const oldPassword = ref('')
const newPassword = ref('')

const activeMenuName = computed(() => {
  const map: Record<string, string> = {
    '/dashboard': '仪表盘概览',
    '/users': '用户管理',
    '/items': '寻物拾物帖子',
    '/announcements': '系统公告发布',
    '/reports': '举报投诉处理',
    '/feedbacks': '意见反馈中心',
    '/chat-sessions': '即时会话监控'
  }
  return map[route.path] || '页面'
})

const logout = () => {
  userStore.logout()
  router.replace('/login')
}

const changePassword = async () => {
  if (!oldPassword.value || !newPassword.value) {
    return ElMessage.warning('请填写完整密码信息')
  }
  await adminApi.changePassword({ oldPassword: oldPassword.value, newPassword: newPassword.value })
  ElMessage.success('密码修改成功，请重新登录')
  passwordVisible.value = false
  logout()
}
</script>

<style scoped>
.layout-wrapper {
  display: flex;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
}

.sidebar-container {
  width: 240px;
  background: #001529;
  display: flex;
  flex-direction: column;
  box-shadow: 2px 0 8px rgba(0, 21, 41, 0.15);
  z-index: 10;
}

.sidebar-logo {
  height: 64px;
  display: flex;
  align-items: center;
  padding: 0 20px;
  gap: 12px;
  background: #002140;
}
.sidebar-logo-img {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  object-fit: cover;
}
.logo-icon {
  width: 32px;
  height: 32px;
  background: linear-gradient(135deg, #409eff, #0052d9);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
}

.sidebar-logo span {
  color: #fff;
  font-weight: 600;
  font-size: 16px;
  letter-spacing: 1px;
}

.custom-menu {
  border-right: none;
}

.menu-divider {
  padding: 20px 20px 10px;
  font-size: 12px;
  color: #595959;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.main-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #f0f2f5;
}

.main-header {
  height: 64px;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
  z-index: 9;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 24px;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 12px;
  padding-right: 16px;
  border-right: 1px solid #f0f0f0;
}

.user-avatar {
  background: #000000;
  font-weight: bold;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.username {
  font-size: 14px;
  font-weight: 600;
  color: #262626;
}

.role-tag {
  font-size: 11px;
  color: #8c8c8c;
  background: #f5f5f5;
  padding: 0 4px;
  border-radius: 2px;
  width: fit-content;
}

.action-buttons {
  display: flex;
  gap: 8px;
}

.main-content {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
}

.pwd-dialog {
  --pwd-color: #165DFF;
}

.pwd-dialog-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 700;
  color: #1d2129;
}
.pwd-dialog-header svg {
  color: #165DFF;
  width: 18px;
  height: 18px;
}

.pwd-form {
  padding: 10px 0 20px;
}

.pwd-dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding-top: 10px;
}

.confirm-btn {
  padding-left: 24px;
  padding-right: 24px;
}

.fade-transform-enter-active,
.fade-transform-leave-active {
  transition: all 0.3s;
}

.fade-transform-enter-from {
  opacity: 0;
  transform: translateX(-10px);
}

.fade-transform-leave-to {
  opacity: 0;
  transform: translateX(10px);
}

.save-btn {
  padding-left: 30px;
  padding-right: 30px;
}

:deep(.el-menu-item.is-active) {
  border-radius: 4px;
  margin: 0 8px;
  height: 40px;
  line-height: 40px;
}

:deep(.el-menu-item) {
  height: 40px;
  line-height: 40px;
  margin: 4px 8px;
}

:deep(.el-menu-item.is-active) {
  background-color: #0f3460  !important;
  color: #ffffff !important;
}

:deep(.el-menu-item:not(.is-active):hover) {
  background-color: #143b6b  !important;
  color: #ffffff !important;
}
</style>