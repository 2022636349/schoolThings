import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '../stores/user'

const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://81.71.7.190:8080/api',
  timeout: 15000
})

// const http = axios.create({
//   // 如果环境变量有配就用环境变量，否则动态获取当前访问的 IP（保留 8080 端口）
//   baseURL: import.meta.env.VITE_API_BASE_URL || `http://${window.location.hostname}:8080/api`,
//   timeout: 15000
// })

http.interceptors.request.use((config) => {
  const userStore = useUserStore()
  if (userStore.token) {
    config.headers.Authorization = `Bearer ${userStore.token}`
  }
  return config
})

http.interceptors.response.use((response) => {
  if (window.location.pathname.includes('/dashboard')) {
    console.warn('http response debug', response.config?.url, response.data)
  }
  return response.data.data
}, (error) => {
  const userStore = useUserStore()
  const message = error?.response?.data?.message || error?.message || '请求失败'
  if (error?.response?.status === 401) {
    userStore.logout()
    window.location.href = '/login'
  }
  ElMessage.error(message)
  return Promise.reject(error)
})

export default http
