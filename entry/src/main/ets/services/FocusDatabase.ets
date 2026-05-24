import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { createSeedPomodoros, createSeedProjects, createSeedTasks } from '../data/SeedData';
import { FocusProject, FocusTask, PomodoroRecord, TaskStatus } from '../models/FocusModels';

type ValueType = relationalStore.ValueType;

const DB_NAME: string = 'focus.db';
const DB_VERSION: number = 2;

export class FocusDatabase {
  private store?: relationalStore.RdbStore;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== undefined) {
      return;
    }
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.store = await relationalStore.getRdbStore(context, config);
    this.store.version = DB_VERSION;
    await this.createTables();
    await this.seedIfEmpty();
  }

  async createTables(): Promise<void> {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS projects (' +
        'id INTEGER PRIMARY KEY, ' +
        'name TEXT NOT NULL, ' +
        'color TEXT NOT NULL, ' +
        'icon TEXT NOT NULL, ' +
        'updated_at INTEGER NOT NULL DEFAULT 0, ' +
        'is_deleted INTEGER NOT NULL DEFAULT 0' +
        ')'
    );
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS tasks (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'title TEXT NOT NULL, ' +
        'note TEXT, ' +
        'project_id INTEGER, ' +
        'priority INTEGER NOT NULL DEFAULT 0, ' +
        'due_at INTEGER NOT NULL DEFAULT 0, ' +
        'status INTEGER NOT NULL DEFAULT 0, ' +
        'pomodoro_count INTEGER NOT NULL DEFAULT 0, ' +
        'created_at INTEGER NOT NULL, ' +
        'updated_at INTEGER NOT NULL DEFAULT 0, ' +
        'completed_at INTEGER NOT NULL DEFAULT 0, ' +
        'tags_json TEXT, ' +
        'subtasks_json TEXT' +
        ')'
    );
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS pomodoros (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'task_id INTEGER, ' +
        'start_at INTEGER NOT NULL, ' +
        'duration INTEGER NOT NULL, ' +
        'completed INTEGER NOT NULL, ' +
        'interrupt_reason TEXT, ' +
        'updated_at INTEGER NOT NULL DEFAULT 0' +
        ')'
    );
    await this.addColumnIfMissing('projects', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('projects', 'is_deleted', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('tasks', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('tasks', 'tags_json', 'TEXT');
    await this.addColumnIfMissing('tasks', 'subtasks_json', 'TEXT');
    await this.addColumnIfMissing('pomodoros', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');
  }

  async getProjects(): Promise<FocusProject[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, name, color, icon FROM projects WHERE is_deleted = 0 ORDER BY id ASC'
    );
    const projects: FocusProject[] = [];
    try {
      while (resultSet.goToNextRow()) {
        projects.push({
          id: this.longValue(resultSet, 'id'),
          name: this.stringValue(resultSet, 'name', '默认项目'),
          color: this.stringValue(resultSet, 'color', '#4F63D2'),
          icon: this.stringValue(resultSet, 'icon', 'P')
        });
      }
    } finally {
      resultSet.close();
    }
    return projects;
  }

  async getTasks(): Promise<FocusTask[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, completed_at, tags_json, subtasks_json ' +
        'FROM tasks ORDER BY status ASC, due_at ASC, priority ASC, id DESC'
    );
    const tasks: FocusTask[] = [];
    try {
      while (resultSet.goToNextRow()) {
        tasks.push({
          id: this.longValue(resultSet, 'id'),
          title: this.stringValue(resultSet, 'title', '未命名任务'),
          note: this.stringValue(resultSet, 'note', ''),
          projectId: this.longValue(resultSet, 'project_id'),
          priority: this.longValue(resultSet, 'priority'),
          dueAt: this.longValue(resultSet, 'due_at'),
          status: this.longValue(resultSet, 'status'),
          pomodoroCount: this.longValue(resultSet, 'pomodoro_count'),
          createdAt: this.longValue(resultSet, 'created_at'),
          completedAt: this.longValue(resultSet, 'completed_at'),
          tags: this.parseStringArray(this.stringValue(resultSet, 'tags_json', '[]')),
          subtasks: this.parseStringArray(this.stringValue(resultSet, 'subtasks_json', '[]'))
        });
      }
    } finally {
      resultSet.close();
    }
    return tasks;
  }

  async getPomodoros(): Promise<PomodoroRecord[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, task_id, start_at, duration, completed, interrupt_reason FROM pomodoros ORDER BY start_at DESC, id DESC'
    );
    const records: PomodoroRecord[] = [];
    try {
      while (resultSet.goToNextRow()) {
        records.push({
          id: this.longValue(resultSet, 'id'),
          taskId: this.longValue(resultSet, 'task_id'),
          startAt: this.longValue(resultSet, 'start_at'),
          duration: this.longValue(resultSet, 'duration'),
          completed: this.longValue(resultSet, 'completed'),
          interruptReason: this.stringValue(resultSet, 'interrupt_reason', '')
        });
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  async addTask(task: FocusTask): Promise<FocusTask> {
    const values: relationalStore.ValuesBucket = this.taskToBucket(task, false);
    const id: number = await this.requireStore().insert('tasks', values);
    return {
      id: id,
      title: task.title,
      note: task.note,
      projectId: task.projectId,
      priority: task.priority,
      dueAt: task.dueAt,
      status: task.status,
      pomodoroCount: task.pomodoroCount,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      tags: task.tags,
      subtasks: task.subtasks
    };
  }

  async upsertProject(project: FocusProject): Promise<void> {
    await this.requireStore().executeSql(
      'INSERT OR REPLACE INTO projects (id, name, color, icon, updated_at, is_deleted) VALUES (?, ?, ?, ?, ?, 0)',
      [project.id, project.name, project.color, project.icon, Date.now()]
    );
  }

  async upsertTask(task: FocusTask): Promise<void> {
    const values: relationalStore.ValuesBucket = this.taskToBucket(task, true);
    await this.requireStore().executeSql(
      'INSERT OR REPLACE INTO tasks (' +
        'id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, tags_json, subtasks_json' +
        ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        values.id as number,
        values.title as string,
        values.note as string,
        values.project_id as number,
        values.priority as number,
        values.due_at as number,
        values.status as number,
        values.pomodoro_count as number,
        values.created_at as number,
        values.updated_at as number,
        values.completed_at as number,
        values.tags_json as string,
        values.subtasks_json as string
      ]
    );
  }

  async updateTask(task: FocusTask): Promise<void> {
    const values: relationalStore.ValuesBucket = this.taskToBucket(task, false);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('tasks');
    predicates.equalTo('id', task.id);
    await this.requireStore().update(values, predicates);
  }

  async recordPomodoro(record: PomodoroRecord): Promise<PomodoroRecord> {
    const values: relationalStore.ValuesBucket = {
      task_id: record.taskId,
      start_at: record.startAt,
      duration: record.duration,
      completed: record.completed,
      interrupt_reason: record.interruptReason,
      updated_at: Date.now()
    };
    const id: number = await this.requireStore().insert('pomodoros', values);
    return {
      id: id,
      taskId: record.taskId,
      startAt: record.startAt,
      duration: record.duration,
      completed: record.completed,
      interruptReason: record.interruptReason
    };
  }

  async incrementTaskPomodoro(taskId: number): Promise<void> {
    await this.requireStore().executeSql(
      'UPDATE tasks SET pomodoro_count = pomodoro_count + 1, updated_at = ? WHERE id = ?',
      [Date.now(), taskId]
    );
  }

  isReady(): boolean {
    return this.store !== undefined;
  }

  private async seedIfEmpty(): Promise<void> {
    const count: number = await this.countRows('projects');
    if (count > 0) {
      return;
    }
    const projects: FocusProject[] = createSeedProjects();
    const tasks: FocusTask[] = createSeedTasks();
    const records: PomodoroRecord[] = createSeedPomodoros();
    for (const project of projects) {
      await this.upsertProject(project);
    }
    for (const task of tasks) {
      await this.upsertTask(task);
    }
    for (const record of records) {
      await this.requireStore().executeSql(
        'INSERT OR REPLACE INTO pomodoros (id, task_id, start_at, duration, completed, interrupt_reason, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [record.id, record.taskId, record.startAt, record.duration, record.completed, record.interruptReason, Date.now()]
      );
    }
  }

  private async addColumnIfMissing(tableName: string, columnName: string, definition: string): Promise<void> {
    const resultSet: relationalStore.ResultSet = await this.query(`PRAGMA table_info(${tableName})`);
    let exists: boolean = false;
    try {
      while (resultSet.goToNextRow()) {
        if (this.stringValue(resultSet, 'name', '') === columnName) {
          exists = true;
          break;
        }
      }
    } finally {
      resultSet.close();
    }
    if (!exists) {
      await this.requireStore().executeSql(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${definition}`);
    }
  }

  private async countRows(tableName: string): Promise<number> {
    const resultSet: relationalStore.ResultSet = await this.query(`SELECT COUNT(*) AS total FROM ${tableName}`);
    try {
      if (resultSet.goToNextRow()) {
        return this.longValue(resultSet, 'total');
      }
      return 0;
    } finally {
      resultSet.close();
    }
  }

  private taskToBucket(task: FocusTask, includeId: boolean): relationalStore.ValuesBucket {
    const values: relationalStore.ValuesBucket = {
      title: task.title,
      note: task.note,
      project_id: task.projectId,
      priority: task.priority,
      due_at: task.dueAt,
      status: task.status,
      pomodoro_count: task.pomodoroCount,
      created_at: task.createdAt,
      updated_at: Date.now(),
      completed_at: task.completedAt,
      tags_json: JSON.stringify(task.tags),
      subtasks_json: JSON.stringify(task.subtasks)
    };
    if (includeId) {
      values.id = task.id;
    }
    return values;
  }

  private async query(sql: string, args?: ValueType[]): Promise<relationalStore.ResultSet> {
    return await this.requireStore().querySql(sql, args);
  }

  private requireStore(): relationalStore.RdbStore {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      throw new Error('FocusDatabase is not initialized');
    }
    return store;
  }

  private longValue(resultSet: relationalStore.ResultSet, columnName: string): number {
    const index: number = resultSet.getColumnIndex(columnName);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return 0;
    }
    return resultSet.getLong(index);
  }

  private stringValue(resultSet: relationalStore.ResultSet, columnName: string, fallback: string): string {
    const index: number = resultSet.getColumnIndex(columnName);
    if (index < 0 || resultSet.isColumnNull(index)) {
      return fallback;
    }
    return resultSet.getString(index);
  }

  private parseStringArray(value: string): string[] {
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

export const focusDatabase: FocusDatabase = new FocusDatabase();
