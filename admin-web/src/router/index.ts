import { createRouter, createWebHistory } from 'vue-router'
import LoginPage from '../views/LoginPage.vue'
import AdminLayout from '../views/layout/AdminLayout.vue'
import DashboardPage from '../views/DashboardPage.vue'
import UsersPage from '../views/UsersPage.vue'
import ItemsPage from '../views/ItemsPage.vue'
import AnnouncementsPage from '../views/AnnouncementsPage.vue'
import ClaimsPage from '../views/ClaimsPage.vue'
import ReportsPage from '../views/ReportsPage.vue'
import FeedbacksPage from '../views/FeedbacksPage.vue'
import ChatSessionsPage from '../views/ChatSessionsPage.vue'
import { useUserStore } from '../stores/user'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: LoginPage },
    {
      path: '/',
      component: AdminLayout,
      meta: { requiresAuth: true },
      children: [
        { path: '', redirect: '/dashboard' },
        { path: '/dashboard', component: DashboardPage },
        { path: '/users', component: UsersPage },
        { path: '/items', component: ItemsPage },
        { path: '/announcements', component: AnnouncementsPage },
        { path: '/claims', component: ClaimsPage },
        { path: '/reports', component: ReportsPage },
        { path: '/feedbacks', component: FeedbacksPage },
        { path: '/chat-sessions', component: ChatSessionsPage }
      ]
    }
  ]
})

router.beforeEach((to, _from, next) => {
  const userStore = useUserStore()
  if (to.meta.requiresAuth && !userStore.token) {
    next('/login')
    return
  }
  if (to.path === '/login' && userStore.token) {
    next('/dashboard')
    return
  }
  next()
})

export default router
