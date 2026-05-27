import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import http from '@ohos.net.http';
import {
  AiCoachAdvice,
  AiCoachSettings,
  FocusProject,
  FocusSettings,
  FocusTask,
  PomodoroRecord,
  TaskStatus
} from '../models/FocusModels';

interface ChatMessage {
  role: string;
  content: string;
}

interface ChatRequestPayload {
  model: string;
  messages: ChatMessage[];
  temperature: number;
  max_tokens: number;
}

interface ChatCompletionMessage {
  content?: string;
}

interface ChatCompletionChoice {
  message?: ChatCompletionMessage;
  text?: string;
}

interface ChatCompletionResponse {
  choices?: ChatCompletionChoice[];
}

const PREF_NAME: string = 'focus_ai';
const DEFAULT_ENDPOINT: string = 'https://api.openai.com/v1';
const DEFAULT_MODEL: string = 'gpt-4o-mini';

export class FocusAiCoachService {
  private pref?: preferences.Preferences;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
    } catch (err) {
      this.pref = undefined;
    }
  }

  defaultSettings(): AiCoachSettings {
    return {
      enabled: false,
      endpoint: DEFAULT_ENDPOINT,
      model: DEFAULT_MODEL,
      apiKey: ''
    };
  }

  async loadSettings(): Promise<AiCoachSettings> {
    if (this.pref === undefined) {
      return this.defaultSettings();
    }
    try {
      return {
        enabled: (await this.pref.get('ai.enabled', false)) as boolean,
        endpoint: (await this.pref.get('ai.endpoint', DEFAULT_ENDPOINT)) as string,
        model: (await this.pref.get('ai.model', DEFAULT_MODEL)) as string,
        apiKey: (await this.pref.get('ai.apiKey', '')) as string
      };
    } catch (err) {
      return this.defaultSettings();
    }
  }

  async saveSettings(settings: AiCoachSettings): Promise<AiCoachSettings> {
    const normalized: AiCoachSettings = {
      enabled: settings.enabled,
      endpoint: this.cleanOrDefault(settings.endpoint, DEFAULT_ENDPOINT),
      model: this.cleanOrDefault(settings.model, DEFAULT_MODEL),
      apiKey: settings.apiKey.trim()
    };
    if (this.pref === undefined) {
      return normalized;
    }
    try {
      await this.pref.put('ai.enabled', normalized.enabled);
      await this.pref.put('ai.endpoint', normalized.endpoint);
      await this.pref.put('ai.model', normalized.model);
      await this.pref.put('ai.apiKey', normalized.apiKey);
      await this.pref.flush();
    } catch (err) {
      return normalized;
    }
    return normalized;
  }

  generateLocalAdvice(
    tasks: FocusTask[],
    projects: FocusProject[],
    records: PomodoroRecord[],
    settings: FocusSettings,
    selectedTaskId: number
  ): AiCoachAdvice {
    const nextTask: FocusTask = this.pickNextTask(tasks, selectedTaskId);
    const completed: number = records.filter((record: PomodoroRecord) => record.completed === 1).length;
    const interrupted: number = records.filter((record: PomodoroRecord) => record.completed === 0).length;
    const recentInterruptions: number = this.recentInterruptions(records);
    const project: FocusProject = this.findProject(projects, nextTask.projectId);
    const minutes: number = this.estimateMinutes(nextTask, settings, recentInterruptions);
    const subtask: string = nextTask.subtasks.length > 0 ? nextTask.subtasks[0] : '先写下可验收的小结果';
    const risk: string = recentInterruptions > 0
      ? `近 7 天有 ${recentInterruptions} 次中断，开始前先关掉消息入口。`
      : '最近中断压力较低，可以直接进入一段完整番茄。';

    return {
      source: '本地规则',
      headline: `建议先推进「${nextTask.title}」`,
      nextAction: `下一步：${subtask}`,
      sessionPlan: `${project.name} · ${minutes} 分钟专注 + ${settings.shortBreakMinutes} 分钟短休`,
      risk: `${risk} 已完成 ${completed} 个番茄，中断 ${interrupted} 次。`,
      estimatedMinutes: minutes,
      confidence: recentInterruptions > 0 ? 72 : 82,
      generatedAt: Date.now()
    };
  }

  async requestAdvice(
    settings: AiCoachSettings,
    tasks: FocusTask[],
    projects: FocusProject[],
    records: PomodoroRecord[],
    focusSettings: FocusSettings,
    selectedTaskId: number
  ): Promise<AiCoachAdvice> {
    const fallback: AiCoachAdvice = this.generateLocalAdvice(tasks, projects, records, focusSettings, selectedTaskId);
    if (!settings.enabled || settings.apiKey.trim().length === 0) {
      return fallback;
    }

    const request: http.HttpRequest = http.createHttp();
    try {
      const payload: ChatRequestPayload = {
        model: this.cleanOrDefault(settings.model, DEFAULT_MODEL),
        messages: [
          {
            role: 'system',
            content: '你是 Focus App 的学习教练。只给简洁、可执行、适合大学生学习场景的中文建议。'
          },
          {
            role: 'user',
            content: this.buildPrompt(tasks, projects, records, focusSettings, selectedTaskId)
          }
        ],
        temperature: 0.4,
        max_tokens: 220
      };
      const response: http.HttpResponse = await request.request(this.chatCompletionsUrl(settings.endpoint), {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 12000,
        readTimeout: 24000,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${settings.apiKey.trim()}`
        },
        extraData: JSON.stringify(payload)
      });
      const responseCode: number = Number(response.responseCode);
      if (responseCode < 200 || responseCode >= 300) {
        return this.withFallbackStatus(fallback, `远程 AI 返回 ${responseCode}，已使用本地建议`);
      }
      const content: string = this.extractContent(`${response.result}`);
      if (content.length === 0) {
        return this.withFallbackStatus(fallback, '远程 AI 返回为空，已使用本地建议');
      }
      return this.parseRemoteAdvice(content, fallback);
    } catch (err) {
      return this.withFallbackStatus(fallback, '远程 AI 暂不可用，已使用本地建议');
    } finally {
      request.destroy();
    }
  }

  private pickNextTask(tasks: FocusTask[], selectedTaskId: number): FocusTask {
    const selected: FocusTask | undefined = tasks.find((task: FocusTask) => {
      return task.id === selectedTaskId && task.status === TaskStatus.TODO;
    });
    if (selected !== undefined) {
      return selected;
    }
    const candidates: FocusTask[] = tasks
      .filter((task: FocusTask) => task.status === TaskStatus.TODO)
      .sort((left: FocusTask, right: FocusTask) => {
        if (left.priority !== right.priority) {
          return left.priority - right.priority;
        }
        return left.dueAt - right.dueAt;
      });
    if (candidates.length > 0) {
      return candidates[0];
    }
    if (tasks.length > 0) {
      return tasks[0];
    }
    const now: number = Date.now();
    return {
      id: 0,
      title: '添加一个学习任务',
      note: '',
      projectId: 0,
      priority: 2,
      dueAt: now,
      status: TaskStatus.TODO,
      pomodoroCount: 0,
      createdAt: now,
      completedAt: 0,
      tags: [],
      subtasks: ['写下一个 25 分钟内能完成的小任务']
    };
  }

  private findProject(projects: FocusProject[], projectId: number): FocusProject {
    const found: FocusProject | undefined = projects.find((project: FocusProject) => project.id === projectId);
    if (found !== undefined) {
      return found;
    }
    if (projects.length > 0) {
      return projects[0];
    }
    return {
      id: 0,
      name: '默认项目',
      color: '#4258C9',
      icon: 'P'
    };
  }

  private estimateMinutes(task: FocusTask, settings: FocusSettings, recentInterruptions: number): number {
    const hoursLeft: number = Math.ceil((task.dueAt - Date.now()) / (60 * 60 * 1000));
    if (recentInterruptions >= 2) {
      return Math.max(15, settings.focusMinutes - 5);
    }
    if (task.priority === 0 || hoursLeft <= 6) {
      return Math.min(45, settings.focusMinutes + 10);
    }
    return settings.focusMinutes;
  }

  private recentInterruptions(records: PomodoroRecord[]): number {
    const weekAgo: number = Date.now() - 7 * 24 * 60 * 60 * 1000;
    return records.filter((record: PomodoroRecord) => {
      return record.completed === 0 && record.startAt >= weekAgo;
    }).length;
  }

  private buildPrompt(
    tasks: FocusTask[],
    projects: FocusProject[],
    records: PomodoroRecord[],
    settings: FocusSettings,
    selectedTaskId: number
  ): string {
    const nextTask: FocusTask = this.pickNextTask(tasks, selectedTaskId);
    const project: FocusProject = this.findProject(projects, nextTask.projectId);
    const todoCount: number = tasks.filter((task: FocusTask) => task.status === TaskStatus.TODO).length;
    const doneCount: number = tasks.filter((task: FocusTask) => task.status === TaskStatus.DONE).length;
    const totalMinutes: number = Math.round(records
      .filter((record: PomodoroRecord) => record.completed === 1)
      .reduce((sum: number, record: PomodoroRecord) => sum + record.duration, 0) / 60);
    const interruptions: number = records.filter((record: PomodoroRecord) => record.completed === 0).length;

    return [
      '请根据以下 Focus App 本地数据生成学习建议。',
      `当前任务：${nextTask.title}`,
      `项目：${project.name}`,
      `优先级：${nextTask.priority}`,
      `子任务：${nextTask.subtasks.join(' / ')}`,
      `待办：${todoCount}，完成：${doneCount}`,
      `累计专注分钟：${totalMinutes}，中断次数：${interruptions}`,
      `默认节奏：${settings.focusMinutes} 分钟专注，${settings.shortBreakMinutes} 分钟短休`,
      '只返回四行，格式严格如下：',
      '标题: ...',
      '下一步: ...',
      '安排: ...',
      '风险: ...'
    ].join('\n');
  }

  private parseRemoteAdvice(content: string, fallback: AiCoachAdvice): AiCoachAdvice {
    const headline: string = this.pickLine(content, '标题', fallback.headline);
    const nextAction: string = this.pickLine(content, '下一步', fallback.nextAction);
    const sessionPlan: string = this.pickLine(content, '安排', fallback.sessionPlan);
    const risk: string = this.pickLine(content, '风险', fallback.risk);
    return {
      source: '远程 AI',
      headline: headline,
      nextAction: nextAction,
      sessionPlan: sessionPlan,
      risk: risk,
      estimatedMinutes: fallback.estimatedMinutes,
      confidence: 88,
      generatedAt: Date.now()
    };
  }

  private pickLine(content: string, key: string, fallback: string): string {
    const lines: string[] = content.split('\n').map((line: string) => line.trim());
    const prefix: string = `${key}:`;
    const matched: string | undefined = lines.find((line: string) => line.indexOf(prefix) === 0);
    if (matched === undefined) {
      return fallback;
    }
    const value: string = matched.substring(prefix.length).trim();
    return value.length === 0 ? fallback : value;
  }

  private extractContent(raw: string): string {
    try {
      const parsed: ChatCompletionResponse = JSON.parse(raw) as ChatCompletionResponse;
      if (parsed.choices !== undefined && parsed.choices.length > 0) {
        const first: ChatCompletionChoice = parsed.choices[0];
        if (first.message !== undefined && first.message.content !== undefined) {
          return first.message.content.trim();
        }
        if (first.text !== undefined) {
          return first.text.trim();
        }
      }
      return '';
    } catch (err) {
      return raw.trim();
    }
  }

  private chatCompletionsUrl(endpoint: string): string {
    const clean: string = this.cleanOrDefault(endpoint, DEFAULT_ENDPOINT).replace(/\/+$/, '');
    if (clean.endsWith('/v1')) {
      return `${clean}/chat/completions`;
    }
    return `${clean}/v1/chat/completions`;
  }

  private cleanOrDefault(value: string, fallback: string): string {
    const cleaned: string = value.trim();
    return cleaned.length === 0 ? fallback : cleaned;
  }

  private withFallbackStatus(fallback: AiCoachAdvice, message: string): AiCoachAdvice {
    return {
      source: message,
      headline: fallback.headline,
      nextAction: fallback.nextAction,
      sessionPlan: fallback.sessionPlan,
      risk: fallback.risk,
      estimatedMinutes: fallback.estimatedMinutes,
      confidence: fallback.confidence,
      generatedAt: Date.now()
    };
  }
}

export const focusAiCoachService: FocusAiCoachService = new FocusAiCoachService();
