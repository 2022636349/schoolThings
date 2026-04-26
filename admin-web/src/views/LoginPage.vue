<template>
  <div class="login-page" @mousemove="handleMouseMove">
    <div class="aurora aurora-a"></div>
    <div class="aurora aurora-b"></div>
    <div class="aurora aurora-c"></div>

    <div class="particle-field" aria-hidden="true">
      <span v-for="dot in particles" :key="dot.id" class="particle" :style="dot.style"></span>
    </div>

    <section class="login-shell">
      <div class="intro-panel">
        <div class="system-badge">
          <span class="badge-dot"></span>
          校园失物招领后台
        </div>
        <h1>让每一条线索都被清晰处理</h1>
        <p>统一管理帖子、用户、举报投诉与公告，帮助管理员更快完成校园失物招领流程。</p>

        <div class="metric-grid">
          <div class="metric-card">
            <strong>实时</strong>
            <span>消息与异议状态同步</span>
          </div>
          <div class="metric-card">
            <strong>清晰</strong>
            <span>运营数据集中呈现</span>
          </div>
          <div class="metric-card">
            <strong>安全</strong>
            <span>管理员权限独立校验</span>
          </div>
        </div>
      </div>

      <el-card class="login-card" shadow="never">
        <div class="scan-line"></div>
        <div class="brand">
          <div class="brand-icon">
            <img :src="myLogo" alt="校园失物招领" />
          </div>
          <div>
            <div class="brand-title">管理端登录</div>
            <div class="brand-sub">Lost &amp; Found Admin Console</div>
          </div>
        </div>

        <el-form class="login-form" @submit.prevent label-position="top">
          <el-form-item label="管理员账号">
            <el-input
              v-model="username"
              size="large"
              placeholder="请输入管理员账号"
              @keyup.enter="handleLogin"
            />
          </el-form-item>
          <el-form-item label="登录密码">
            <el-input
              v-model="password"
              size="large"
              type="password"
              placeholder="请输入登录密码"
              show-password
              @keyup.enter="handleLogin"
            />
          </el-form-item>

          <el-button class="login-btn" type="primary" :loading="loading" @click="handleLogin">
            <span>进入管理后台</span>
          </el-button>
        </el-form>

        <div class="security-line">
          <span></span>
          管理员操作将被系统记录
        </div>
      </el-card>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '../stores/user'
import { adminApi } from '../api/admin'
import myLogo from '../assets/logo.png'

interface ParticleConfig {
  id: number
  style: Record<string, string>
}

const router = useRouter()
const userStore = useUserStore()
const username = ref('admin')
const password = ref('admin123')
const loading = ref(false)

const particles = computed<ParticleConfig[]>(() => {
  return Array.from({ length: 34 }, (_, index) => {
    const size = 2 + (index % 5)
    return {
      id: index,
      style: {
        width: `${size}px`,
        height: `${size}px`,
        left: `${(index * 37) % 100}%`,
        top: `${(index * 19) % 100}%`,
        animationDelay: `${(index % 9) * 0.55}s`,
        animationDuration: `${9 + (index % 7)}s`
      }
    }
  })
})

const handleMouseMove = (event: MouseEvent) => {
  const target = event.currentTarget as HTMLElement
  const rect = target.getBoundingClientRect()
  target.style.setProperty('--mouse-x', `${event.clientX - rect.left}px`)
  target.style.setProperty('--mouse-y', `${event.clientY - rect.top}px`)
}

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
  --mouse-x: 50%;
  --mouse-y: 50%;
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  padding: 40px 24px;
  color: #eaf2ff;
  background:
    radial-gradient(circle at var(--mouse-x) var(--mouse-y), rgba(84, 184, 255, 0.24), transparent 260px),
    linear-gradient(135deg, #0b1221 0%, #102b36 45%, #172219 100%);
}

.login-page::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
  background-size: 44px 44px;
  mask-image: radial-gradient(circle at center, black, transparent 72%);
  opacity: 0.34;
}

.login-page::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(120deg, transparent 0%, rgba(255, 255, 255, 0.08) 45%, transparent 60%);
  transform: translateX(-100%);
  animation: pageShine 8s ease-in-out infinite;
}

.aurora {
  position: absolute;
  width: 380px;
  height: 380px;
  border-radius: 50%;
  filter: blur(24px);
  opacity: 0.5;
  animation: floatAurora 12s ease-in-out infinite;
}

.aurora-a {
  left: 8%;
  top: 8%;
  background: rgba(69, 152, 255, 0.42);
}

.aurora-b {
  right: 9%;
  top: 18%;
  background: rgba(65, 214, 168, 0.34);
  animation-delay: -4s;
}

.aurora-c {
  right: 28%;
  bottom: -12%;
  background: rgba(255, 188, 92, 0.26);
  animation-delay: -7s;
}

.particle-field {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.particle {
  position: absolute;
  border-radius: 50%;
  background: rgba(219, 245, 255, 0.9);
  box-shadow: 0 0 16px rgba(91, 196, 255, 0.9);
  animation: particleDrift linear infinite;
}

.login-shell {
  position: relative;
  z-index: 2;
  width: min(1080px, 100%);
  display: grid;
  grid-template-columns: 1.08fr 440px;
  gap: 34px;
  align-items: center;
}

.intro-panel {
  animation: slideUp 680ms ease-out both;
}

.system-badge {
  width: fit-content;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 13px;
  border: 1px solid rgba(255, 255, 255, 0.18);
  border-radius: 999px;
  color: rgba(234, 242, 255, 0.84);
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
}

.badge-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #48d597;
  box-shadow: 0 0 14px #48d597;
}

.intro-panel h1 {
  max-width: 620px;
  margin: 26px 0 18px;
  font-size: clamp(42px, 6vw, 70px);
  line-height: 1.02;
  letter-spacing: 0;
}

.intro-panel p {
  max-width: 560px;
  margin: 0;
  color: rgba(234, 242, 255, 0.72);
  font-size: 17px;
  line-height: 1.8;
}

.metric-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-top: 34px;
}

.metric-card {
  min-height: 96px;
  padding: 18px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(14px);
  transition: transform 220ms ease, border-color 220ms ease, background 220ms ease;
}

.metric-card:hover {
  transform: translateY(-6px);
  border-color: rgba(106, 216, 255, 0.58);
  background: rgba(255, 255, 255, 0.12);
}

.metric-card strong {
  display: block;
  margin-bottom: 8px;
  font-size: 20px;
  color: #ffffff;
}

.metric-card span {
  color: rgba(234, 242, 255, 0.66);
  font-size: 13px;
  line-height: 1.55;
}

.login-card {
  position: relative;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.22);
  border-radius: 8px;
  background: rgba(248, 252, 255, 0.86);
  box-shadow: 0 28px 90px rgba(0, 0, 0, 0.34);
  backdrop-filter: blur(20px);
  animation: cardEnter 760ms cubic-bezier(.2, .8, .2, 1) both;
}

.login-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 34px 110px rgba(0, 0, 0, 0.42);
}

.login-card :deep(.el-card__body) {
  position: relative;
  padding: 34px;
}

.scan-line {
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, transparent, rgba(57, 175, 255, 0.18), transparent);
  transform: translateX(-120%);
  animation: scanLine 4.8s ease-in-out infinite;
  pointer-events: none;
}

.brand {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 30px;
}

.brand-icon {
  width: 54px;
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border-radius: 8px;
  background: linear-gradient(135deg, #e8f7ff, #ffffff);
  box-shadow: inset 0 0 0 1px rgba(36, 104, 180, 0.12), 0 14px 28px rgba(43, 120, 190, 0.18);
}

.brand-icon img {
  width: 36px;
  height: 36px;
  object-fit: contain;
}

.brand-title {
  font-size: 23px;
  font-weight: 800;
  color: #102033;
}

.brand-sub {
  margin-top: 4px;
  font-size: 13px;
  color: #6c7b8f;
}

.login-form {
  position: relative;
}

.login-form :deep(.el-form-item) {
  margin-bottom: 22px;
}

.login-form :deep(.el-form-item__label) {
  margin-bottom: 8px;
  color: #253246;
  font-weight: 700;
}

.login-form :deep(.el-input__wrapper) {
  height: 48px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.88);
  box-shadow: inset 0 0 0 1px rgba(35, 58, 86, 0.12);
  transition: transform 180ms ease, box-shadow 180ms ease, background 180ms ease;
}

.login-form :deep(.el-input__wrapper:hover) {
  transform: translateY(-2px);
  box-shadow: inset 0 0 0 1px rgba(26, 143, 229, 0.32), 0 10px 22px rgba(39, 112, 188, 0.12);
}

.login-form :deep(.el-input__wrapper.is-focus) {
  background: #ffffff;
  box-shadow: inset 0 0 0 1px #2b9cf0, 0 0 0 4px rgba(43, 156, 240, 0.13);
}

.login-btn {
  width: 100%;
  height: 50px;
  margin-top: 4px;
  border: 0;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 800;
  background: linear-gradient(135deg, #1278df, #21b39c);
  box-shadow: 0 16px 32px rgba(20, 132, 204, 0.3);
  transition: transform 180ms ease, box-shadow 180ms ease, filter 180ms ease;
}

.login-btn:hover {
  transform: translateY(-3px);
  filter: saturate(1.08);
  box-shadow: 0 22px 42px rgba(20, 132, 204, 0.38);
}

.login-btn:active {
  transform: translateY(0);
}

.security-line {
  display: flex;
  align-items: center;
  gap: 9px;
  justify-content: center;
  margin-top: 24px;
  color: #77849a;
  font-size: 12px;
}

.security-line span {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #21b39c;
  box-shadow: 0 0 10px rgba(33, 179, 156, 0.8);
}

@keyframes cardEnter {
  from {
    opacity: 0;
    transform: translateY(24px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(22px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes particleDrift {
  0% {
    transform: translate3d(0, 0, 0);
    opacity: 0;
  }
  16% {
    opacity: 0.85;
  }
  100% {
    transform: translate3d(26px, -120px, 0);
    opacity: 0;
  }
}

@keyframes floatAurora {
  0%, 100% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  50% {
    transform: translate3d(28px, -18px, 0) scale(1.08);
  }
}

@keyframes scanLine {
  0%, 42% {
    transform: translateX(-120%);
  }
  72%, 100% {
    transform: translateX(120%);
  }
}

@keyframes pageShine {
  0%, 58% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

@media (max-width: 900px) {
  .login-shell {
    grid-template-columns: 1fr;
    max-width: 480px;
  }

  .intro-panel {
    display: none;
  }
}

@media (max-width: 520px) {
  .login-page {
    padding: 22px 14px;
  }

  .login-card :deep(.el-card__body) {
    padding: 26px 20px;
  }

  .brand-title {
    font-size: 20px;
  }
}
</style>
