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
  ResourceInsight,
  StudyResource,
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
  max_tokens?: number;
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
const DEFAULT_ENDPOINT: string = 'https://token-plan-cn.xiaomimimo.com/v1';
const DEFAULT_MODEL: string = 'mimo-v2.5';

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
      let model: string = (await this.pref.get('ai.model', DEFAULT_MODEL)) as string;
      if (model === 'mimo-v2.5-pro') {
        model = 'mimo-v2.5';
        await this.pref.put('ai.model', model);
      }
      return {
        enabled: (await this.pref.get('ai.enabled', false)) as boolean,
        endpoint: (await this.pref.get('ai.endpoint', DEFAULT_ENDPOINT)) as string,
        model: model,
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

  async requestAdvice(
    settings: AiCoachSettings,
    tasks: FocusTask[],
    projects: FocusProject[],
    records: PomodoroRecord[],
    focusSettings: FocusSettings,
    selectedTaskId: number
  ): Promise<AiCoachAdvice> {
    if (!settings.enabled || settings.apiKey.trim().length === 0) {
      return this.remoteAdviceStatus('请先在 AI 设置中启用远程模型并填写 API Key');
    }

    const request: http.HttpRequest = http.createHttp();
    try {
      const payload: ChatRequestPayload = {
        model: this.cleanOrDefault(settings.model, DEFAULT_MODEL),
        messages: [
          {
            role: 'system',
            content: '你是知序 App 的学习教练。只给简洁、可执行、适合大学生学习场景的中文建议。'
          },
          {
            role: 'user',
            content: this.buildPrompt(tasks, projects, records, focusSettings, selectedTaskId)
          }
        ],
        temperature: 0.4
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
        return this.remoteAdviceStatus(`远程 AI 返回 ${responseCode}，请检查服务配置`);
      }
      const content: string = this.extractContent(`${response.result}`);
      if (content.length === 0) {
        return this.remoteAdviceStatus('远程 AI 返回为空，请稍后重试');
      }
      return this.parseRemoteAdvice(content);
    } catch (err) {
      return this.remoteAdviceStatus('远程 AI 请求失败，请检查接口地址或服务状态');
    } finally {
      request.destroy();
    }
  }

  async requestResourceInsight(settings: AiCoachSettings, resource: StudyResource): Promise<ResourceInsight> {
    if (!settings.enabled || settings.apiKey.trim().length === 0) {
      return this.remoteResourceStatus('请先在 AI 设置中启用远程模型并填写 API Key', resource);
    }

    const request: http.HttpRequest = http.createHttp();
    try {
      const url: string = this.chatCompletionsUrl(settings.endpoint);
      const payload: ChatRequestPayload = {
        model: this.cleanOrDefault(settings.model, DEFAULT_MODEL),
        messages: [
          {
            role: 'system',
            content: '你是知序 App 的学习资料整理助手。只输出简洁中文，帮助大学生把资料转成下一步行动。'
          },
          {
            role: 'user',
            content: this.buildResourcePrompt(resource)
          }
        ],
        temperature: 0.35
      };
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 12000,
        readTimeout: 30000,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${settings.apiKey.trim()}`
        },
        extraData: JSON.stringify(payload)
      });
      const responseCode: number = Number(response.responseCode);
      if (responseCode < 200 || responseCode >= 300) {
        return this.remoteResourceStatus(`远程 AI 返回 ${responseCode}，请检查服务配置`, resource);
      }
      const content: string = this.extractContent(`${response.result}`);
      if (content.length === 0) {
        return this.remoteResourceStatus('远程 AI 返回为空，请稍后重试', resource);
      }
      return this.parseRemoteResourceInsight(content, resource);
    } catch (err) {
      return this.remoteResourceStatus('远程 AI 请求失败，请检查接口地址或服务状态', resource);
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
      '请根据以下知序 App 本地数据生成学习建议。',
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

  private buildResourcePrompt(resource: StudyResource): string {
    const content: string = resource.content.length > 1100 ? `${resource.content.substring(0, 1100)}...` : resource.content;
    return [
      '请把这份学习资料提炼成摘要、要点和一个可执行任务。',
      `标题：${resource.title}`,
      `类型：${resource.sourceType}`,
      `内容：${content}`,
      '只返回四行，格式严格如下：',
      '摘要: ...',
      '要点: 要点一 / 要点二 / 要点三',
      '任务: ...',
      '分钟: 25'
    ].join('\n');
  }

  private parseRemoteAdvice(content: string): AiCoachAdvice {
    const headline: string = this.pickLine(content, '标题', '远程 AI 已返回学习建议');
    const nextAction: string = this.pickLine(content, '下一步', '查看建议内容并选择下一段任务');
    const sessionPlan: string = this.pickLine(content, '安排', '按远程 AI 建议安排下一段专注');
    const risk: string = this.pickLine(content, '风险', '开始前确认资料、任务和时间安排');
    return {
      source: '远程 AI',
      headline: headline,
      nextAction: nextAction,
      sessionPlan: sessionPlan,
      risk: risk,
      estimatedMinutes: this.parseMinutes(this.pickLine(content, '分钟', '25'), 25),
      confidence: 88,
      generatedAt: Date.now()
    };
  }

  private parseRemoteResourceInsight(content: string, resource: StudyResource): ResourceInsight {
    const summary: string = this.pickLine(content, '摘要', '远程 AI 已完成资料摘要，请查看原文确认。');
    const keyPointLine: string = this.pickLine(content, '要点', '查看原文 / 整理关键概念 / 形成复习任务');
    const nextTaskTitle: string = this.pickLine(content, '任务', `整理「${resource.title}」学习任务`);
    return {
      source: '远程 AI',
      summary: summary,
      keyPoints: this.parseKeyPointLine(keyPointLine),
      nextTaskTitle: nextTaskTitle,
      estimatedMinutes: this.parseMinutes(this.pickLine(content, '分钟', '25'), 25),
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
      return '';
    }
  }

  private parseKeyPointLine(line: string): string[] {
    const normalized: string = line.replace(/，/g, '/').replace(/、/g, '/').replace(/;/g, '/').replace(/；/g, '/');
    const points: string[] = normalized
      .split('/')
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0)
      .slice(0, 3);
    return points.length > 0 ? points : ['查看原文', '整理关键概念', '形成复习任务'];
  }

  private parseMinutes(value: string, fallback: number): number {
    const parsedMinutes: number = Number(value.replace('分钟', '').trim());
    return parsedMinutes !== parsedMinutes ? fallback : Math.max(15, Math.min(60, Math.round(parsedMinutes)));
  }

  private chatCompletionsUrl(endpoint: string): string {
    const clean: string = this.cleanOrDefault(endpoint, DEFAULT_ENDPOINT).replace(/\/+$/, '');
    if (clean.endsWith('/chat/completions')) {
      return clean;
    }
    if (clean.endsWith('/v1')) {
      return `${clean}/chat/completions`;
    }
    return `${clean}/v1/chat/completions`;
  }

  private cleanOrDefault(value: string, fallback: string): string {
    const cleaned: string = value.trim();
    return cleaned.length === 0 ? fallback : cleaned;
  }

  private remoteAdviceStatus(message: string): AiCoachAdvice {
    return {
      source: message,
      headline: message,
      nextAction: '打开 AI 设置，确认 endpoint、model 和 API Key 后再刷新。',
      sessionPlan: '远程 AI 未返回建议',
      risk: '当前不生成替代建议，请配置远程 AI 后使用。',
      estimatedMinutes: 0,
      confidence: 0,
      generatedAt: Date.now()
    };
  }

  private remoteResourceStatus(message: string, resource: StudyResource): ResourceInsight {
    return {
      source: message,
      summary: message,
      keyPoints: ['配置远程 AI', '确认接口可用', '重新提炼资料'],
      nextTaskTitle: `提炼「${resource.title}」`,
      estimatedMinutes: 25,
      generatedAt: Date.now()
    };
  }
}

export const focusAiCoachService: FocusAiCoachService = new FocusAiCoachService();
