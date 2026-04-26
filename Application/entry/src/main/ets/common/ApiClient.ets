import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { AppConfig } from './AppConfig';
import { Session } from './Session';
import { NetworkMonitor } from './NetworkMonitor';

export interface ApiResult<T> {
  code: number;
  message: string;
  data: T;
}

interface UploadBase64Body {
  prefix: string;
  name: string;
  base64: string;
  contentType: string;
}

interface RefreshTokenResp {
  accessToken: string;
  refreshToken: string;
}

export class ApiError extends Error {
  code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

type QueryValue = string | number | boolean | null | undefined;
type QueryMap = Record<string, QueryValue>;

function buildQuery(params?: QueryMap): string {
  if (!params) return '';
  const parts: string[] = [];
  const keys = Object.keys(params);
  for (const k of keys) {
    const v = params[k];
    if (v === null || v === undefined) continue;
    parts.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);
  }
  return parts.length > 0 ? '?' + parts.join('&') : '';
}

let globalContext: common.UIAbilityContext | null = null;
let hasShownSessionExpiredToast: boolean = false;

export class ApiClient {
  static setContext(ctx: common.UIAbilityContext): void {
    globalContext = ctx;
  }

  static getContext(): common.UIAbilityContext | null {
    return globalContext;
  }

  private static resolveContext(ctx?: common.UIAbilityContext): common.UIAbilityContext | null {
    return ctx ?? globalContext;
  }

  static async get<T>(path: string, params?: QueryMap, ctx?: common.UIAbilityContext): Promise<T> {
    return ApiClient.request<T>('GET', path + buildQuery(params), undefined, ctx);
  }

  static async post<T>(path: string, body?: Object, ctx?: common.UIAbilityContext): Promise<T> {
    return ApiClient.request<T>('POST', path, body, ctx);
  }

  static async put<T>(path: string, body?: Object, ctx?: common.UIAbilityContext): Promise<T> {
    return ApiClient.request<T>('PUT', path, body, ctx);
  }

  static async del<T>(path: string, ctx?: common.UIAbilityContext): Promise<T> {
    return ApiClient.request<T>('DELETE', path, undefined, ctx);
  }

  private static handleSessionExpired(ctx?: common.UIAbilityContext): void {

    if (!NetworkMonitor.isOnline()) {
      return;
    }
    const resolvedCtx = ApiClient.resolveContext(ctx);
    if (resolvedCtx) {
      Session.clear(resolvedCtx);
    }
    if (!hasShownSessionExpiredToast) {
      hasShownSessionExpiredToast = true;
      promptAction.showToast({ message: '登录已失效，请重新登录' });
    }
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  private static resetSessionExpiredFlag(): void {
    hasShownSessionExpiredToast = false;
  }

  private static async request<T>(
    method: string,
    path: string,
    body: Object | undefined,
    ctx?: common.UIAbilityContext,
    hasRetried: boolean = false
  ): Promise<T> {
    const url = AppConfig.baseURL + path;
    const token = ApiClient.readToken(ctx);

    const header: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (token && token.length > 0) {
      header['Authorization'] = 'Bearer ' + token;
    }

    const httpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: ApiClient.toMethod(method),
        header: header,
        readTimeout: AppConfig.timeoutMs,
        connectTimeout: AppConfig.timeoutMs,
        expectDataType: http.HttpDataType.STRING
      };
      if (body !== undefined && body !== null) {
        options.extraData = JSON.stringify(body);
      }

      let resp: http.HttpResponse;
      try {
        resp = await httpRequest.request(url, options);
      } catch (e) {

        NetworkMonitor.reportRequestFailure();
        throw new ApiError(-1, '网络连接失败，请检查网络');
      }

      NetworkMonitor.reportRequestSuccess();

      const status = resp.responseCode;
      const raw = (typeof resp.result === 'string') ? resp.result : JSON.stringify(resp.result);

      if (status < 200 || status >= 300) {
        if ((status === 401 || status === 403) && !hasRetried && await ApiClient.tryRefreshToken(ctx)) {
          return ApiClient.request<T>(method, path, body, ctx, true);
        }
        if (status === 401 || status === 403) {
          ApiClient.handleSessionExpired(ctx);
        }
        throw new ApiError(status, `HTTP ${status}: ${raw}`);
      }

      if (!raw || raw.length === 0) {
        return null as T;
      }
      const parsed = JSON.parse(raw) as ApiResult<T>;
      if ((parsed.code === 2001 || parsed.code === 2004) && !hasRetried && await ApiClient.tryRefreshToken(ctx)) {
        return ApiClient.request<T>(method, path, body, ctx, true);
      }
      if (parsed.code === 2001 || parsed.code === 2004) {
        ApiClient.handleSessionExpired(ctx);
      }
      if (parsed.code !== 0 && parsed.code !== 200) {
        throw new ApiError(parsed.code, parsed.message || '接口调用失败');
      }
      ApiClient.resetSessionExpiredFlag();
      return parsed.data;
    } finally {
      httpRequest.destroy();
    }
  }

  private static toMethod(m: string): http.RequestMethod {
    switch (m) {
      case 'POST': return http.RequestMethod.POST;
      case 'PUT': return http.RequestMethod.PUT;
      case 'DELETE': return http.RequestMethod.DELETE;
      case 'GET':
      default: return http.RequestMethod.GET;
    }
  }

  private static async tryRefreshToken(ctx?: common.UIAbilityContext): Promise<boolean> {
    const c = ApiClient.resolveContext(ctx);
    if (!c) return false;
    const refreshToken = Session.getRefreshToken(c);
    if (!refreshToken) return false;

    const url = AppConfig.baseURL + '/auth/refresh?refreshToken=' + encodeURIComponent(refreshToken);
    const httpRequest = http.createHttp();
    try {
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        readTimeout: AppConfig.timeoutMs,
        connectTimeout: AppConfig.timeoutMs,
        expectDataType: http.HttpDataType.STRING
      });
      if (resp.responseCode < 200 || resp.responseCode >= 300) return false;
      const raw = (typeof resp.result === 'string') ? resp.result : JSON.stringify(resp.result);
      if (!raw) return false;
      const parsed = JSON.parse(raw) as ApiResult<RefreshTokenResp>;
      if (parsed.code !== 0 || !parsed.data || !parsed.data.accessToken) return false;
      Session.updateTokens(c, parsed.data.accessToken, parsed.data.refreshToken || refreshToken);
      return true;
    } catch (e) {
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  private static readToken(ctx?: common.UIAbilityContext): string {
    const c = ApiClient.resolveContext(ctx);
    if (!c) return '';
    try {
      return Session.getAccessToken(c);
    } catch (e) {
      return '';
    }
  }

  static async uploadBase64(
    prefix: string,
    fileName: string,
    base64: string,
    contentType: string,
    ctx?: common.UIAbilityContext
  ): Promise<string> {
    const body: UploadBase64Body = {
      prefix: prefix,
      name: fileName,
      base64: base64,
      contentType: contentType
    };
    const url: string = await ApiClient.post<string>('/upload/base64', body, ctx);
    return url;
  }
}
