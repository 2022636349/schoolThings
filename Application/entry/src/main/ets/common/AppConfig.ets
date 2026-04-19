/**
 * 全局配置
 * 所有调用后端的地方统一从这里读 baseURL
 *
 * 真机调试时把 baseURL 改成局域网 IP，例如：
 *   http://192.168.0.100:8080/api
 * 生产环境改成正式域名，例如：
 *   https://api.example.com/api
 */
export class AppConfig {
  /** 后端基础地址（末尾不要带斜杠） */
  static readonly baseURL: string = 'http://10.48.220.83:8080/api';

  /** 请求超时（毫秒） */
  static readonly timeoutMs: number = 15000;
}
