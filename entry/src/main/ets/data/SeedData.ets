import {
  FocusProject,
  FocusSettings,
  FocusTask,
  ForestPlant,
  PomodoroRecord,
  StudyResource,
  StudyResourceStatus,
  TaskStatus
} from '../models/FocusModels';

const ONE_HOUR: number = 60 * 60 * 1000;
const ONE_DAY: number = 24 * ONE_HOUR;

export function createSeedProjects(): FocusProject[] {
  return [
    { id: 1, name: '数据库', color: '#4F7BFF', icon: 'DB' },
    { id: 2, name: '科研', color: '#12A87D', icon: 'R' },
    { id: 3, name: '协程演讲', color: '#F59E0B', icon: 'P' },
    { id: 4, name: '移动开发', color: '#E4566E', icon: 'A' }
  ];
}

export function createSeedTasks(): FocusTask[] {
  const now: number = Date.now();
  return [
    {
      id: 1,
      title: '完成 HW4 实验报告复盘',
      note: '整理接口、页面和测试截图，作为期末答辩素材。',
      projectId: 4,
      priority: 0,
      dueAt: now + 4 * ONE_HOUR,
      status: TaskStatus.TODO,
      pomodoroCount: 1,
      createdAt: now - ONE_DAY,
      completedAt: 0,
      tags: ['报告', '高优'],
      subtasks: ['补充架构图', '标注关键代码']
    },
    {
      id: 2,
      title: '数据库索引章节总结',
      note: '复习 B+ 树、聚簇索引和查询优化。',
      projectId: 1,
      priority: 1,
      dueAt: now + ONE_DAY,
      status: TaskStatus.TODO,
      pomodoroCount: 2,
      createdAt: now - 2 * ONE_DAY,
      completedAt: 0,
      tags: ['期末', '笔记'],
      subtasks: ['画一张思维导图']
    },
    {
      id: 3,
      title: '读论文 Related Work',
      note: '提炼 3 篇相关工作，用一句话写贡献。',
      projectId: 2,
      priority: 2,
      dueAt: now + 2 * ONE_DAY,
      status: TaskStatus.TODO,
      pomodoroCount: 0,
      createdAt: now - ONE_DAY,
      completedAt: 0,
      tags: ['科研'],
      subtasks: ['Paper A', 'Paper B', 'Paper C']
    },
    {
      id: 4,
      title: '协程演讲 Demo 排练',
      note: '控制在 6 分钟内，突出挂起、恢复、调度三个点。',
      projectId: 3,
      priority: 0,
      dueAt: now + 3 * ONE_DAY,
      status: TaskStatus.TODO,
      pomodoroCount: 0,
      createdAt: now,
      completedAt: 0,
      tags: ['展示'],
      subtasks: ['检查录屏', '压缩 PPT']
    },
    {
      id: 5,
      title: '整理知序 App 答辩话术',
      note: '突出服务卡片、一多布局、后台任务、本地数据闭环。',
      projectId: 4,
      priority: 1,
      dueAt: now + 5 * ONE_HOUR,
      status: TaskStatus.DONE,
      pomodoroCount: 1,
      createdAt: now - 2 * ONE_DAY,
      completedAt: now - 2 * ONE_HOUR,
      tags: ['答辩'],
      subtasks: ['列功能清单']
    }
  ];
}

export function createSeedPomodoros(): PomodoroRecord[] {
  const now: number = Date.now();
  return [
    { id: 1, taskId: 1, startAt: now - 6 * ONE_DAY, duration: 1500, completed: 1, interruptReason: '' },
    { id: 2, taskId: 2, startAt: now - 5 * ONE_DAY, duration: 1500, completed: 1, interruptReason: '' },
    { id: 3, taskId: 2, startAt: now - 4 * ONE_DAY, duration: 1200, completed: 0, interruptReason: '临时消息' },
    { id: 4, taskId: 5, startAt: now - 2 * ONE_DAY, duration: 1500, completed: 1, interruptReason: '' },
    { id: 5, taskId: 1, startAt: now - ONE_DAY, duration: 1500, completed: 1, interruptReason: '' }
  ];
}

export function createSeedStudyResources(): StudyResource[] {
  const now: number = Date.now();
  return [
    {
      id: 1,
      title: '鸿蒙期末项目需求记录',
      sourceType: 'note',
      projectId: 4,
      linkedTaskId: 1,
      content: '老师要求课程项目一般要有 4-5 个页面，每个页面都要有实在功能。如果能连接服务器，服务器端再连接数据库，会更好。',
      summary: '项目需要体现多页面、真实功能、本地数据库、可选服务器和课程知识点。',
      keyPoints: ['4-5 个真实页面', '本地数据库闭环', '可选服务器加分'],
      tags: ['课程要求', '答辩'],
      status: StudyResourceStatus.ACTIVE,
      createdAt: now - 2 * ONE_DAY,
      updatedAt: now - 2 * ONE_DAY,
      reviewDueAt: now + ONE_DAY
    },
    {
      id: 2,
      title: '数据库复习资料',
      sourceType: 'courseware',
      projectId: 1,
      linkedTaskId: 2,
      content: '索引、事务、范式、SQL 查询优化是期末复习重点。需要把概念拆成可完成的小任务。',
      summary: '围绕数据库核心概念建立复习清单，并用番茄钟分段完成。',
      keyPoints: ['索引与查询优化', '事务 ACID', '范式设计'],
      tags: ['复习', '数据库'],
      status: StudyResourceStatus.ACTIVE,
      createdAt: now - ONE_DAY,
      updatedAt: now - ONE_DAY,
      reviewDueAt: now + 2 * ONE_DAY
    },
    {
      id: 3,
      title: '论文 Related Work 摘录',
      sourceType: 'pdf',
      projectId: 2,
      linkedTaskId: 3,
      content: '阅读相关工作时需要记录每篇论文的问题、方法、贡献和局限，并最终压缩成一段综述。',
      summary: '按问题、方法、贡献、局限四栏整理文献，避免只摘抄摘要。',
      keyPoints: ['问题定义', '方法贡献', '局限比较'],
      tags: ['论文', '科研'],
      status: StudyResourceStatus.ACTIVE,
      createdAt: now - 6 * ONE_HOUR,
      updatedAt: now - 6 * ONE_HOUR,
      reviewDueAt: now + 3 * ONE_DAY
    }
  ];
}

export function createDefaultSettings(): FocusSettings {
  return {
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    themeColor: '#2F6BFF',
    noise: '雨声',
    notificationEnabled: true
  };
}

export function createForestPlants(): ForestPlant[] {
  return [
    { id: 1, name: '晨光树苗', icon: 'Seed', unlockPomodoros: 1, unlockStreak: 0, color: '#78B159' },
    { id: 2, name: '银杏', icon: 'Ginkgo', unlockPomodoros: 3, unlockStreak: 1, color: '#E8B547' },
    { id: 3, name: '松树', icon: 'Pine', unlockPomodoros: 6, unlockStreak: 2, color: '#2F855A' },
    { id: 4, name: '蓝花楹', icon: 'Bloom', unlockPomodoros: 10, unlockStreak: 3, color: '#6D6AEF' },
    { id: 5, name: '红枫', icon: 'Maple', unlockPomodoros: 15, unlockStreak: 5, color: '#C2415D' },
    { id: 6, name: '知识森林', icon: 'Forest', unlockPomodoros: 25, unlockStreak: 7, color: '#0F766E' }
  ];
}
