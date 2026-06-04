export enum TaskStatus {
  TODO = 0,
  DONE = 1,
  DELETED = 2
}

export enum StudyResourceStatus {
  ACTIVE = 0,
  ARCHIVED = 1
}

export enum ResourceSummaryStatus {
  PENDING = 0,
  EXTRACTED = 1,
  FAILED = 2
}

export enum PomodoroStatus {
  IDLE = 0,
  RUNNING = 1,
  PAUSED = 2,
  BREAK = 3,
  FINISHED = 4
}

export interface FocusProject {
  id: number;
  name: string;
  color: string;
  icon: string;
  updatedAt?: number;
  isDeleted?: number;
}

export interface FocusTask {
  id: number;
  title: string;
  note: string;
  projectId: number;
  priority: number;
  dueAt: number;
  status: number;
  pomodoroCount: number;
  createdAt: number;
  completedAt: number;
  tags: string[];
  subtasks: string[];
  updatedAt?: number;
  isDeleted?: number;
  clientRequestId?: string;
}

export interface QuickTaskDraft {
  title: string;
  note: string;
  projectId?: number;
  priority: number;
  dueAt?: number;
  dueOffsetHours?: number;
  source?: string;
  tags?: string[];
  subtasks?: string[];
}

export interface ImageTaskExtractionResult {
  drafts: QuickTaskDraft[];
  message: string;
  rawContent: string;
  source: string;
}

export interface StudyResource {
  id: number;
  title: string;
  sourceType: string;
  projectId: number;
  linkedTaskId: number;
  content: string;
  summary: string;
  summaryStatus?: number;
  keyPoints: string[];
  tags: string[];
  status: number;
  createdAt: number;
  updatedAt: number;
  reviewDueAt: number;
}

export interface PomodoroRecord {
  id: number;
  taskId: number;
  startAt: number;
  duration: number;
  completed: number;
  interruptReason: string;
  updatedAt?: number;
  clientRequestId?: string;
}

export interface FocusSettings {
  focusMinutes: number;
  shortBreakMinutes: number;
  longBreakMinutes: number;
  themeColor: string;
  noise: string;
  notificationEnabled: boolean;
}

export interface ForestPlant {
  id: number;
  name: string;
  icon: string;
  unlockPomodoros: number;
  unlockStreak: number;
  color: string;
}

export interface StatPoint {
  label: string;
  value: number;
}

export interface ReviewStats {
  completedPomodoros: number;
  interruptedPomodoros: number;
  totalFocusMinutes: number;
  weekFocusPoints: StatPoint[];
  projectFocusPoints: StatPoint[];
  streakDays: number;
  bestStreakDays: number;
  unlockedPlantIds: number[];
}

export interface AiCoachSettings {
  enabled: boolean;
  endpoint: string;
  model: string;
  apiKey: string;
}

export interface AiCoachAdvice {
  source: string;
  headline: string;
  nextAction: string;
  sessionPlan: string;
  risk: string;
  estimatedMinutes: number;
  confidence: number;
  generatedAt: number;
}

export interface ResourceInsight {
  source: string;
  summary: string;
  keyPoints: string[];
  nextTaskTitle: string;
  estimatedMinutes: number;
  generatedAt: number;
}
