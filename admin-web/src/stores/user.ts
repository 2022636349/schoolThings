import { defineStore } from 'pinia'

interface UserState {
  token: string
  username: string
  role: string
}

const TOKEN_KEY = 'admin_token'
const USERNAME_KEY = 'admin_username'
const ROLE_KEY = 'admin_role'

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    token: localStorage.getItem(TOKEN_KEY) || '',
    username: localStorage.getItem(USERNAME_KEY) || '',
    role: localStorage.getItem(ROLE_KEY) || ''
  }),
  actions: {
    login(token: string, username: string, role: string) {
      this.token = token
      this.username = username
      this.role = role
      localStorage.setItem(TOKEN_KEY, token)
      localStorage.setItem(USERNAME_KEY, username)
      localStorage.setItem(ROLE_KEY, role)
    },
    logout() {
      this.token = ''
      this.username = ''
      this.role = ''
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USERNAME_KEY)
      localStorage.removeItem(ROLE_KEY)
    }
  }
})
