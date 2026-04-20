import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '../stores/user'

const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api',
  timeout: 15000
})

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
