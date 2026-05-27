import { PomodoroStatus } from '../models/FocusModels';

const PRIORITY_CRITICAL: string = '#E4566E';
const PRIORITY_URGENT: string = '#F59E0B';
const PRIORITY_IMPORTANT: string = '#2F6BFF';
const PRIORITY_LOW: string = '#8B95A7';

const DANGER_SOFT: string = '#FBEAEE';
const WARNING_SOFT: string = '#FBF1E2';
const ACCENT_SOFT: string = '#EDF1FF';
const SURFACE_ALT: string = '#F1F3F7';

const ACCENT: string = '#4258C9';
const WARNING: string = '#D88B2B';
const SUCCESS: string = '#1FA37A';

export function formatTimerText(seconds: number): string {
  const safeSeconds: number = Math.max(0, seconds);
  const minute: number = Math.floor(safeSeconds / 60);
  const second: number = safeSeconds % 60;
  const minuteText: string = minute < 10 ? `0${minute}` : `${minute}`;
  const secondText: string = second < 10 ? `0${second}` : `${second}`;
  return `${minuteText}:${secondText}`;
}

export function formatDueText(timestamp: number, now: number = Date.now()): string {
  const diff: number = timestamp - now;
  if (diff <= 0) {
    return '已到期';
  }
  const hours: number = Math.ceil(diff / (60 * 60 * 1000));
  if (hours < 24) {
    return `${hours} 小时内`;
  }
  return `${Math.ceil(hours / 24)} 天内`;
}

export function priorityName(priority: number): string {
  if (priority === 0) {
    return '紧急重要';
  }
  if (priority === 1) {
    return '紧急不重要';
  }
  if (priority === 2) {
    return '重要不紧急';
  }
  return '不紧急不重要';
}

export function priorityColor(priority: number): string {
  if (priority === 0) {
    return PRIORITY_CRITICAL;
  }
  if (priority === 1) {
    return PRIORITY_URGENT;
  }
  if (priority === 2) {
    return PRIORITY_IMPORTANT;
  }
  return PRIORITY_LOW;
}

export function priorityTint(priority: number): string {
  if (priority === 0) {
    return DANGER_SOFT;
  }
  if (priority === 1) {
    return WARNING_SOFT;
  }
  if (priority === 2) {
    return ACCENT_SOFT;
  }
  return SURFACE_ALT;
}

export function focusStateText(status: PomodoroStatus): string {
  if (status === PomodoroStatus.RUNNING) {
    return '沉浸中';
  }
  if (status === PomodoroStatus.PAUSED) {
    return '已暂停';
  }
  if (status === PomodoroStatus.FINISHED) {
    return '休息一下';
  }
  return '准备开始';
}

export function focusStateColor(status: PomodoroStatus): string {
  if (status === PomodoroStatus.RUNNING) {
    return ACCENT;
  }
  if (status === PomodoroStatus.PAUSED) {
    return WARNING;
  }
  if (status === PomodoroStatus.FINISHED) {
    return SUCCESS;
  }
  return PRIORITY_LOW;
}
