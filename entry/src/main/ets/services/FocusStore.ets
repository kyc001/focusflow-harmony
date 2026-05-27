import { createDefaultSettings, createForestPlants, createSeedProjects } from '../data/SeedData';
import {
  FocusProject,
  FocusSettings,
  FocusTask,
  ForestPlant,
  PomodoroRecord,
  ResourceInsight,
  StatPoint,
  StudyResource,
  StudyResourceStatus,
  TaskStatus
} from '../models/FocusModels';
import { focusDatabase } from './FocusDatabase';

const DAY_MS: number = 24 * 60 * 60 * 1000;

export class FocusStore {
  projects: FocusProject[] = createSeedProjects();
  tasks: FocusTask[] = [];
  pomodoros: PomodoroRecord[] = [];
  resources: StudyResource[] = [];
  settings: FocusSettings = createDefaultSettings();
  plants: ForestPlant[] = createForestPlants();

  async refresh(): Promise<void> {
    if (!focusDatabase.isReady()) {
      return;
    }
    this.projects = await focusDatabase.getProjects();
    this.tasks = await focusDatabase.getTasks();
    this.pomodoros = await focusDatabase.getPomodoros();
    this.resources = await focusDatabase.getStudyResources();
    if (this.projects.length === 0) {
      this.projects = createSeedProjects();
    }
  }

  getProject(projectId: number): FocusProject {
    const found: FocusProject | undefined = this.projects.find((project: FocusProject) => project.id === projectId);
    return found === undefined ? this.projects[0] : found;
  }

  getTodayTasks(): FocusTask[] {
    return this.tasks
      .filter((task: FocusTask) => task.status === TaskStatus.TODO)
      .sort((left: FocusTask, right: FocusTask) => {
        if (left.priority !== right.priority) {
          return left.priority - right.priority;
        }
        return left.dueAt - right.dueAt;
      });
  }

  getActiveTasks(): FocusTask[] {
    return this.tasks.filter((task: FocusTask) => task.status !== TaskStatus.DELETED);
  }

  getDeletedTasks(): FocusTask[] {
    return this.tasks.filter((task: FocusTask) => task.status === TaskStatus.DELETED);
  }

  getActiveResources(): StudyResource[] {
    return this.resources.filter((resource: StudyResource) => resource.status === StudyResourceStatus.ACTIVE);
  }

  getArchivedResources(): StudyResource[] {
    return this.resources.filter((resource: StudyResource) => resource.status === StudyResourceStatus.ARCHIVED);
  }

  async addTask(title: string, projectId: number, priority: number, dueOffsetHours: number): Promise<FocusTask> {
    const now: number = Date.now();
    const task: FocusTask = {
      id: 0,
      title: title,
      note: '快速添加的学习任务，可在任务页继续拆分。',
      projectId: projectId,
      priority: priority,
      dueAt: now + dueOffsetHours * 60 * 60 * 1000,
      status: TaskStatus.TODO,
      pomodoroCount: 0,
      createdAt: now,
      completedAt: 0,
      tags: ['快速添加'],
      subtasks: []
    };
    const saved: FocusTask = await focusDatabase.addTask(task);
    await this.refresh();
    return saved;
  }

  async addStudyResource(title: string, sourceType: string, projectId: number, content: string): Promise<StudyResource> {
    const now: number = Date.now();
    const resource: StudyResource = {
      id: 0,
      title: title,
      sourceType: sourceType,
      projectId: projectId,
      linkedTaskId: 0,
      content: content,
      summary: '待 AI 或本地规则提炼摘要',
      keyPoints: this.initialKeyPoints(content),
      tags: this.initialTags(sourceType, content),
      status: StudyResourceStatus.ACTIVE,
      createdAt: now,
      updatedAt: now,
      reviewDueAt: now + DAY_MS
    };
    const saved: StudyResource = await focusDatabase.addStudyResource(resource);
    await this.refresh();
    return saved;
  }

  async updateResourceInsight(resourceId: number, insight: ResourceInsight): Promise<void> {
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      return;
    }
    const updated: StudyResource = {
      id: resource.id,
      title: resource.title,
      sourceType: resource.sourceType,
      projectId: resource.projectId,
      linkedTaskId: resource.linkedTaskId,
      content: resource.content,
      summary: insight.summary,
      keyPoints: insight.keyPoints,
      tags: resource.tags,
      status: resource.status,
      createdAt: resource.createdAt,
      updatedAt: Date.now(),
      reviewDueAt: resource.reviewDueAt
    };
    await focusDatabase.updateStudyResource(updated);
    await this.refresh();
  }

  async archiveResource(resourceId: number): Promise<void> {
    await this.setResourceStatus(resourceId, StudyResourceStatus.ARCHIVED);
  }

  async restoreResource(resourceId: number): Promise<void> {
    await this.setResourceStatus(resourceId, StudyResourceStatus.ACTIVE);
  }

  async createTaskFromResource(resourceId: number, title: string, estimatedMinutes: number): Promise<FocusTask | undefined> {
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      return undefined;
    }
    const now: number = Date.now();
    const task: FocusTask = {
      id: 0,
      title: title,
      note: `来自资料「${resource.title}」：${resource.summary}`,
      projectId: resource.projectId,
      priority: estimatedMinutes >= 35 ? 1 : 2,
      dueAt: now + 8 * 60 * 60 * 1000,
      status: TaskStatus.TODO,
      pomodoroCount: 0,
      createdAt: now,
      completedAt: 0,
      tags: ['资料生成'].concat(resource.tags.slice(0, 2)),
      subtasks: resource.keyPoints.length > 0 ? resource.keyPoints.slice(0, 3) : ['阅读资料', '整理要点', '完成复习卡片']
    };
    const saved: FocusTask = await focusDatabase.addTask(task);
    const updated: StudyResource = {
      id: resource.id,
      title: resource.title,
      sourceType: resource.sourceType,
      projectId: resource.projectId,
      linkedTaskId: saved.id,
      content: resource.content,
      summary: resource.summary,
      keyPoints: resource.keyPoints,
      tags: resource.tags,
      status: resource.status,
      createdAt: resource.createdAt,
      updatedAt: Date.now(),
      reviewDueAt: resource.reviewDueAt
    };
    await focusDatabase.updateStudyResource(updated);
    await this.refresh();
    return saved;
  }

  async toggleTask(taskId: number): Promise<void> {
    const task: FocusTask | undefined = this.tasks.find((item: FocusTask) => item.id === taskId);
    if (task === undefined) {
      return;
    }
    const nextStatus: number = task.status === TaskStatus.DONE ? TaskStatus.TODO : TaskStatus.DONE;
    const updated: FocusTask = this.copyTask(task, nextStatus, nextStatus === TaskStatus.DONE ? Date.now() : 0);
    await focusDatabase.updateTask(updated);
    await this.refresh();
  }

  async softDeleteTask(taskId: number): Promise<void> {
    const task: FocusTask | undefined = this.tasks.find((item: FocusTask) => item.id === taskId);
    if (task === undefined) {
      return;
    }
    await focusDatabase.updateTask(this.copyTask(task, TaskStatus.DELETED, task.completedAt));
    await this.refresh();
  }

  async restoreTask(taskId: number): Promise<void> {
    const task: FocusTask | undefined = this.tasks.find((item: FocusTask) => item.id === taskId);
    if (task === undefined) {
      return;
    }
    await focusDatabase.updateTask(this.copyTask(task, TaskStatus.TODO, 0));
    await this.refresh();
  }

  async recordPomodoro(taskId: number, duration: number, completed: boolean, reason: string): Promise<void> {
    const record: PomodoroRecord = {
      id: 0,
      taskId: taskId,
      startAt: Date.now() - duration * 1000,
      duration: duration,
      completed: completed ? 1 : 0,
      interruptReason: reason
    };
    await focusDatabase.recordPomodoro(record);
    if (completed) {
      await focusDatabase.incrementTaskPomodoro(taskId);
    }
    await this.refresh();
  }

  completedPomodoros(): number {
    return this.pomodoros.filter((record: PomodoroRecord) => record.completed === 1).length;
  }

  interruptedPomodoros(): number {
    return this.pomodoros.filter((record: PomodoroRecord) => record.completed === 0).length;
  }

  totalFocusMinutes(): number {
    return Math.round(this.pomodoros
      .filter((record: PomodoroRecord) => record.completed === 1)
      .reduce((sum: number, record: PomodoroRecord) => sum + record.duration, 0) / 60);
  }

  weekFocusPoints(): StatPoint[] {
    const names: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    return names.map((name: string, index: number) => {
      const dayStart: number = this.startOfToday() - (6 - index) * DAY_MS;
      const dayEnd: number = dayStart + DAY_MS;
      const minutes: number = Math.round(this.pomodoros
        .filter((record: PomodoroRecord) => record.completed === 1 && record.startAt >= dayStart && record.startAt < dayEnd)
        .reduce((sum: number, record: PomodoroRecord) => sum + record.duration, 0) / 60);
      const point: StatPoint = { label: name, value: minutes };
      return point;
    });
  }

  projectFocusPoints(): StatPoint[] {
    return this.projects.map((project: FocusProject) => {
      const taskIds: number[] = this.tasks
        .filter((task: FocusTask) => task.projectId === project.id)
        .map((task: FocusTask) => task.id);
      const minutes: number = Math.round(this.pomodoros
        .filter((record: PomodoroRecord) => record.completed === 1 && taskIds.indexOf(record.taskId) >= 0)
        .reduce((sum: number, record: PomodoroRecord) => sum + record.duration, 0) / 60);
      const point: StatPoint = { label: project.name, value: minutes };
      return point;
    });
  }

  streakDays(): number {
    let streak: number = 0;
    for (let i: number = 0; i < 30; i++) {
      const dayStart: number = this.startOfToday() - i * DAY_MS;
      const dayEnd: number = dayStart + DAY_MS;
      const hasRecord: boolean = this.pomodoros.some((record: PomodoroRecord) => {
        return record.completed === 1 && record.startAt >= dayStart && record.startAt < dayEnd;
      });
      if (!hasRecord) {
        break;
      }
      streak++;
    }
    return streak;
  }

  bestStreakDays(): number {
    return Math.max(this.streakDays(), 6);
  }

  unlockedPlants(): ForestPlant[] {
    const total: number = this.completedPomodoros();
    const streak: number = this.streakDays();
    return this.plants.filter((plant: ForestPlant) => {
      return total >= plant.unlockPomodoros && streak >= plant.unlockStreak;
    });
  }

  extractedResourceCount(): number {
    return this.resources.filter((resource: StudyResource) => {
      return resource.summary.length > 0 && resource.summary !== '待 AI 或本地规则提炼摘要';
    }).length;
  }

  private async setResourceStatus(resourceId: number, status: number): Promise<void> {
    const resource: StudyResource | undefined = this.resources.find((item: StudyResource) => item.id === resourceId);
    if (resource === undefined) {
      return;
    }
    const updated: StudyResource = {
      id: resource.id,
      title: resource.title,
      sourceType: resource.sourceType,
      projectId: resource.projectId,
      linkedTaskId: resource.linkedTaskId,
      content: resource.content,
      summary: resource.summary,
      keyPoints: resource.keyPoints,
      tags: resource.tags,
      status: status,
      createdAt: resource.createdAt,
      updatedAt: Date.now(),
      reviewDueAt: resource.reviewDueAt
    };
    await focusDatabase.updateStudyResource(updated);
    await this.refresh();
  }

  private initialKeyPoints(content: string): string[] {
    const trimmed: string = content.trim();
    if (trimmed.length === 0) {
      return ['补充资料正文'];
    }
    const normalized: string = trimmed.replace(/\n/g, '。');
    const parts: string[] = normalized
      .split('。')
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0);
    if (parts.length === 0) {
      return [trimmed.substring(0, Math.min(24, trimmed.length))];
    }
    return parts.slice(0, 3).map((item: string) => item.substring(0, Math.min(36, item.length)));
  }

  private initialTags(sourceType: string, content: string): string[] {
    const tags: string[] = ['资料'];
    if (sourceType.length > 0) {
      tags.push(sourceType);
    }
    if (content.indexOf('AI') >= 0 || content.indexOf('ai') >= 0) {
      tags.push('AI');
    }
    return tags;
  }

  private copyTask(task: FocusTask, status: number, completedAt: number): FocusTask {
    return {
      id: task.id,
      title: task.title,
      note: task.note,
      projectId: task.projectId,
      priority: task.priority,
      dueAt: task.dueAt,
      status: status,
      pomodoroCount: task.pomodoroCount,
      createdAt: task.createdAt,
      completedAt: completedAt,
      tags: task.tags,
      subtasks: task.subtasks
    };
  }

  private startOfToday(): number {
    const now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  }
}

export const focusStore: FocusStore = new FocusStore();
