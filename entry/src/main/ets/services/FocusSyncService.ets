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
  projects: ServerProject[];
  tasks: ServerTask[];
  pomodoros: ServerPomodoro[];
}

// 后端实体(字段名与后端 snake_case 一致,Jackson 自动转换)
interface ServerProject {
  id: number;
  userId: number;
  name: string;
  color: string;
  icon: string;
  updatedAt: number;
  isDeleted: number;
}

interface ServerTask {
  id: number;
  userId: number;
  title: string;
  note: string;
  projectId: number;
  priority: number;
  dueAt: number;
  status: number;
  pomodoroCount: number;
  createdAt: number;
  updatedAt: number;
  completedAt: number;
  isDeleted: number;
  clientRequestId: string;
  tagsJson: string;
  subtasksJson: string;
}

interface ServerPomodoro {
  id: number;
  userId: number;
  taskId: number;
  startAt: number;
  duration: number;
  completed: number;
  interruptReason: string;
  updatedAt: number;
  clientRequestId: string;
}

interface SyncPushRequest {
  projects: ServerProject[];
  tasks: ServerTask[];
  pomodoros: ServerPomodoro[];
}

interface AuthResponse {
  userId: number;
  username: string;
  nickname: string;
  token: string;
}

interface SyncActionResult {
  success: boolean;
  message: string;
}

interface SyncPullResult {
  success: boolean;
  message: string;
  bundle?: SyncBundle;
}

const PREF_NAME: string = 'focus_sync';
const DEFAULT_BASE_URL: string = 'http://localhost:8080';

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

  isLoggedIn(): boolean {
    return this.userId > 0 && this.token.length > 0;
  }

  async login(username: string, password: string): Promise<SyncActionResult> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(`${this.baseUrl}/api/user/login`, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 15000,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ username: username, password: password })
      });
      const code: number = Number(response.responseCode);
      if (code < 200 || code >= 300) {
        return { success: false, message: `服务器返回 ${code}` };
      }
      const result: ServerResult<AuthResponse> = JSON.parse(`${response.result}`) as ServerResult<AuthResponse>;
      if (result.code !== 200 || result.data === null) {
        return { success: false, message: result.msg || '登录失败' };
      }
      this.userId = result.data.userId;
      this.token = result.data.token;
      if (this.pref !== undefined) {
        await this.pref.put('sync.userId', this.userId);
        await this.pref.put('sync.token', this.token);
        await this.pref.put('sync.username', result.data.username);
        await this.pref.put('sync.nickname', result.data.nickname);
        await this.pref.flush();
      }
      return { success: true, message: `欢迎，${result.data.nickname}` };
    } catch (err) {
      return { success: false, message: `网络错误：${JSON.stringify(err)}` };
    } finally {
      request.destroy();
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
    const request: http.HttpRequest = http.createHttp();
    try {
      const url: string = `${this.baseUrl}/api/sync/pull?since=${since}`;
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 20000,
        header: {
          'Content-Type': 'application/json',
          'X-User-Id': `${this.userId}`
        }
      });
      const code: number = Number(response.responseCode);
      if (code < 200 || code >= 300) {
        return { success: false, message: `服务器返回 ${code}` };
      }
      const result: ServerResult<SyncBundle> = JSON.parse(`${response.result}`) as ServerResult<SyncBundle>;
      if (result.code !== 200 || result.data === null) {
        return { success: false, message: result.msg || 'pull 失败' };
      }
      return { success: true, message: 'pull 成功', bundle: result.data };
    } catch (err) {
      return { success: false, message: `网络错误：${JSON.stringify(err)}` };
    } finally {
      request.destroy();
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
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(`${this.baseUrl}/api/sync/push`, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 25000,
        header: {
          'Content-Type': 'application/json',
          'X-User-Id': `${this.userId}`
        },
        extraData: JSON.stringify(payload)
      });
      const code: number = Number(response.responseCode);
      if (code < 200 || code >= 300) {
        return { success: false, message: `服务器返回 ${code}` };
      }
      const result: ServerResult<SyncBundle> = JSON.parse(`${response.result}`) as ServerResult<SyncBundle>;
      if (result.code !== 200) {
        return { success: false, message: result.msg || 'push 失败' };
      }
      return { success: true, message: 'push 成功' };
    } catch (err) {
      return { success: false, message: `网络错误：${JSON.stringify(err)}` };
    } finally {
      request.destroy();
    }
  }

  async syncBidirectional(): Promise<SyncActionResult> {
    const lastSync: number = this.pref !== undefined ? (await this.pref.get('sync.lastSyncTime', 0)) as number : 0;
    const pullResult = await this.pullFromServer(lastSync);
    if (!pullResult.success || pullResult.bundle === undefined) {
      return { success: false, message: `下拉失败：${pullResult.message}` };
    }
    await this.mergeServerData(pullResult.bundle);
    const localProjects: FocusProject[] = await focusDatabase.getProjects();
    const localTasks: FocusTask[] = await focusDatabase.getTasks();
    const localPomodoros: PomodoroRecord[] = await focusDatabase.getPomodoros();
    const pushResult = await this.pushToServer(localProjects, localTasks, localPomodoros);
    if (!pushResult.success) {
      return { success: false, message: `上推失败：${pushResult.message}` };
    }
    if (this.pref !== undefined) {
      await this.pref.put('sync.lastSyncTime', Date.now());
      await this.pref.flush();
    }
    return { success: true, message: '同步完成' };
  }

  private async mergeServerData(bundle: SyncBundle): Promise<void> {
    for (const sp of bundle.projects) {
      const local: FocusProject = {
        id: sp.id,
        name: sp.name,
        color: sp.color,
        icon: sp.icon
      };
      await focusDatabase.upsertProject(local);
    }
    for (const st of bundle.tasks) {
      const local: FocusTask = {
        id: st.id,
        title: st.title,
        note: st.note,
        projectId: st.projectId,
        priority: st.priority,
        dueAt: st.dueAt,
        status: st.status,
        pomodoroCount: st.pomodoroCount,
        createdAt: st.createdAt,
        completedAt: st.completedAt,
        tags: this.parseJsonArray(st.tagsJson),
        subtasks: this.parseJsonArray(st.subtasksJson)
      };
      await focusDatabase.upsertTask(local);
    }
    for (const sr of bundle.pomodoros) {
      const local: PomodoroRecord = {
        id: sr.id,
        taskId: sr.taskId,
        startAt: sr.startAt,
        duration: sr.duration,
        completed: sr.completed,
        interruptReason: sr.interruptReason
      };
      await focusDatabase.recordPomodoro(local);
    }
  }

  private toServerProject(p: FocusProject): ServerProject {
    return {
      id: p.id,
      userId: this.userId,
      name: p.name,
      color: p.color,
      icon: p.icon,
      updatedAt: Date.now(),
      isDeleted: 0
    };
  }

  private toServerTask(t: FocusTask): ServerTask {
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
      updatedAt: Date.now(),
      completedAt: t.completedAt,
      isDeleted: 0,
      clientRequestId: `client-${t.id}-${Date.now()}`,
      tagsJson: JSON.stringify(t.tags),
      subtasksJson: JSON.stringify(t.subtasks)
    };
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
      updatedAt: Date.now(),
      clientRequestId: `client-pomo-${r.id}-${r.startAt}`
    };
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
}

export const focusSyncService: FocusSyncService = new FocusSyncService();
