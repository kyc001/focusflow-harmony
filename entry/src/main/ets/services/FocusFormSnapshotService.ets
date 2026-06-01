import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { FocusTask, PomodoroRecord, TaskStatus } from '../models/FocusModels';

const PREF_NAME: string = 'focus_form_snapshot';
const DAILY_POMODORO_TARGET: number = 4;

export interface FocusFormData {
  title: string;
  subtitle: string;
  progress: string;
  progressPercent: number;
  task1: string;
  task2: string;
  task3: string;
  isCompact: boolean;
}

export const DEFAULT_FOCUS_FORM_DATA: FocusFormData = {
  title: '知序 今日',
  subtitle: '本地学习闭环',
  progress: '0/4 番茄',
  progressPercent: 0,
  task1: '暂无待办任务',
  task2: '打开应用添加学习计划',
  task3: '完成番茄后卡片会更新',
  isCompact: false
};

export class FocusFormSnapshotService {
  private pref?: preferences.Preferences;

  async init(context: common.Context): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
    } catch (err) {
      this.pref = undefined;
    }
  }

  async saveSnapshot(context: common.Context, tasks: FocusTask[], pomodoros: PomodoroRecord[], resourcesLength: number): Promise<void> {
    try {
      await this.init(context);
      if (this.pref === undefined) {
        return;
      }
      const data: FocusFormData = this.buildSnapshot(tasks, pomodoros, resourcesLength, false);
      await this.pref.put('title', data.title);
      await this.pref.put('subtitle', data.subtitle);
      await this.pref.put('progress', data.progress);
      await this.pref.put('progressPercent', data.progressPercent);
      await this.pref.put('task1', data.task1);
      await this.pref.put('task2', data.task2);
      await this.pref.put('task3', data.task3);
      await this.pref.flush();
    } catch (err) {
    }
  }

  loadSnapshotSync(context: common.Context, isCompact: boolean): FocusFormData {
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
      return {
        title: pref.getSync('title', DEFAULT_FOCUS_FORM_DATA.title) as string,
        subtitle: pref.getSync('subtitle', DEFAULT_FOCUS_FORM_DATA.subtitle) as string,
        progress: pref.getSync('progress', DEFAULT_FOCUS_FORM_DATA.progress) as string,
        progressPercent: pref.getSync('progressPercent', DEFAULT_FOCUS_FORM_DATA.progressPercent) as number,
        task1: pref.getSync('task1', DEFAULT_FOCUS_FORM_DATA.task1) as string,
        task2: pref.getSync('task2', DEFAULT_FOCUS_FORM_DATA.task2) as string,
        task3: pref.getSync('task3', DEFAULT_FOCUS_FORM_DATA.task3) as string,
        isCompact: isCompact
      };
    } catch (err) {
      return this.defaultData(isCompact);
    }
  }

  private defaultData(isCompact: boolean): FocusFormData {
    return {
      title: DEFAULT_FOCUS_FORM_DATA.title,
      subtitle: DEFAULT_FOCUS_FORM_DATA.subtitle,
      progress: DEFAULT_FOCUS_FORM_DATA.progress,
      progressPercent: DEFAULT_FOCUS_FORM_DATA.progressPercent,
      task1: DEFAULT_FOCUS_FORM_DATA.task1,
      task2: DEFAULT_FOCUS_FORM_DATA.task2,
      task3: DEFAULT_FOCUS_FORM_DATA.task3,
      isCompact: isCompact
    };
  }

  private buildSnapshot(tasks: FocusTask[], pomodoros: PomodoroRecord[], resourcesLength: number, isCompact: boolean): FocusFormData {
    const todayStart: number = this.startOfToday(Date.now());
    const todayEnd: number = todayStart + 24 * 60 * 60 * 1000;
    const todayPomodoros: number = pomodoros.filter((record: PomodoroRecord) => {
      return record.completed === 1 && record.startAt >= todayStart && record.startAt < todayEnd;
    }).length;
    const activeTasks: FocusTask[] = tasks
      .filter((task: FocusTask) => task.status === TaskStatus.TODO && task.isDeleted !== 1)
      .sort((left: FocusTask, right: FocusTask) => {
        if (left.priority !== right.priority) {
          return left.priority - right.priority;
        }
        return left.dueAt - right.dueAt;
      });
    const taskNames: string[] = activeTasks.slice(0, 3).map((task: FocusTask) => task.title);
    while (taskNames.length < 3) {
      taskNames.push(taskNames.length === 0 ? '暂无待办任务' : '完成后自动刷新卡片');
    }
    const percent: number = Math.min(100, Math.round(todayPomodoros * 100 / DAILY_POMODORO_TARGET));
    return {
      title: '知序 今日',
      subtitle: `${activeTasks.length} 项待办 · ${resourcesLength} 份资料`,
      progress: `${todayPomodoros}/${DAILY_POMODORO_TARGET} 番茄`,
      progressPercent: percent,
      task1: taskNames[0],
      task2: taskNames[1],
      task3: taskNames[2],
      isCompact: isCompact
    };
  }

  private startOfToday(now: number): number {
    const date: Date = new Date(now);
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  }
}

export const focusFormSnapshotService: FocusFormSnapshotService = new FocusFormSnapshotService();
