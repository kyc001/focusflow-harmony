import http from '@ohos.net.http';
import { common } from '@kit.AbilityKit';
import preferences from '@ohos.data.preferences';
import { FocusProject, FocusTask, PomodoroRecord } from '../models/FocusModels';
import { focusDatabase } from './FocusDatabase';

// 后端响应包装
interface ServerResult<T> {
  code: number;
  msg: string;
  data: T;
}

// 后端同步包
interface SyncBundle {
  serverTime: number;
  server_time?: number;
  projects: ServerProject[];
  tasks: ServerTask[];
  pomodoros: ServerPomodoro[];
}

// 后端实体(字段名与后端 snake_case 一致,Jackson 自动转换)
interface ServerProject {
  id: number;
  userId: number;
  user_id?: number;
  name: string;
  color: string;
  icon: string;
  updatedAt: number;
  updated_at?: number;
  isDeleted: number;
  is_deleted?: number;
}

interface ServerTask {
  id: number;
  userId: number;
  user_id?: number;
  title: string;
  note: string;
  projectId: number;
  project_id?: number;
  priority: number;
  dueAt: number;
  due_at?: number;
  status: number;
  pomodoroCount: number;
  pomodoro_count?: number;
  createdAt: number;
  created_at?: number;
  updatedAt: number;
  updated_at?: number;
  completedAt: number;
  completed_at?: number;
  isDeleted: number;
  is_deleted?: number;
  clientRequestId: string;
  client_request_id?: string;
  tagsJson: string;
  tags_json?: string;
  subtasksJson: string;
  subtasks_json?: string;
}

interface ServerPomodoro {
  id: number;
  userId: number;
  user_id?: number;
  taskId: number;
  task_id?: number;
  startAt: number;
  start_at?: number;
  duration: number;
  completed: number;
  interruptReason: string;
  interrupt_reason?: string;
  updatedAt: number;
  updated_at?: number;
  clientRequestId: string;
  client_request_id?: string;
}

interface SyncPushRequest {
  projects: ServerProject[];
  tasks: ServerTask[];
  pomodoros: ServerPomodoro[];
}

interface AuthResponse {
  userId: number;
  user_id?: number;
  username: string;
  nickname: string;
  token: string;
}

interface SyncActionResult {
  success: boolean;
  message: string;
  serverTime?: number;
}

interface SyncPullResult {
  success: boolean;
  message: string;
  bundle?: SyncBundle;
}

const PREF_NAME: string = 'focus_sync';
const DEFAULT_BASE_URL: string = 'http://10.0.2.2:8080';

export class FocusSyncService {
  private pref?: preferences.Preferences;
  private baseUrl: string = DEFAULT_BASE_URL;
  private userId: number = 0;
  private token: string = '';

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    this.pref = await preferences.getPreferences(context, PREF_NAME);
    this.baseUrl = (await this.pref.get('sync.baseUrl', DEFAULT_BASE_URL)) as string;
    this.userId = (await this.pref.get('sync.userId', 0)) as number;
    this.token = (await this.pref.get('sync.token', '')) as string;
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  async saveBaseUrl(baseUrl: string): Promise<void> {
    this.baseUrl = this.normalizeBaseUrl(baseUrl);
    if (this.pref !== undefined) {
      await this.pref.put('sync.baseUrl', this.baseUrl);
      await this.pref.flush();
    }
  }

  isLoggedIn(): boolean {
    return this.userId > 0 && this.token.length > 0;
  }

  async login(username: string, password: string): Promise<SyncActionResult> {
    const loginBaseUrl: string = this.normalizeBaseUrl(this.baseUrl);
    try {
      const healthResponse: http.HttpResponse = await this.request(`${loginBaseUrl}/api/user/ping`, {
        method: http.RequestMethod.GET,
        connectTimeout: 6000,
        readTimeout: 6000,
        header: { 'Content-Type': 'application/json' }
      });
      const healthCode: number = Number(healthResponse.responseCode);
      if (healthCode < 200 || healthCode >= 300) {
        return { success: false, message: `服务器连通但健康检查返回 ${healthCode}` };
      }

      const response: http.HttpResponse = await this.request(`${loginBaseUrl}/api/user/login`, {
        method: http.RequestMethod.POST,
        connectTimeout: 10000,
        readTimeout: 15000,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ username: username, password: password })
      });
      const code: number = Number(response.responseCode);
      if (code < 200 || code >= 300) {
        return { success: false, message: `服务器返回 ${code}` };
      }
      const result: ServerResult<AuthResponse> = this.parseServerResult<AuthResponse>(response.result);
      if (result.code !== 200 || result.data === null) {
        return { success: false, message: result.msg || '登录失败' };
      }
      const resolvedUserId: number = result.data.userId === undefined ? Number(result.data.user_id) : result.data.userId;
      if (resolvedUserId !== resolvedUserId || resolvedUserId <= 0) {
        return { success: false, message: '登录响应缺少 userId' };
      }
      this.baseUrl = loginBaseUrl;
      this.userId = resolvedUserId;
      this.token = result.data.token;
      if (this.pref !== undefined) {
        await this.pref.put('sync.baseUrl', this.baseUrl);
        await this.pref.put('sync.userId', this.userId);
        await this.pref.put('sync.token', this.token);
        await this.pref.put('sync.username', result.data.username);
        await this.pref.put('sync.nickname', result.data.nickname);
        await this.pref.flush();
      }
      return { success: true, message: `欢迎，${result.data.nickname}` };
    } catch (err) {
      return { success: false, message: `网络错误：无法连接 ${loginBaseUrl}，详情：${this.formatNetworkError(err)}` };
    }
  }

  async logout(): Promise<void> {
    this.userId = 0;
    this.token = '';
    if (this.pref !== undefined) {
      await this.pref.delete('sync.userId');
      await this.pref.delete('sync.token');
      await this.pref.delete('sync.username');
      await this.pref.delete('sync.nickname');
      await this.pref.flush();
    }
  }

  async pullFromServer(since: number): Promise<SyncPullResult> {
    if (!this.isLoggedIn()) {
      return { success: false, message: '未登录' };
    }
    try {
      const url: string = `${this.baseUrl}/api/sync/pull?since=${since}`;
      const response: http.HttpResponse = await this.request(url, {
        method: http.RequestMethod.POST,
        connectTimeout: 10000,
        readTimeout: 20000,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.token}`,
          'X-User-Id': `${this.userId}`
        }
      });
      const code: number = Number(response.responseCode);
      if (code < 200 || code >= 300) {
        return { success: false, message: `服务器返回 ${code}` };
      }
      const result: ServerResult<SyncBundle> = this.parseServerResult<SyncBundle>(response.result);
      if (result.code !== 200 || result.data === null) {
        return { success: false, message: result.msg || 'pull 失败' };
      }
      return { success: true, message: 'pull 成功', bundle: result.data };
    } catch (err) {
      return { success: false, message: `网络错误：无法连接 ${this.baseUrl}，详情：${this.formatNetworkError(err)}` };
    }
  }

  async pushToServer(projects: FocusProject[], tasks: FocusTask[], pomodoros: PomodoroRecord[]): Promise<SyncActionResult> {
    if (!this.isLoggedIn()) {
      return { success: false, message: '未登录' };
    }
    const payload: SyncPushRequest = {
      projects: projects.map((p: FocusProject) => this.toServerProject(p)),
      tasks: tasks.map((t: FocusTask) => this.toServerTask(t)),
      pomodoros: pomodoros.map((r: PomodoroRecord) => this.toServerPomodoro(r))
    };
    try {
      const response: http.HttpResponse = await this.request(`${this.baseUrl}/api/sync/push`, {
        method: http.RequestMethod.POST,
        connectTimeout: 10000,
        readTimeout: 25000,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.token}`,
          'X-User-Id': `${this.userId}`
        },
        extraData: JSON.stringify(payload)
      });
      const code: number = Number(response.responseCode);
      if (code < 200 || code >= 300) {
        return { success: false, message: `服务器返回 ${code}` };
      }
      const result: ServerResult<SyncBundle> = this.parseServerResult<SyncBundle>(response.result);
      if (result.code !== 200) {
        return { success: false, message: result.msg || 'push 失败' };
      }
      return {
        success: true,
        message: 'push 成功',
        serverTime: result.data === undefined || result.data === null ? undefined : this.bundleServerTime(result.data)
      };
    } catch (err) {
      return { success: false, message: `网络错误：无法连接 ${this.baseUrl}，详情：${this.formatNetworkError(err)}` };
    }
  }

  async syncBidirectional(): Promise<SyncActionResult> {
    const lastSync: number = await this.lastServerSyncTime();
    const pullResult = await this.pullFromServer(lastSync);
    if (!pullResult.success || pullResult.bundle === undefined) {
      return { success: false, message: `下拉失败：${pullResult.message}` };
    }
    await this.mergeServerData(pullResult.bundle);
    const localProjects: FocusProject[] = await focusDatabase.getProjectsForSync();
    const localTasks: FocusTask[] = await focusDatabase.getTasksForSync();
    const localPomodoros: PomodoroRecord[] = await focusDatabase.getPomodorosForSync();
    const pushResult = await this.pushToServer(localProjects, localTasks, localPomodoros);
    if (!pushResult.success) {
      return { success: false, message: `上推失败：${pushResult.message}` };
    }
    await focusDatabase.markProjectsSynced(localProjects);
    await focusDatabase.markTasksSynced(localTasks);
    await focusDatabase.markPomodorosSynced(localPomodoros);
    if (this.pref !== undefined) {
      const serverTime: number = pushResult.serverTime || this.bundleServerTime(pullResult.bundle);
      await this.pref.put('sync.lastServerTime', serverTime);
      await this.pref.put('sync.lastSyncTime', serverTime);
      await this.pref.flush();
    }
    const pulledCount: number = pullResult.bundle.projects.length + pullResult.bundle.tasks.length + pullResult.bundle.pomodoros.length;
    const pushedCount: number = localProjects.length + localTasks.length + localPomodoros.length;
    return { success: true, message: `同步完成：下拉 ${pulledCount} 条，上推 ${pushedCount} 条` };
  }

  private async mergeServerData(bundle: SyncBundle): Promise<void> {
    for (const sp of bundle.projects) {
      const projectUpdatedAt: number = this.numberValue(sp.updatedAt, sp.updated_at, Date.now());
      const localUpdatedAt: number = await focusDatabase.localProjectUpdatedAt(sp.id);
      if (localUpdatedAt > projectUpdatedAt) {
        continue;
      }
      const local: FocusProject = {
        id: sp.id,
        name: sp.name,
        color: sp.color,
        icon: sp.icon,
        updatedAt: projectUpdatedAt,
        isDeleted: this.numberValue(sp.isDeleted, sp.is_deleted, 0)
      };
      await focusDatabase.upsertProject(local);
    }
    for (const st of bundle.tasks) {
      const taskUpdatedAt: number = this.numberValue(st.updatedAt, st.updated_at, Date.now());
      const taskClientRequestId: string = this.stringValue(st.clientRequestId, st.client_request_id, `client-task-${st.id}`);
      const localUpdatedAt: number = await focusDatabase.localTaskUpdatedAt(st.id, taskClientRequestId);
      if (localUpdatedAt > taskUpdatedAt) {
        continue;
      }
      const local: FocusTask = {
        id: st.id,
        title: st.title,
        note: st.note,
        projectId: this.numberValue(st.projectId, st.project_id, 0),
        priority: st.priority,
        dueAt: this.numberValue(st.dueAt, st.due_at, 0),
        status: st.status,
        pomodoroCount: this.numberValue(st.pomodoroCount, st.pomodoro_count, 0),
        createdAt: this.numberValue(st.createdAt, st.created_at, Date.now()),
        completedAt: this.numberValue(st.completedAt, st.completed_at, 0),
        tags: this.parseJsonArray(this.stringValue(st.tagsJson, st.tags_json, '[]')),
        subtasks: this.parseJsonArray(this.stringValue(st.subtasksJson, st.subtasks_json, '[]')),
        updatedAt: taskUpdatedAt,
        isDeleted: this.numberValue(st.isDeleted, st.is_deleted, 0),
        clientRequestId: taskClientRequestId
      };
      await focusDatabase.upsertTask(local);
    }
    for (const sr of bundle.pomodoros) {
      const clientRequestId: string = this.stringValue(sr.clientRequestId, sr.client_request_id, '');
      const local: PomodoroRecord = {
        id: sr.id,
        taskId: this.numberValue(sr.taskId, sr.task_id, 0),
        startAt: this.numberValue(sr.startAt, sr.start_at, Date.now()),
        duration: sr.duration,
        completed: sr.completed,
        interruptReason: this.stringValue(sr.interruptReason, sr.interrupt_reason, ''),
        updatedAt: this.numberValue(sr.updatedAt, sr.updated_at, Date.now()),
        clientRequestId: clientRequestId.length > 0 ? clientRequestId : `server-pomo-${sr.id}`
      };
      await focusDatabase.upsertPomodoro(local);
    }
  }

  private toServerProject(p: FocusProject): ServerProject {
    return {
      id: p.id,
      userId: this.userId,
      name: p.name,
      color: p.color,
      icon: p.icon,
      updatedAt: p.updatedAt === undefined || p.updatedAt <= 0 ? Date.now() : p.updatedAt,
      isDeleted: p.isDeleted === undefined ? 0 : p.isDeleted
    };
  }

  private toServerTask(t: FocusTask): ServerTask {
    const clientRequestId: string = this.localTaskClientRequestId(t);
    return {
      id: t.id,
      userId: this.userId,
      title: t.title,
      note: t.note,
      projectId: t.projectId,
      priority: t.priority,
      dueAt: t.dueAt,
      status: t.status,
      pomodoroCount: t.pomodoroCount,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt === undefined || t.updatedAt <= 0 ? Date.now() : t.updatedAt,
      completedAt: t.completedAt,
      isDeleted: t.isDeleted === undefined ? (t.status === 2 ? 1 : 0) : t.isDeleted,
      clientRequestId: clientRequestId,
      tagsJson: JSON.stringify(t.tags),
      subtasksJson: JSON.stringify(t.subtasks)
    };
  }

  private localTaskClientRequestId(t: FocusTask): string {
    if (t.clientRequestId !== undefined && t.clientRequestId.trim().length > 0) {
      return t.clientRequestId.trim();
    }
    return `client-task-${t.id}`;
  }

  private toServerPomodoro(r: PomodoroRecord): ServerPomodoro {
    return {
      id: r.id,
      userId: this.userId,
      taskId: r.taskId,
      startAt: r.startAt,
      duration: r.duration,
      completed: r.completed,
      interruptReason: r.interruptReason,
      updatedAt: r.updatedAt === undefined || r.updatedAt <= 0 ? Date.now() : r.updatedAt,
      clientRequestId: this.localPomodoroClientRequestId(r)
    };
  }

  private localPomodoroClientRequestId(r: PomodoroRecord): string {
    if (r.clientRequestId !== undefined && r.clientRequestId.trim().length > 0) {
      return r.clientRequestId.trim();
    }
    return `local-pomo-${r.id}-${r.taskId}-${r.startAt}-${r.duration}`;
  }

  private parseJsonArray(value: string): string[] {
    if (value === null || value === undefined || value.length === 0) {
      return [];
    }
    try {
      const parsed: Object = JSON.parse(value) as Object;
      if (Array.isArray(parsed)) {
        return parsed.map((item: Object) => `${item}`);
      }
      return [];
    } catch (err) {
      return [];
    }
  }

  private async request(url: string, options: http.HttpRequestOptions): Promise<http.HttpResponse> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const requestOptions: http.HttpRequestOptions = {
        method: options.method,
        extraData: options.extraData,
        expectDataType: http.HttpDataType.STRING,
        usingProtocol: http.HttpProtocol.HTTP1_1,
        usingProxy: false,
        usingCache: false,
        connectTimeout: options.connectTimeout,
        readTimeout: options.readTimeout,
        header: options.header
      };
      return await request.request(url, requestOptions);
    } finally {
      request.destroy();
    }
  }

  private parseServerResult<T>(raw: Object | string | ArrayBuffer): ServerResult<T> {
    const text: string = `${raw}`;
    try {
      return JSON.parse(text) as ServerResult<T>;
    } catch (err) {
      const preview: string = text.length > 120 ? `${text.substring(0, 120)}...` : text;
      throw new Error(`Invalid JSON response: ${preview}`);
    }
  }

  private async lastServerSyncTime(): Promise<number> {
    if (this.pref === undefined) {
      return 0;
    }
    const serverTime: number = (await this.pref.get('sync.lastServerTime', 0)) as number;
    if (serverTime > 0) {
      return serverTime;
    }
    return 0;
  }

  private bundleServerTime(bundle: SyncBundle): number {
    return this.numberValue(bundle.serverTime, bundle.server_time, 0);
  }

  private formatNetworkError(err: Object): string {
    const detail: string = JSON.stringify(err);
    if (detail.length > 0 && detail !== '{}') {
      return detail;
    }
    return `${err}`;
  }

  private numberValue(primary: number | undefined, fallback: number | undefined, defaultValue: number): number {
    if (primary !== undefined && primary !== null) {
      return Number(primary);
    }
    if (fallback !== undefined && fallback !== null) {
      return Number(fallback);
    }
    return defaultValue;
  }

  private stringValue(primary: string | undefined, fallback: string | undefined, defaultValue: string): string {
    if (primary !== undefined && primary !== null) {
      return `${primary}`;
    }
    if (fallback !== undefined && fallback !== null) {
      return `${fallback}`;
    }
    return defaultValue;
  }

  private normalizeBaseUrl(value: string): string {
    const clean: string = value.trim().replace(/\/+$/, '');
    return clean.length === 0 ? DEFAULT_BASE_URL : clean;
  }
}

export const focusSyncService: FocusSyncService = new FocusSyncService();
