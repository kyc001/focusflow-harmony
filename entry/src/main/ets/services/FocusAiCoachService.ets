import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import http from '@ohos.net.http';
import util from '@ohos.util';
import {
  AiCoachAdvice,
  AiCoachSettings,
  FocusProject,
  FocusSettings,
  FocusTask,
  ImageTaskExtractionResult,
  PomodoroRecord,
  QuickTaskDraft,
  ResourceInsight,
  StudyResource,
  TaskStatus
} from '../models/FocusModels';

interface ChatContentPart {
  type: string;
  text?: string;
  image_url?: ImageUrlContent;
}

interface ImageUrlContent {
  url: string;
  detail?: string;
}

interface ChatMessage {
  role: string;
  content: string | ChatContentPart[];
}

interface ChatRequestPayload {
  model: string;
  messages: ChatMessage[];
  temperature: number;
  max_tokens?: number;
  response_format?: ResponseFormat;
}

interface ResponseFormat {
  type: string;
}

interface ChatCompletionMessage {
  content?: string | ChatContentPart[];
  reasoning_content?: string;
}

interface ChatCompletionChoice {
  message?: ChatCompletionMessage;
  text?: string;
  finish_reason?: string;
}

interface ChatCompletionResponse {
  choices?: ChatCompletionChoice[];
}

interface AiEnvConfig {
  endpoint?: string;
  model?: string;
  apiKey?: string;
}

interface ImageTaskJsonDraft {
  title?: string;
  note?: string;
  description?: string;
  priority?: string | number;
  dueAt?: string | number;
  deadline?: string;
  dueOffsetHours?: string | number;
  subtasks?: string[] | string;
  tags?: string[] | string;
}

interface ImageTaskJsonResult extends ImageTaskJsonDraft {
  tasks?: ImageTaskJsonDraft[];
}

const PREF_NAME: string = 'focus_ai';
const DEFAULT_ENDPOINT: string = '';
const DEFAULT_MODEL: string = '';
const DEFAULT_API_KEY: string = '';

export class FocusAiCoachService {
  private pref?: preferences.Preferences;
  private envDefaults: AiCoachSettings = {
    enabled: true,
    endpoint: DEFAULT_ENDPOINT,
    model: DEFAULT_MODEL,
    apiKey: DEFAULT_API_KEY
  };

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
    } catch (err) {
      this.pref = undefined;
    }
    this.envDefaults = this.loadEnvDefaults(context);
  }

  defaultSettings(): AiCoachSettings {
    return {
      enabled: true,
      endpoint: this.envDefaults.endpoint,
      model: this.envDefaults.model,
      apiKey: this.envDefaults.apiKey
    };
  }

  async loadSettings(): Promise<AiCoachSettings> {
    if (this.pref === undefined) {
      return this.defaultSettings();
    }
    try {
      let endpoint: string = (await this.pref.get('ai.endpoint', this.envDefaults.endpoint)) as string;
      let model: string = (await this.pref.get('ai.model', this.envDefaults.model)) as string;
      let apiKey: string = (await this.pref.get('ai.apiKey', this.envDefaults.apiKey)) as string;
      endpoint = this.envDefaults.endpoint.length > 0 ? this.envDefaults.endpoint : endpoint;
      model = this.envDefaults.model.length > 0 ? this.envDefaults.model : model;
      apiKey = this.envDefaults.apiKey.length > 0 ? this.envDefaults.apiKey : apiKey;
      return {
        enabled: (await this.pref.get('ai.enabled', true)) as boolean,
        endpoint: endpoint,
        model: model,
        apiKey: apiKey
      };
    } catch (err) {
      return this.defaultSettings();
    }
  }

  async saveSettings(settings: AiCoachSettings): Promise<AiCoachSettings> {
    const normalized: AiCoachSettings = {
      enabled: settings.enabled,
      endpoint: this.cleanOrDefault(settings.endpoint, this.envDefaults.endpoint),
      model: this.cleanOrDefault(settings.model, this.envDefaults.model),
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
        model: this.cleanOrDefault(settings.model, this.envDefaults.model),
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

  async requestTaskFromImage(settings: AiCoachSettings, imageBase64: string, mimeType: string): Promise<ImageTaskExtractionResult> {
    if (!settings.enabled || settings.apiKey.trim().length === 0) {
      return this.imageTaskStatus('请先在 AI 设置中启用远程模型并填写 API Key');
    }

    const tokenBudgets: number[] = [1800, 3200];
    let lastStatus: string = '远程 AI 返回为空，请稍后重试';
    for (let index: number = 0; index < tokenBudgets.length; index++) {
      const request: http.HttpRequest = http.createHttp();
      try {
      const payload: ChatRequestPayload = {
        model: this.visualTaskModel(settings),
        messages: [
          {
            role: 'system',
            content: '你是知序 App 的任务录入助手。不要解释，不要展开推理，直接输出最终任务字段。'
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: [
                  '请从图片中提取所有明确、可执行的学习任务。',
                  '如果图片是任务列表、课程通知、聊天截图或应用截图，请把多个作业/实验/报告/复习事项拆成多个对象，不要合并。',
                  '只返回 JSON，不要返回 Markdown，不要解释。格式必须是：',
                  '{"tasks":[{"title":"...","note":"...","priority":1,"dueOffsetHours":8,"deadline":"","subtasks":["..."],"tags":["图片提取","课程"]}]}',
                  'priority 只能是 0 到 3；deadline 尽量使用 yyyy-MM-dd HH:mm；无法确定 deadline 时使用 dueOffsetHours。',
                  '没有依据的字段留空，不要编造；最多返回 5 条任务。'
                ].join('\n')
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`,
                  detail: 'high'
                }
              }
            ]
          }
        ],
        temperature: 0.2,
        max_tokens: tokenBudgets[index]
      };
      const response: http.HttpResponse = await this.requestWithTimeout(request, this.chatCompletionsUrl(settings.endpoint), {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${settings.apiKey.trim()}`
        },
        extraData: JSON.stringify(payload)
      }, 35000);
      const responseCode: number = Number(response.responseCode);
      if (responseCode < 200 || responseCode >= 300) {
        return this.imageTaskStatus(`远程 AI 返回 ${responseCode}，请检查服务配置`);
      }
      const rawResponse: string = `${response.result}`;
      const content: string = this.extractContent(rawResponse);
      if (content.length === 0) {
        lastStatus = `远程 AI 返回为空（响应 ${rawResponse.length} 字符），已自动重试；仍为空时请换图或稍后再试`;
        continue;
      }
      const drafts: QuickTaskDraft[] = this.parseRemoteImageTasks(content);
      if (drafts.length === 0) {
        lastStatus = `远程 AI 返回了 ${content.length} 字符，但没有解析出任务`;
        continue;
      }
      return {
        drafts: drafts,
        message: `识别到 ${drafts.length} 条候选任务，请确认后保存`,
        rawContent: this.previewText(content, 240),
        source: 'image'
      };
    } catch (err) {
      lastStatus = `图片已上传，但远程 AI 未返回任务：${err instanceof Error ? err.message : '请检查接口地址、模型能力或网络状态'}`;
    } finally {
      request.destroy();
    }
    }
    return this.imageTaskStatus(lastStatus);
  }

  async requestTaskFromText(settings: AiCoachSettings, ocrText: string): Promise<ImageTaskExtractionResult> {
    const cleanText: string = ocrText.trim();
    if (cleanText.length === 0) {
      return this.imageTaskStatus('OCR 文本为空，无法解析任务');
    }
    const fallbackDrafts: QuickTaskDraft[] = this.parseImageTasksFromText(cleanText);
    if (!settings.enabled || settings.apiKey.trim().length === 0) {
      return fallbackDrafts.length > 0 ? {
        drafts: fallbackDrafts,
        message: `OCR 已识别文字，远程 AI 未配置，已生成 ${fallbackDrafts.length} 条待确认草稿`,
        rawContent: this.previewText(cleanText, 240),
        source: 'text'
      } : this.imageTaskStatus('OCR 已识别文字，但远程 AI 未配置且本地规则未解析出任务');
    }

    const request: http.HttpRequest = http.createHttp();
    try {
      const payload: ChatRequestPayload = {
        model: this.visualTaskModel(settings),
        messages: [
          {
            role: 'system',
            content: '你是知序 App 的 OCR 任务解析助手。只返回 JSON，不要返回 Markdown，也不要解释。'
          },
          {
            role: 'user',
            content: [
              '请从以下 OCR 文本中提取所有明确、可执行的学习任务。',
              '若有多个作业、实验、报告、复习事项或课程通知，请逐条放入 tasks 数组。',
              'JSON 格式必须是：{"tasks":[{"title":"...","note":"...","priority":1,"dueOffsetHours":8,"deadline":"","subtasks":["..."],"tags":["OCR","课程"]}]}',
              'priority 只能是 0 到 3；deadline 尽量使用 yyyy-MM-dd HH:mm；没有依据的字段留空，不要编造；最多返回 5 条任务。',
              '',
              cleanText
            ].join('\n')
          }
        ],
        temperature: 0.15,
        max_tokens: 2200,
        response_format: { type: 'json_object' }
      };
      const response: http.HttpResponse = await this.requestWithTimeout(request, this.chatCompletionsUrl(settings.endpoint), {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${settings.apiKey.trim()}`
        },
        extraData: JSON.stringify(payload)
      }, 35000);
      const responseCode: number = Number(response.responseCode);
      if (responseCode < 200 || responseCode >= 300) {
        return fallbackDrafts.length > 0 ? {
          drafts: fallbackDrafts,
          message: `远程 AI 返回 ${responseCode}，已使用 OCR 文本生成 ${fallbackDrafts.length} 条待确认草稿`,
          rawContent: this.previewText(cleanText, 240),
          source: 'text'
        } : this.imageTaskStatus(`远程 AI 返回 ${responseCode}，请检查服务配置`);
      }
      const rawResponse: string = `${response.result}`;
      const content: string = this.extractContent(rawResponse);
      if (content.length === 0) {
        return fallbackDrafts.length > 0 ? {
          drafts: fallbackDrafts,
          message: `远程 AI 返回为空（响应 ${rawResponse.length} 字符），已使用 OCR 文本生成 ${fallbackDrafts.length} 条待确认草稿`,
          rawContent: this.previewText(cleanText, 240),
          source: 'text'
        } : this.imageTaskStatus(`远程 AI 返回为空（响应 ${rawResponse.length} 字符），OCR 本地规则也未解析出任务`);
      }
      const drafts: QuickTaskDraft[] = this.parseRemoteImageTasks(content);
      if (drafts.length > 0) {
        return {
          drafts: drafts,
          message: `OCR + mimo-v2.5 识别到 ${drafts.length} 条候选任务，请确认后保存`,
          rawContent: this.previewText(content, 240),
          source: 'text'
        };
      }
      return fallbackDrafts.length > 0 ? {
        drafts: fallbackDrafts,
        message: `远程 AI 返回了 ${content.length} 字符但未解析出任务，已使用 OCR 文本生成 ${fallbackDrafts.length} 条待确认草稿`,
        rawContent: this.previewText(`${content}\nOCR：${cleanText}`, 240),
        source: 'text'
      } : this.imageTaskStatus(`远程 AI 返回了 ${content.length} 字符，但没有解析出任务`);
    } catch (err) {
      return fallbackDrafts.length > 0 ? {
        drafts: fallbackDrafts,
        message: `远程 AI 未返回任务：${err instanceof Error ? err.message : '请检查网络或模型能力'}；已使用 OCR 文本生成 ${fallbackDrafts.length} 条待确认草稿`,
        rawContent: this.previewText(cleanText, 240),
        source: 'text'
      } : this.imageTaskStatus(`远程 AI 未返回任务：${err instanceof Error ? err.message : '请检查网络或模型能力'}`);
    } finally {
      request.destroy();
    }
  }

  private requestWithTimeout(
    request: http.HttpRequest,
    url: string,
    options: http.HttpRequestOptions,
    timeoutMs: number
  ): Promise<http.HttpResponse> {
    return new Promise<http.HttpResponse>((resolve, reject) => {
      let settled: boolean = false;
      let timerId: number = -1;
      timerId = setTimeout(() => {
        if (settled) {
          return;
        }
        settled = true;
        request.destroy();
        reject(new Error(`远程 AI 超过 ${Math.round(timeoutMs / 1000)} 秒未返回`));
      }, timeoutMs);

      request.request(url, options)
        .then((response: http.HttpResponse) => {
          if (settled) {
            return;
          }
          settled = true;
          if (timerId >= 0) {
            clearTimeout(timerId);
          }
          resolve(response);
        })
        .catch((err: Error) => {
          if (settled) {
            return;
          }
          settled = true;
          if (timerId >= 0) {
            clearTimeout(timerId);
          }
          reject(err);
        });
    });
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

  private parseRemoteImageTasks(content: string): QuickTaskDraft[] {
    const jsonDrafts: QuickTaskDraft[] = this.parseImageTasksFromJson(content);
    if (jsonDrafts.length > 0) {
      return jsonDrafts;
    }
    const legacyDraft: QuickTaskDraft = this.parseRemoteImageTask(content);
    return legacyDraft.title.trim().length > 0 ? [legacyDraft] : [];
  }

  private parseImageTasksFromText(text: string): QuickTaskDraft[] {
    const segments: string[] = this.splitTaskTextSegments(text);
    return segments
      .map((segment: string) => this.textSegmentToQuickTask(segment, text))
      .filter((draft: QuickTaskDraft) => draft.title.trim().length > 0)
      .slice(0, 5);
  }

  private splitTaskTextSegments(text: string): string[] {
    const normalized: string = text.replace(/\r/g, '\n').replace(/[。；;]+/g, '\n');
    const lines: string[] = normalized.split('\n')
      .map((line: string) => this.cleanImageTaskLine(line).replace(/^\d+[.、)]\s*/g, '').trim())
      .filter((line: string) => line.length >= 4);
    const taskLines: string[] = lines.filter((line: string) => this.containsTaskKeyword(line));
    if (taskLines.length > 0) {
      return taskLines;
    }
    return this.containsTaskKeyword(text) ? [this.previewText(text, 160)] : [];
  }

  private textSegmentToQuickTask(segment: string, fullText: string): QuickTaskDraft {
    const clean: string = segment.replace(/\s+/g, ' ').trim();
    const title: string = this.inferTextTaskTitle(clean);
    const deadline: number | undefined = this.inferTextDeadline(clean);
    return {
      title: title,
      note: this.inferTextTaskNote(clean, fullText),
      priority: this.inferTextPriority(clean, deadline),
      dueAt: deadline,
      dueOffsetHours: deadline === undefined ? 8 : undefined,
      source: 'image-ocr',
      tags: ['OCR', this.inferTextTaskType(clean)],
      subtasks: ['核对识别文字', `完成「${title}」`, '提交或复盘结果']
    };
  }

  private containsTaskKeyword(text: string): boolean {
    return text.indexOf('作业') >= 0 ||
      text.indexOf('实验') >= 0 ||
      text.indexOf('报告') >= 0 ||
      text.indexOf('复习') >= 0 ||
      text.indexOf('考试') >= 0 ||
      text.indexOf('测验') >= 0 ||
      text.indexOf('提交') >= 0 ||
      text.indexOf('截止') >= 0 ||
      text.indexOf('任务') >= 0 ||
      text.indexOf('todo') >= 0 ||
      text.indexOf('TODO') >= 0;
  }

  private inferTextTaskTitle(segment: string): string {
    const clean: string = segment.replace(/^[-•·*]+\s*/g, '').trim();
    if (clean.length === 0) {
      return '整理图片中的学习任务';
    }
    return this.previewText(clean, 36);
  }

  private inferTextTaskNote(segment: string, fullText: string): string {
    const source: string = segment.trim().length > 0 ? segment : fullText;
    return `由 OCR 文本识别生成，请核对后执行：${this.previewText(source, 96)}`;
  }

  private inferTextTaskType(segment: string): string {
    if (segment.indexOf('实验') >= 0) {
      return '实验';
    }
    if (segment.indexOf('报告') >= 0) {
      return '报告';
    }
    if (segment.indexOf('考试') >= 0 || segment.indexOf('测验') >= 0) {
      return '考试';
    }
    if (segment.indexOf('复习') >= 0) {
      return '复习';
    }
    if (segment.indexOf('作业') >= 0) {
      return '作业';
    }
    return '课程';
  }

  private inferTextPriority(segment: string, deadline: number | undefined): number {
    if (segment.indexOf('紧急') >= 0 || segment.indexOf('今天') >= 0 || segment.indexOf('今晚') >= 0) {
      return 0;
    }
    if (deadline !== undefined && deadline - Date.now() <= 24 * 60 * 60 * 1000) {
      return 0;
    }
    if (segment.indexOf('考试') >= 0 || segment.indexOf('截止') >= 0 || segment.indexOf('提交') >= 0) {
      return 1;
    }
    return 2;
  }

  private inferTextDeadline(segment: string): number | undefined {
    const normalized: string = segment.replace(/：/g, ':').replace(/\//g, '-');
    const explicit: number | undefined = this.parseExplicitTextDeadline(normalized);
    if (explicit !== undefined) {
      return explicit;
    }
    const now: Date = new Date();
    const clock: number[] = this.parseTextClock(normalized);
    if (normalized.indexOf('今天') >= 0 || normalized.indexOf('今晚') >= 0) {
      const target: Date = new Date(now.getTime());
      target.setHours(clock[0] >= 0 ? clock[0] : 23, clock[1], 0, 0);
      return target.getTime();
    }
    if (normalized.indexOf('明天') >= 0) {
      const target: Date = new Date(now.getTime());
      target.setDate(target.getDate() + 1);
      target.setHours(clock[0] >= 0 ? clock[0] : 18, clock[1], 0, 0);
      return target.getTime();
    }
    if (normalized.indexOf('后天') >= 0) {
      const target: Date = new Date(now.getTime());
      target.setDate(target.getDate() + 2);
      target.setHours(clock[0] >= 0 ? clock[0] : 18, clock[1], 0, 0);
      return target.getTime();
    }
    return undefined;
  }

  private parseExplicitTextDeadline(text: string): number | undefined {
    const normalized: string = text.replace(' ', 'T');
    const candidates: string[] = [];
    const yearPattern: RegExp = /20\d{2}-\d{1,2}-\d{1,2}(?:[T\s]\d{1,2}:\d{1,2})?/g;
    const monthPattern: RegExp = /\d{1,2}-\d{1,2}(?:[T\s]\d{1,2}:\d{1,2})?/g;
    let matched: RegExpExecArray | null = yearPattern.exec(normalized);
    while (matched !== null) {
      candidates.push(matched[0]);
      matched = yearPattern.exec(normalized);
    }
    matched = monthPattern.exec(normalized);
    while (matched !== null) {
      candidates.push(`${new Date().getFullYear()}-${matched[0]}`);
      matched = monthPattern.exec(normalized);
    }
    for (let index: number = 0; index < candidates.length; index++) {
      const parsed: number = Date.parse(candidates[index].replace(' ', 'T'));
      if (!Number.isNaN(parsed)) {
        return parsed;
      }
    }
    return undefined;
  }

  private parseTextClock(text: string): number[] {
    const colonIndex: number = text.indexOf(':');
    if (colonIndex > 0) {
      const hourText: string = text.substring(Math.max(0, colonIndex - 2), colonIndex).replace(/[^0-9]/g, '');
      const minuteText: string = text.substring(colonIndex + 1, colonIndex + 3).replace(/[^0-9]/g, '');
      const hour: number = Number(hourText);
      const minute: number = Number(minuteText.length > 0 ? minuteText : '0');
      return [Number.isNaN(hour) ? -1 : hour, Number.isNaN(minute) ? 0 : minute];
    }
    const hourIndex: number = text.indexOf('点');
    if (hourIndex > 0) {
      const hourText: string = text.substring(Math.max(0, hourIndex - 2), hourIndex).replace(/[^0-9]/g, '');
      const minuteText: string = text.substring(hourIndex + 1, hourIndex + 3).replace(/[^0-9]/g, '');
      const hour: number = Number(hourText);
      const minute: number = Number(minuteText.length > 0 ? minuteText : '0');
      return [Number.isNaN(hour) ? -1 : hour, Number.isNaN(minute) ? 0 : minute];
    }
    return [-1, 0];
  }

  private parseImageTasksFromJson(content: string): QuickTaskDraft[] {
    const jsonText: string = this.extractJsonObject(content);
    if (jsonText.length === 0) {
      return [];
    }
    try {
      const parsed: ImageTaskJsonResult = JSON.parse(jsonText) as ImageTaskJsonResult;
      let sourceTasks: ImageTaskJsonDraft[] = [];
      if (parsed.tasks !== undefined && Array.isArray(parsed.tasks)) {
        sourceTasks = parsed.tasks;
      } else if (parsed.title !== undefined) {
        sourceTasks = [parsed];
      }
      return sourceTasks
        .map((item: ImageTaskJsonDraft) => this.imageJsonDraftToQuickTask(item))
        .filter((draft: QuickTaskDraft) => draft.title.trim().length > 0)
        .slice(0, 5);
    } catch (err) {
      return [];
    }
  }

  private imageJsonDraftToQuickTask(item: ImageTaskJsonDraft): QuickTaskDraft {
    const title: string = this.cleanImageTaskLine(item.title === undefined ? '' : `${item.title}`);
    const noteSource: string = item.note !== undefined ? `${item.note}` :
      item.description !== undefined ? `${item.description}` : '';
    const tags: string[] = this.normalizeStringArray(item.tags, '图片提取 / AI');
    if (tags.indexOf('图片提取') < 0) {
      tags.unshift('图片提取');
    }
    return {
      title: this.previewText(title, 36),
      note: noteSource.trim().length > 0 ? noteSource.trim() : '由图片识别生成，请核对后执行。',
      priority: this.parsePriority(item.priority === undefined ? '1' : `${item.priority}`),
      dueAt: this.parseImageDueAt(item.deadline !== undefined ? item.deadline : item.dueAt),
      dueOffsetHours: this.parseDueOffsetHours(item.dueOffsetHours === undefined ? '8' : `${item.dueOffsetHours}`),
      source: 'image',
      tags: tags.slice(0, 4),
      subtasks: this.normalizeStringArray(item.subtasks, `核对图片内容 / 处理「${title}」 / 完成学习输出`)
    };
  }

  private parseRemoteImageTask(content: string): QuickTaskDraft {
    const pickedTitle: string = this.pickLine(content, '标题', '');
    const title: string = pickedTitle.length > 0 ? pickedTitle : this.pickImageTaskTitle(content);
    const pickedNote: string = this.pickLine(content, '备注', '');
    const note: string = pickedNote.length > 0 ? pickedNote : `由图片识别生成：${this.previewText(content, 72)}`;
    const subtaskLine: string = this.pickLine(content, '子任务', `核对图片内容 / 处理「${title}」 / 完成学习输出`);
    const tagLine: string = this.pickLine(content, '标签', '图片提取 / AI');
    return {
      title: title,
      note: note,
      priority: this.parsePriority(this.pickLine(content, '优先级', '1')),
      dueOffsetHours: this.parseDueOffsetHours(this.pickLine(content, '截止小时', '8')),
      source: 'image',
      tags: this.parseKeyPointLine(tagLine).slice(0, 4),
      subtasks: this.parseKeyPointLine(subtaskLine)
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

  private extractJsonObject(content: string): string {
    const trimmed: string = content.trim()
      .replace(/^```json/i, '')
      .replace(/^```/i, '')
      .replace(/```$/i, '')
      .trim();
    const start: number = trimmed.indexOf('{');
    const end: number = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return '';
    }
    return trimmed.substring(start, end + 1);
  }

  private extractContent(raw: string): string {
    try {
      const parsed: ChatCompletionResponse = JSON.parse(raw) as ChatCompletionResponse;
      if (parsed.choices !== undefined && parsed.choices.length > 0) {
        const first: ChatCompletionChoice = parsed.choices[0];
        if (first.message !== undefined && first.message.content !== undefined) {
          if (typeof first.message.content === 'string') {
            return first.message.content.trim();
          }
          return first.message.content
            .map((part: ChatContentPart) => part.text === undefined ? '' : part.text)
            .join('\n')
            .trim();
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

  private pickImageTaskTitle(content: string): string {
    const tableTitle: string = this.pickMarkdownTableTitle(content);
    if (tableTitle.length > 0) {
      return tableTitle;
    }
    const lines: string[] = content.split('\n')
      .map((line: string) => this.cleanImageTaskLine(line))
      .filter((line: string) => {
        return line.length > 0 &&
          line.indexOf('标题') < 0 &&
          line.indexOf('备注') < 0 &&
          line.indexOf('优先级') < 0 &&
          line.indexOf('截止小时') < 0 &&
          line.indexOf('子任务') < 0 &&
          line.indexOf('标签') < 0;
      });
    return lines.length > 0 ? this.previewText(lines[0], 28) : '整理图片中的学习任务';
  }

  private normalizeStringArray(value: string[] | string | undefined, fallback: string): string[] {
    if (value === undefined) {
      return this.parseKeyPointLine(fallback);
    }
    if (Array.isArray(value)) {
      const items: string[] = value
        .map((item: string) => item.trim())
        .filter((item: string) => item.length > 0)
        .slice(0, 4);
      return items.length > 0 ? items : this.parseKeyPointLine(fallback);
    }
    const parsed: string[] = this.parseKeyPointLine(value);
    return parsed.length > 0 ? parsed : this.parseKeyPointLine(fallback);
  }

  private pickMarkdownTableTitle(content: string): string {
    const lines: string[] = content.split('\n');
    for (let index: number = 0; index < lines.length; index++) {
      const line: string = lines[index].trim();
      if (line.indexOf('|') < 0) {
        continue;
      }
      const cells: string[] = line.split('|')
        .map((cell: string) => this.cleanImageTaskLine(cell))
        .filter((cell: string) => cell.length > 0);
      if (cells.length < 2) {
        continue;
      }
      const first: string = cells[0];
      if (first.indexOf('---') >= 0 || first.indexOf('任务名称') >= 0 || first.indexOf('标题') >= 0) {
        continue;
      }
      return this.previewText(first, 28);
    }
    return '';
  }

  private cleanImageTaskLine(line: string): string {
    return line
      .replace(/\*/g, '')
      .replace(/`/g, '')
      .replace(/^[-\s|]+/g, '')
      .replace(/[-\s|]+$/g, '')
      .trim();
  }

  private previewText(value: string, limit: number): string {
    const normalized: string = value.replace(/\s+/g, ' ').trim();
    if (normalized.length <= limit) {
      return normalized;
    }
    return `${normalized.substring(0, limit)}...`;
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

  private parsePriority(value: string): number {
    const parsed: number = Number(value.replace(/[^0-9]/g, ''));
    if (Number.isNaN(parsed)) {
      return 1;
    }
    return Math.max(0, Math.min(3, Math.round(parsed)));
  }

  private parseDueOffsetHours(value: string): number {
    const parsed: number = Number(value.replace(/[^0-9.]/g, ''));
    if (Number.isNaN(parsed)) {
      return 8;
    }
    return Math.max(1, Math.min(24 * 14, Math.round(parsed)));
  }

  private parseImageDueAt(value: string | number | undefined): number | undefined {
    if (value === undefined) {
      return undefined;
    }
    if (typeof value === 'number') {
      return value > 0 ? value : undefined;
    }
    const clean: string = value.trim();
    if (clean.length === 0) {
      return undefined;
    }
    const normalized: string = clean.replace(/\//g, '-').replace(' ', 'T');
    const parsed: number = Date.parse(normalized);
    if (Number.isNaN(parsed)) {
      return undefined;
    }
    return parsed;
  }

  private chatCompletionsUrl(endpoint: string): string {
    const clean: string = this.cleanOrDefault(endpoint, this.envDefaults.endpoint).replace(/\/+$/, '');
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

  private visualTaskModel(settings: AiCoachSettings): string {
    const configured: string = this.cleanOrDefault(settings.model, this.envDefaults.model);
    return configured.length > 0 ? configured : 'mimo-v2.5';
  }

  private loadEnvDefaults(context: common.UIAbilityContext): AiCoachSettings {
    try {
      const content: Uint8Array = context.resourceManager.getRawFileContentSync('ai-env.json');
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const parsed: AiEnvConfig = JSON.parse(decoder.decode(content)) as AiEnvConfig;
      return {
        enabled: true,
        endpoint: this.cleanOrDefault(parsed.endpoint === undefined ? '' : parsed.endpoint, DEFAULT_ENDPOINT),
        model: this.cleanOrDefault(parsed.model === undefined ? '' : parsed.model, DEFAULT_MODEL),
        apiKey: parsed.apiKey === undefined ? DEFAULT_API_KEY : parsed.apiKey.trim()
      };
    } catch (err) {
      return {
        enabled: true,
        endpoint: DEFAULT_ENDPOINT,
        model: DEFAULT_MODEL,
        apiKey: DEFAULT_API_KEY
      };
    }
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

  private imageTaskStatus(message: string): ImageTaskExtractionResult {
    return {
      drafts: [],
      message: message,
      rawContent: '',
      source: 'error'
    };
  }
}

export const focusAiCoachService: FocusAiCoachService = new FocusAiCoachService();
