import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { createSeedPomodoros, createSeedProjects, createSeedStudyResources, createSeedTasks } from '../data/SeedData';
import { FocusProject, FocusTask, PomodoroRecord, ResourceSummaryStatus, StudyResource, TaskStatus } from '../models/FocusModels';

type ValueType = relationalStore.ValueType;

const DB_NAME: string = 'focus.db';
const DB_VERSION: number = 6;

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
    await this.seedStudyResourcesIfEmpty();
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
        'is_deleted INTEGER NOT NULL DEFAULT 0, ' +
        'dirty INTEGER NOT NULL DEFAULT 1' +
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
        'is_deleted INTEGER NOT NULL DEFAULT 0, ' +
        'client_request_id TEXT, ' +
        'tags_json TEXT, ' +
        'subtasks_json TEXT, ' +
        'dirty INTEGER NOT NULL DEFAULT 1' +
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
        'updated_at INTEGER NOT NULL DEFAULT 0, ' +
        'client_request_id TEXT, ' +
        'dirty INTEGER NOT NULL DEFAULT 1' +
        ')'
    );
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS study_resources (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'title TEXT NOT NULL, ' +
        'source_type TEXT NOT NULL, ' +
        'project_id INTEGER NOT NULL, ' +
        'linked_task_id INTEGER NOT NULL DEFAULT 0, ' +
        'content TEXT, ' +
        'summary TEXT, ' +
        'summary_status INTEGER NOT NULL DEFAULT 0, ' +
        'key_points_json TEXT, ' +
        'tags_json TEXT, ' +
        'status INTEGER NOT NULL DEFAULT 0, ' +
        'created_at INTEGER NOT NULL, ' +
        'updated_at INTEGER NOT NULL, ' +
        'review_due_at INTEGER NOT NULL DEFAULT 0' +
        ')'
    );
    await this.addColumnIfMissing('projects', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('projects', 'is_deleted', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('projects', 'dirty', 'INTEGER NOT NULL DEFAULT 1');
    await this.addColumnIfMissing('tasks', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('tasks', 'is_deleted', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('tasks', 'client_request_id', 'TEXT');
    await this.addColumnIfMissing('tasks', 'tags_json', 'TEXT');
    await this.addColumnIfMissing('tasks', 'subtasks_json', 'TEXT');
    await this.addColumnIfMissing('tasks', 'dirty', 'INTEGER NOT NULL DEFAULT 1');
    await this.addColumnIfMissing('pomodoros', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');
    await this.addColumnIfMissing('pomodoros', 'client_request_id', 'TEXT');
    await this.addColumnIfMissing('pomodoros', 'dirty', 'INTEGER NOT NULL DEFAULT 1');
    await this.addColumnIfMissing('study_resources', 'summary_status', 'INTEGER NOT NULL DEFAULT 0');
    await this.backfillTaskClientRequestIds();
    await this.backfillPomodoroClientRequestIds();
  }

  async getProjects(): Promise<FocusProject[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, name, color, icon, updated_at, is_deleted FROM projects WHERE is_deleted = 0 ORDER BY id ASC'
    );
    const projects: FocusProject[] = [];
    try {
      while (resultSet.goToNextRow()) {
        projects.push({
          id: this.longValue(resultSet, 'id'),
          name: this.stringValue(resultSet, 'name', '默认项目'),
          color: this.stringValue(resultSet, 'color', '#4F63D2'),
          icon: this.stringValue(resultSet, 'icon', 'P'),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          isDeleted: this.longValue(resultSet, 'is_deleted')
        });
      }
    } finally {
      resultSet.close();
    }
    return projects;
  }

  async getProjectsForSync(): Promise<FocusProject[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, name, color, icon, updated_at, is_deleted FROM projects WHERE dirty = 1 ORDER BY updated_at ASC, id ASC'
    );
    const projects: FocusProject[] = [];
    try {
      while (resultSet.goToNextRow()) {
        projects.push({
          id: this.longValue(resultSet, 'id'),
          name: this.stringValue(resultSet, 'name', '默认项目'),
          color: this.stringValue(resultSet, 'color', '#4F63D2'),
          icon: this.stringValue(resultSet, 'icon', 'P'),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          isDeleted: this.longValue(resultSet, 'is_deleted')
        });
      }
    } finally {
      resultSet.close();
    }
    return projects;
  }

  async getTasks(): Promise<FocusTask[]> {
    return this.queryTasks('WHERE is_deleted = 0', []);
  }

  async getTasksWithDeleted(): Promise<FocusTask[]> {
    return this.queryTasks('', []);
  }

  async getTasksForSync(): Promise<FocusTask[]> {
    return this.queryTasks('WHERE dirty = 1', []);
  }

  async getPomodorosForSync(): Promise<PomodoroRecord[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, task_id, start_at, duration, completed, interrupt_reason, updated_at, client_request_id ' +
        'FROM pomodoros WHERE dirty = 1 ORDER BY updated_at ASC, id ASC'
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
          interruptReason: this.stringValue(resultSet, 'interrupt_reason', ''),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          clientRequestId: this.stringValue(resultSet, 'client_request_id', '')
        });
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  private async queryTasks(whereClause: string, args: relationalStore.ValueType[]): Promise<FocusTask[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted, client_request_id, tags_json, subtasks_json ' +
        `FROM tasks ${whereClause} ORDER BY status ASC, due_at ASC, priority ASC, id DESC`,
      args
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
          subtasks: this.parseStringArray(this.stringValue(resultSet, 'subtasks_json', '[]')),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          isDeleted: this.longValue(resultSet, 'is_deleted'),
          clientRequestId: this.stringValue(resultSet, 'client_request_id', '')
        });
      }
    } finally {
      resultSet.close();
    }
    return tasks;
  }

  async getPomodoros(): Promise<PomodoroRecord[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, task_id, start_at, duration, completed, interrupt_reason, updated_at, client_request_id FROM pomodoros ORDER BY start_at DESC, id DESC'
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
          interruptReason: this.stringValue(resultSet, 'interrupt_reason', ''),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          clientRequestId: this.stringValue(resultSet, 'client_request_id', '')
        });
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  async getStudyResources(): Promise<StudyResource[]> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, title, source_type, project_id, linked_task_id, content, summary, summary_status, key_points_json, tags_json, status, created_at, updated_at, review_due_at ' +
        'FROM study_resources ORDER BY status ASC, updated_at DESC, id DESC'
    );
    const resources: StudyResource[] = [];
    try {
      while (resultSet.goToNextRow()) {
        resources.push({
          id: this.longValue(resultSet, 'id'),
          title: this.stringValue(resultSet, 'title', '未命名资料'),
          sourceType: this.stringValue(resultSet, 'source_type', 'note'),
          projectId: this.longValue(resultSet, 'project_id'),
          linkedTaskId: this.longValue(resultSet, 'linked_task_id'),
          content: this.stringValue(resultSet, 'content', ''),
          summary: this.stringValue(resultSet, 'summary', ''),
          summaryStatus: this.resourceSummaryStatus(
            this.longValue(resultSet, 'summary_status'),
            this.stringValue(resultSet, 'summary', '')
          ),
          keyPoints: this.parseStringArray(this.stringValue(resultSet, 'key_points_json', '[]')),
          tags: this.parseStringArray(this.stringValue(resultSet, 'tags_json', '[]')),
          status: this.longValue(resultSet, 'status'),
          createdAt: this.longValue(resultSet, 'created_at'),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          reviewDueAt: this.longValue(resultSet, 'review_due_at')
        });
      }
    } finally {
      resultSet.close();
    }
    return resources;
  }

  async addTask(task: FocusTask): Promise<FocusTask> {
    const values: relationalStore.ValuesBucket = this.taskToBucket(task, false, 1);
    const id: number = await this.requireStore().insert('tasks', values);
    const clientRequestId: string = `client-task-${id}`;
    await this.requireStore().executeSql(
      'UPDATE tasks SET client_request_id = ? WHERE id = ?',
      [clientRequestId, id]
    );
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
      subtasks: task.subtasks,
      updatedAt: values.updated_at as number,
      isDeleted: 0,
      clientRequestId: clientRequestId
    };
  }

  async addStudyResource(resource: StudyResource): Promise<StudyResource> {
    const values: relationalStore.ValuesBucket = this.resourceToBucket(resource, false);
    const id: number = await this.requireStore().insert('study_resources', values);
    return {
      id: id,
      title: resource.title,
      sourceType: resource.sourceType,
      projectId: resource.projectId,
      linkedTaskId: resource.linkedTaskId,
      content: resource.content,
      summary: resource.summary,
      keyPoints: resource.keyPoints,
      tags: resource.tags,
      status: resource.status,
      createdAt: resource.createdAt,
      updatedAt: resource.updatedAt,
      reviewDueAt: resource.reviewDueAt
    };
  }

  async upsertProject(project: FocusProject, markDirty: boolean = false): Promise<void> {
    const updatedAt: number = project.updatedAt === undefined || project.updatedAt <= 0 ? Date.now() : project.updatedAt;
    const existing: FocusProject | undefined = await this.findProjectById(project.id);
    if (existing !== undefined && (existing.updatedAt || 0) > updatedAt) {
      return;
    }
    await this.requireStore().executeSql(
      'INSERT OR REPLACE INTO projects (id, name, color, icon, updated_at, is_deleted, dirty) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        project.id,
        project.name,
        project.color,
        project.icon,
        updatedAt,
        project.isDeleted === undefined ? 0 : project.isDeleted,
        markDirty ? 1 : 0
      ]
    );
  }

  async upsertTask(task: FocusTask, markDirty: boolean = false): Promise<void> {
    const updatedAt: number = task.updatedAt === undefined || task.updatedAt <= 0 ? Date.now() : task.updatedAt;
    const clientRequestId: string = this.taskClientRequestId(task);
    const existing: FocusTask | undefined = await this.findTaskByIdOrClientRequestId(task.id, clientRequestId);
    if (existing !== undefined && (existing.updatedAt || 0) > updatedAt) {
      return;
    }
    const targetId: number = existing === undefined ? task.id : existing.id;
    const values: relationalStore.ValuesBucket = this.taskToBucket(task, true, markDirty ? 1 : 0);
    await this.requireStore().executeSql(
      'INSERT OR REPLACE INTO tasks (' +
        'id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted, client_request_id, tags_json, subtasks_json, dirty' +
        ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        targetId,
        values.title as string,
        values.note as string,
        values.project_id as number,
        values.priority as number,
        values.due_at as number,
        values.status as number,
        values.pomodoro_count as number,
        values.created_at as number,
        updatedAt,
        values.completed_at as number,
        task.isDeleted === undefined ? (task.status === TaskStatus.DELETED ? 1 : 0) : task.isDeleted,
        clientRequestId,
        values.tags_json as string,
        values.subtasks_json as string,
        markDirty ? 1 : 0
      ]
    );
  }

  async upsertStudyResource(resource: StudyResource): Promise<void> {
    const values: relationalStore.ValuesBucket = this.resourceToBucket(resource, true);
    await this.requireStore().executeSql(
      'INSERT OR REPLACE INTO study_resources (' +
        'id, title, source_type, project_id, linked_task_id, content, summary, summary_status, key_points_json, tags_json, status, created_at, updated_at, review_due_at' +
        ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        values.id as number,
        values.title as string,
        values.source_type as string,
        values.project_id as number,
        values.linked_task_id as number,
        values.content as string,
        values.summary as string,
        values.summary_status as number,
        values.key_points_json as string,
        values.tags_json as string,
        values.status as number,
        values.created_at as number,
        values.updated_at as number,
        values.review_due_at as number
      ]
    );
  }

  async updateTask(task: FocusTask): Promise<void> {
    const values: relationalStore.ValuesBucket = this.taskToBucket(task, false, 1);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('tasks');
    predicates.equalTo('id', task.id);
    await this.requireStore().update(values, predicates);
  }

  async localProjectUpdatedAt(projectId: number): Promise<number> {
    const project: FocusProject | undefined = await this.findProjectById(projectId);
    return project === undefined ? 0 : (project.updatedAt || 0);
  }

  async localTaskUpdatedAt(taskId: number, clientRequestId: string): Promise<number> {
    const task: FocusTask | undefined = await this.findTaskByIdOrClientRequestId(taskId, clientRequestId);
    return task === undefined ? 0 : (task.updatedAt || 0);
  }

  async updateStudyResource(resource: StudyResource): Promise<void> {
    const values: relationalStore.ValuesBucket = this.resourceToBucket(resource, false);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('study_resources');
    predicates.equalTo('id', resource.id);
    await this.requireStore().update(values, predicates);
  }

  async recordPomodoro(record: PomodoroRecord): Promise<PomodoroRecord> {
    const updatedAt: number = record.updatedAt === undefined || record.updatedAt <= 0 ? Date.now() : record.updatedAt;
    const clientRequestId: string = this.pomodoroClientRequestId(record);
    const values: relationalStore.ValuesBucket = {
      task_id: record.taskId,
      start_at: record.startAt,
      duration: record.duration,
      completed: record.completed,
      interrupt_reason: record.interruptReason,
      updated_at: updatedAt,
      client_request_id: clientRequestId,
      dirty: 1
    };
    const id: number = await this.requireStore().insert('pomodoros', values);
    return {
      id: id,
      taskId: record.taskId,
      startAt: record.startAt,
      duration: record.duration,
      completed: record.completed,
      interruptReason: record.interruptReason,
      updatedAt: updatedAt,
      clientRequestId: clientRequestId
    };
  }

  async upsertPomodoro(record: PomodoroRecord, markDirty: boolean = false): Promise<void> {
    const updatedAt: number = record.updatedAt === undefined || record.updatedAt <= 0 ? Date.now() : record.updatedAt;
    const clientRequestId: string = this.pomodoroClientRequestId(record);
    const existing: PomodoroRecord | undefined = await this.findPomodoroByClientRequestId(clientRequestId);
    if (existing !== undefined && (existing.updatedAt || 0) > updatedAt) {
      return;
    }
    const existingId: number = existing === undefined ? 0 : existing.id;
    if (existingId > 0) {
      await this.requireStore().executeSql(
        'INSERT OR REPLACE INTO pomodoros (id, task_id, start_at, duration, completed, interrupt_reason, updated_at, client_request_id, dirty) ' +
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          existingId,
          record.taskId,
          record.startAt,
          record.duration,
          record.completed,
          record.interruptReason,
          updatedAt,
          clientRequestId,
          markDirty ? 1 : 0
        ]
      );
    } else {
      await this.requireStore().executeSql(
        'INSERT INTO pomodoros (task_id, start_at, duration, completed, interrupt_reason, updated_at, client_request_id, dirty) ' +
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          record.taskId,
          record.startAt,
          record.duration,
          record.completed,
          record.interruptReason,
          updatedAt,
          clientRequestId,
          markDirty ? 1 : 0
        ]
      );
    }
  }

  async incrementTaskPomodoro(taskId: number): Promise<void> {
    await this.requireStore().executeSql(
      'UPDATE tasks SET pomodoro_count = pomodoro_count + 1, updated_at = ?, dirty = 1 WHERE id = ?',
      [Date.now(), taskId]
    );
  }

  async markProjectsSynced(projects: FocusProject[]): Promise<void> {
    for (const project of projects) {
      await this.requireStore().executeSql(
        'UPDATE projects SET dirty = 0 WHERE id = ? AND updated_at = ?',
        [project.id, project.updatedAt]
      );
    }
  }

  async markTasksSynced(tasks: FocusTask[]): Promise<void> {
    for (const task of tasks) {
      await this.requireStore().executeSql(
        'UPDATE tasks SET dirty = 0 WHERE id = ? AND updated_at = ? AND client_request_id = ?',
        [task.id, task.updatedAt, this.taskClientRequestId(task)]
      );
    }
  }

  async markPomodorosSynced(records: PomodoroRecord[]): Promise<void> {
    for (const record of records) {
      await this.requireStore().executeSql(
        'UPDATE pomodoros SET dirty = 0 WHERE id = ? AND updated_at = ? AND client_request_id = ?',
        [record.id, record.updatedAt, this.pomodoroClientRequestId(record)]
      );
    }
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
      await this.upsertProject(project, true);
    }
    for (const task of tasks) {
      await this.upsertTask(task, true);
    }
    for (const record of records) {
      await this.requireStore().executeSql(
        'INSERT OR REPLACE INTO pomodoros (id, task_id, start_at, duration, completed, interrupt_reason, updated_at, client_request_id, dirty) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [record.id, record.taskId, record.startAt, record.duration, record.completed, record.interruptReason, Date.now(), this.pomodoroClientRequestId(record), 1]
      );
    }
  }

  private async seedStudyResourcesIfEmpty(): Promise<void> {
    const count: number = await this.countRows('study_resources');
    if (count > 0) {
      return;
    }
    const resources: StudyResource[] = createSeedStudyResources();
    for (const resource of resources) {
      await this.upsertStudyResource(resource);
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

  private async findPomodoroByClientRequestId(clientRequestId: string): Promise<PomodoroRecord | undefined> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, task_id, start_at, duration, completed, interrupt_reason, updated_at, client_request_id ' +
        'FROM pomodoros WHERE client_request_id = ? ORDER BY updated_at DESC, id ASC LIMIT 1',
      [clientRequestId]
    );
    try {
      if (resultSet.goToNextRow()) {
        return {
          id: this.longValue(resultSet, 'id'),
          taskId: this.longValue(resultSet, 'task_id'),
          startAt: this.longValue(resultSet, 'start_at'),
          duration: this.longValue(resultSet, 'duration'),
          completed: this.longValue(resultSet, 'completed'),
          interruptReason: this.stringValue(resultSet, 'interrupt_reason', ''),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          clientRequestId: this.stringValue(resultSet, 'client_request_id', '')
        };
      }
      return undefined;
    } finally {
      resultSet.close();
    }
  }

  private async findProjectById(projectId: number): Promise<FocusProject | undefined> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, name, color, icon, updated_at, is_deleted FROM projects WHERE id = ? LIMIT 1',
      [projectId]
    );
    try {
      if (resultSet.goToNextRow()) {
        return {
          id: this.longValue(resultSet, 'id'),
          name: this.stringValue(resultSet, 'name', '默认项目'),
          color: this.stringValue(resultSet, 'color', '#4F63D2'),
          icon: this.stringValue(resultSet, 'icon', 'P'),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          isDeleted: this.longValue(resultSet, 'is_deleted')
        };
      }
      return undefined;
    } finally {
      resultSet.close();
    }
  }

  private async findTaskByIdOrClientRequestId(taskId: number, clientRequestId: string): Promise<FocusTask | undefined> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, is_deleted, client_request_id, tags_json, subtasks_json ' +
        'FROM tasks WHERE id = ? OR client_request_id = ? ORDER BY updated_at DESC, id ASC LIMIT 1',
      [taskId, clientRequestId]
    );
    try {
      if (resultSet.goToNextRow()) {
        return {
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
          subtasks: this.parseStringArray(this.stringValue(resultSet, 'subtasks_json', '[]')),
          updatedAt: this.longValue(resultSet, 'updated_at'),
          isDeleted: this.longValue(resultSet, 'is_deleted'),
          clientRequestId: this.stringValue(resultSet, 'client_request_id', '')
        };
      }
      return undefined;
    } finally {
      resultSet.close();
    }
  }

  private async backfillTaskClientRequestIds(): Promise<void> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id FROM tasks WHERE client_request_id IS NULL OR client_request_id = ?',
      ['']
    );
    const ids: number[] = [];
    try {
      while (resultSet.goToNextRow()) {
        ids.push(this.longValue(resultSet, 'id'));
      }
    } finally {
      resultSet.close();
    }
    for (const id of ids) {
      await this.requireStore().executeSql(
        'UPDATE tasks SET client_request_id = ? WHERE id = ?',
        [`client-task-${id}`, id]
      );
    }
  }

  private async backfillPomodoroClientRequestIds(): Promise<void> {
    const resultSet: relationalStore.ResultSet = await this.query(
      'SELECT id, task_id, start_at, duration FROM pomodoros WHERE client_request_id IS NULL OR client_request_id = ?',
      ['']
    );
    const records: PomodoroRecord[] = [];
    try {
      while (resultSet.goToNextRow()) {
        records.push({
          id: this.longValue(resultSet, 'id'),
          taskId: this.longValue(resultSet, 'task_id'),
          startAt: this.longValue(resultSet, 'start_at'),
          duration: this.longValue(resultSet, 'duration'),
          completed: 0,
          interruptReason: ''
        });
      }
    } finally {
      resultSet.close();
    }
    for (const record of records) {
      await this.requireStore().executeSql(
        'UPDATE pomodoros SET client_request_id = ? WHERE id = ?',
        [this.pomodoroClientRequestId(record), record.id]
      );
    }
  }

  private taskToBucket(task: FocusTask, includeId: boolean, dirty: number = 1): relationalStore.ValuesBucket {
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
      is_deleted: task.isDeleted === undefined ? (task.status === TaskStatus.DELETED ? 1 : 0) : task.isDeleted,
      client_request_id: this.taskClientRequestId(task),
      tags_json: JSON.stringify(task.tags),
      subtasks_json: JSON.stringify(task.subtasks),
      dirty: dirty
    };
    if (includeId) {
      values.id = task.id;
    }
    return values;
  }

  private resourceToBucket(resource: StudyResource, includeId: boolean): relationalStore.ValuesBucket {
    const now: number = Date.now();
    const values: relationalStore.ValuesBucket = {
      title: resource.title,
      source_type: resource.sourceType,
      project_id: resource.projectId,
      linked_task_id: resource.linkedTaskId,
      content: resource.content,
      summary: resource.summary,
      summary_status: resource.summaryStatus === undefined ? ResourceSummaryStatus.PENDING : resource.summaryStatus,
      key_points_json: JSON.stringify(resource.keyPoints),
      tags_json: JSON.stringify(resource.tags),
      status: resource.status,
      created_at: resource.createdAt,
      updated_at: now,
      review_due_at: resource.reviewDueAt
    };
    if (includeId) {
      values.id = resource.id;
      values.updated_at = resource.updatedAt;
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

  private resourceSummaryStatus(rawStatus: number, summary: string): number {
    if (rawStatus > ResourceSummaryStatus.PENDING) {
      return rawStatus;
    }
    const trimmed: string = summary.trim();
    if (trimmed.length === 0 || trimmed.indexOf('待 AI') === 0) {
      return ResourceSummaryStatus.PENDING;
    }
    return ResourceSummaryStatus.EXTRACTED;
  }

  private pomodoroClientRequestId(record: PomodoroRecord): string {
    if (record.clientRequestId !== undefined && record.clientRequestId.trim().length > 0) {
      return record.clientRequestId.trim();
    }
    return `local-pomo-${record.id}-${record.taskId}-${record.startAt}-${record.duration}`;
  }

  private taskClientRequestId(task: FocusTask): string {
    if (task.clientRequestId !== undefined && task.clientRequestId.trim().length > 0) {
      return task.clientRequestId.trim();
    }
    return `client-task-${task.id}`;
  }
}

export const focusDatabase: FocusDatabase = new FocusDatabase();
