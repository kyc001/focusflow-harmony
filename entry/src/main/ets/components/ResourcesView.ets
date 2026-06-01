import { focusStore } from '../services/FocusStore';
import {
  ACCENT,
  ACCENT_SOFT,
  BORDER_SOFT,
  CARD_GLASS,
  CARD_GLASS_BLUR,
  CARD_SHADOW,
  CARD_SHADOW_STRONG,
  CARD_SOFT,
  DEEP_2,
  DEEP_4,
  GLOW_BLUE,
  GRADIENT_ACCENT_END,
  GRADIENT_ACCENT_START,
  GRADIENT_PRIMARY_START,
  GRADIENT_SUCCESS_END,
  GRADIENT_SUCCESS_START,
  RADIUS_XL,
  SHADOW_FLOAT_COLOR,
  SHADOW_FLOAT_OFFSET_X,
  SHADOW_FLOAT_OFFSET_Y,
  SHADOW_FLOAT_RADIUS,
  SUCCESS,
  SUCCESS_SOFT,
  SURFACE_ALT,
  TEXT_DIM,
  TEXT_MAIN,
  TEXT_MUTED,
  TEXT_SUB,
  VIOLET,
  VIOLET_SOFT
} from '../utils/FocusDesignTokens';
import {
  FocusProject,
  ResourceInsight,
  ResourceSummaryStatus,
  StudyResource,
  StudyResourceStatus
} from '../models/FocusModels';
import { EmptyState, FocusSmallUiAsset } from './FocusVisuals';

const DEFAULT_RESOURCE_INSIGHT: ResourceInsight = {
  source: '未提炼',
  summary: '选择一份资料后，可使用远程 AI 生成摘要、要点和下一步任务。',
  keyPoints: ['配置远程 AI', '选择学习资料', '生成专注任务'],
  nextTaskTitle: '等待 AI 提炼资料',
  estimatedMinutes: 25,
  generatedAt: 0
};

@Component
export struct ResourcesView {
  @Prop resources: StudyResource[] = [];
  @Prop resourceWorkspace: string = 'library';
  @Prop showArchivedResources: boolean = false;
  @Prop selectedResourceId: number = 0;
  @Prop resourceFilterProjectId: number = 0;
  @Prop resourceType: string = 'note';
  @Prop selectedResourceProjectId: number = 0;
  @Prop newResourceTitle: string = '';
  @Prop newResourceContent: string = '';
  @Prop pickedFileUri: string = '';
  @Prop resourceLoading: boolean = false;
  @Prop resourceMessage: string = '';
  @Prop latestResourceInsight: ResourceInsight = DEFAULT_RESOURCE_INSIGHT;
  @Prop remoteAiReady: boolean = false;
  @Prop remoteAiEnabled: boolean = false;
  @Prop activeResourceCount: number = 0;
  @Prop archivedResourceCount: number = 0;
  @Prop extractedResourceCount: number = 0;
  @Prop showHero: boolean = true;
  @Prop showFlowHint: boolean = true;

  onWorkspaceChange: (mode: string) => void = () => {};
  onTitleChange: (value: string) => void = () => {};
  onContentChange: (value: string) => void = () => {};
  onResourceTypeChange: (type: string) => void = () => {};
  onProjectChange: (projectId: number) => void = () => {};
  onAddResource: () => void = () => {};
  onPickFile: () => void = () => {};
  onClearPickedFile: () => void = () => {};
  onSavePickedFile: () => void = () => {};
  onExtractResource: (resourceId: number) => void = () => {};
  onCreateTaskFromResource: (resourceId: number) => void = () => {};
  onShowArchivedChange: (showArchived: boolean) => void = () => {};
  onFilterProjectChange: (projectId: number) => void = () => {};
  onSelectResource: (resourceId: number) => void = () => {};
  onArchiveResource: (resourceId: number) => void = () => {};
  onRestoreResource: (resourceId: number) => void = () => {};
  taskTitleForResource: (taskId: number) => string = () => '未绑定任务';

  build() {
    Column() {
      if (this.showHero) {
        this.ResourceHeroCard()
      }
      this.ResourceWorkspaceTabs()
      if (this.showFlowHint) {
        this.ResourceFlowHint()
      }
      this.ResourceWorkspaceContent()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private resourceTypeName(type: string): string {
    if (type === 'link') {
      return '网页链接';
    }
    if (type === 'file') {
      return '本地文件';
    }
    if (type === 'pdf') {
      return '论文/PDF';
    }
    if (type === 'courseware') {
      return '课件';
    }
    return '笔记';
  }

  private resourceWorkspaceName(mode: string): string {
    if (mode === 'memo') {
      return '备忘录';
    }
    if (mode === 'upload') {
      return '文件导入';
    }
    if (mode === 'insight') {
      return 'AI 提炼';
    }
    return '资料库';
  }

  private resourceWorkspaceHint(): string {
    if (this.resourceWorkspace === 'memo') {
      return '快速写入课堂灵感、待查问题和复习提醒。';
    }
    if (this.resourceWorkspace === 'upload') {
      return '选择本地文档后，保存文件引用和自己的备注。';
    }
    if (this.resourceWorkspace === 'insight') {
      return '选择资料后提炼摘要、要点，并生成下一段专注任务。';
    }
    return '浏览活跃资料、筛选项目，并把资料沉淀成可复用素材。';
  }

  private resourceWorkspaceIcon(): string {
    if (this.resourceWorkspace === 'memo') {
      return 'quick';
    }
    if (this.resourceWorkspace === 'upload') {
      return 'sync';
    }
    if (this.resourceWorkspace === 'insight') {
      return 'ai';
    }
    return 'local';
  }

  private selectedResource(): StudyResource | undefined {
    return this.resources.find((resource: StudyResource) => resource.id === this.selectedResourceId);
  }

  private selectedResourceStatusText(): string {
    const resource: StudyResource | undefined = this.selectedResource();
    return resource === undefined ? '未选择资料' : `已选：${resource.title}`;
  }

  private resourceAiStatusText(): string {
    if (this.remoteAiReady) {
      return '远程 AI 已就绪';
    }
    if (this.remoteAiEnabled) {
      return '远程 AI 缺少 Key';
    }
    return '远程 AI 待开启';
  }

  private selectedResourceTitle(): string {
    const resource: StudyResource | undefined = this.selectedResource();
    return resource === undefined ? '尚未选择资料' : resource.title;
  }

  private selectedResourceSummary(): string {
    const resource: StudyResource | undefined = this.selectedResource();
    if (resource === undefined) {
      return '从左侧资料列表选择一份内容，或先添加课程笔记、论文摘录、网页链接。';
    }
    return this.resourceHasExtractedInsight(resource) && resource.summary.length > 0 ?
      resource.summary :
      this.latestResourceInsight.summary;
  }

  private selectedResourceKeyPoints(): string[] {
    const resource: StudyResource | undefined = this.selectedResource();
    if (resource === undefined) {
      return this.latestResourceInsight.keyPoints;
    }
    return this.resourceHasExtractedInsight(resource) && resource.keyPoints.length > 0 ?
      resource.keyPoints :
      this.latestResourceInsight.keyPoints;
  }

  private resourceHasExtractedInsight(resource: StudyResource): boolean {
    if (resource.summaryStatus === ResourceSummaryStatus.EXTRACTED) {
      return true;
    }
    return resource.summaryStatus === undefined && resource.summary.length > 0 && resource.summary !== '待 AI';
  }

  private resourceInsightSourceLabel(): string {
    if (this.latestResourceInsight.source === '远程 AI' || this.latestResourceInsight.source === '已保存提炼') {
      return this.latestResourceInsight.source;
    }
    return '待提炼';
  }

  private resourcePreview(content: string): string {
    if (content.length <= 88) {
      return content;
    }
    return `${content.substring(0, 88)}...`;
  }

  private filteredResources(): StudyResource[] {
    return this.resources.filter((resource: StudyResource) => {
      const statusMatched: boolean = this.showArchivedResources ?
        resource.status === StudyResourceStatus.ARCHIVED :
        resource.status === StudyResourceStatus.ACTIVE;
      const projectMatched: boolean = this.resourceFilterProjectId === 0 || resource.projectId === this.resourceFilterProjectId;
      return statusMatched && projectMatched;
    });
  }

  private fileNameFromUri(uri: string): string {
    const clean: string = uri.split('?')[0];
    const index: number = clean.lastIndexOf('/');
    const name: string = index >= 0 && index < clean.length - 1 ? clean.substring(index + 1) : clean;
    return name.length > 0 ? name.replace(/%20/g, ' ') : '导入文件';
  }

  private pickedFileName(): string {
    return this.pickedFileUri.length === 0 ? '尚未选择文件' : this.fileNameFromUri(this.pickedFileUri);
  }

  private pickedFilePreview(): string {
    if (this.pickedFileUri.length === 0) {
      return '选择 PDF、课件、Markdown 或文档后，会保存为资料记录。';
    }
    if (this.pickedFileUri.length <= 72) {
      return this.pickedFileUri;
    }
    return `${this.pickedFileUri.substring(0, 72)}...`;
  }

  @Builder
  private ResourceWorkspaceContent() {
    if (this.resourceWorkspace === 'memo') {
      this.ResourceQuickAddCard()
    } else if (this.resourceWorkspace === 'upload') {
      this.ResourceImportCard()
    } else if (this.resourceWorkspace === 'insight') {
      GridRow({
        columns: { xs: 4, sm: 4, md: 8, lg: 12 },
        gutter: { x: 12, y: 12 }
      }) {
        GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 7 } }) {
          this.ResourceAiCard()
        }
        GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 5 } }) {
          this.ResourceList()
        }
      }
    } else {
      this.ResourceFilterBar()
      this.ResourceList()
    }
  }

  @Builder
  private ResourceFlowHint() {
    Row() {
      FocusSmallUiAsset({ variant: this.resourceWorkspaceIcon(), assetSize: 36 })
      Column() {
        Text(this.resourceWorkspaceName(this.resourceWorkspace))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Text(this.resourceWorkspaceHint())
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, right: 8 })
      Column() {
        Text(this.selectedResourceStatusText())
          .fontSize(10)
          .fontColor(this.selectedResource() === undefined ? TEXT_MUTED : ACCENT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.resourceAiStatusText())
          .fontSize(10)
          .fontColor(this.remoteAiReady ? SUCCESS : TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .width(112)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(CARD_GLASS)
    .border({ width: 1, color: '#CCFFFFFF' })
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0B14260F', offsetX: 0, offsetY: 4 })
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 12 })
  }

  @Builder
  private ResourceHeroCard() {
    Column() {
      Row() {
        Column() {
          Text('学习资料库')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(`${this.resourceWorkspaceName(this.resourceWorkspace)} · 自定义学习素材`)
            .fontSize(11)
            .fontColor('#B0FFFFFF')
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.focus_ui_sync_bridge'))
          .resourceMicroAssetStyle(70)
          .borderRadius(18)
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('把备忘录、链接、课件和本地文件拆成几个可进入的工作区')
        .fontSize(13)
        .fontColor('#D8FFFFFF')
        .lineHeight(20)
        .margin({ top: 12 })

      Row() {
        this.DarkHeroStat('活跃资料', `${this.activeResourceCount}`)
        Column()
          .width(1)
          .height(28)
          .backgroundColor('#1AFFFFFF')
        this.DarkHeroStat('已提炼', `${this.extractedResourceCount}`)
        Column()
          .width(1)
          .height(28)
          .backgroundColor('#1AFFFFFF')
        this.DarkHeroStat('已归档', `${this.archivedResourceCount}`)
      }
      .width('100%')
      .margin({ top: 18 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .linearGradient({
      angle: 160,
      colors: [[DEEP_2, 0.0], [DEEP_4, 1.0]]
    })
    .shadow({ radius: 30, color: CARD_SHADOW_STRONG, offsetX: 0, offsetY: 14 })
    .margin({ bottom: 12 })
  }

  @Builder
  private DarkHeroStat(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text(label)
        .fontSize(10)
        .fontColor('#99FFFFFF')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 4, right: 4 })
  }

  @Builder
  private ResourceWorkspaceTabs() {
    Row() {
      this.ResourceWorkspaceTab('library', '资料库', '查看')
      this.ResourceWorkspaceTab('memo', '备忘录', '写入')
      this.ResourceWorkspaceTab('upload', '文件', '导入')
      this.ResourceWorkspaceTab('insight', '提炼', 'AI')
    }
    .width('100%')
    .padding(5)
    .backgroundColor('#CCFFFFFF')
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
    .border({ width: 1, color: '#80FFFFFF' })
    .borderRadius(16)
    .shadow({ radius: 18, color: CARD_SHADOW, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 12 })
  }

  @Builder
  private ResourceWorkspaceTab(mode: string, title: string, caption: string) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontWeight(this.resourceWorkspace === mode ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.resourceWorkspace === mode ? '#FFFFFF' : TEXT_SUB)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(caption)
        .fontSize(9)
        .fontColor(this.resourceWorkspace === mode ? '#CCFFFFFF' : TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.resourceWorkspace === mode ? ACCENT : Color.Transparent)
    .borderRadius(12)
    .onClick(() => {
      this.onWorkspaceChange(mode);
    })
  }

  @Builder
  private ResourceQuickAddCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_quick_add'))
          .resourceMicroAssetStyle(44)
          .margin({ right: 10 })
        Column() {
          Text(this.resourceWorkspace === 'memo' ? '写一条备忘录' : '新增资料')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text(this.resourceWorkspace === 'memo' ? '把资料库当作课程备忘录使用' : '粘贴课堂笔记、论文摘录或链接说明')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      TextInput({ placeholder: '资料标题，例如：操作系统进程调度笔记', text: this.newResourceTitle })
        .height(42)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 14 })
        .onChange((value: string) => {
          this.onTitleChange(value);
        })

      TextInput({ placeholder: this.resourceWorkspace === 'memo' ? '今天想到的知识点、待查问题、复习提醒...' : '正文摘录 / 链接说明 / 复习材料要点', text: this.newResourceContent })
        .height(this.resourceWorkspace === 'memo' ? 112 : 76)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.onContentChange(value);
        })

      Text('类型')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SUB)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12, bottom: 8 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(['note', 'link', 'courseware', 'pdf'], (type: string) => {
          Text(this.resourceTypeName(type))
            .height(30)
            .fontSize(12)
            .fontWeight(this.resourceType === type ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.resourceType === type ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.resourceType === type ? ACCENT : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.onResourceTypeChange(type);
            })
        }, (type: string) => type)
      }
      .width('100%')

      this.ProjectSelector('项目')

      Button(this.resourceWorkspace === 'memo' ? '保存备忘录' : '保存到资料库')
        .height(40)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(ACCENT)
        .linearGradient({
          angle: 90,
          colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
        })
        .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 })
        .onClick(() => {
          this.onAddResource();
        })
    }
    .resourceCardStyle()
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private ResourceImportCard() {
    Column() {
      Row() {
        Image($r('app.media.focus_ui_sync_bridge'))
          .resourceMicroAssetStyle(44)
          .margin({ right: 10 })
        Column() {
          Text('导入本地文件')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_MAIN)
          Text('选择文档后保存文件引用和自己的备注')
            .fontSize(11)
            .fontColor(TEXT_MUTED)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Column() {
        Text(this.pickedFileName())
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.pickedFileUri.length > 0 ? TEXT_MAIN : TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.pickedFilePreview())
          .fontSize(11)
          .fontColor(TEXT_MUTED)
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
      }
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_SOFT)
      .border({ width: 1, color: BORDER_SOFT })
      .borderRadius(14)
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 14 })

      Row() {
        Button('选择文件')
          .height(38)
          .layoutWeight(1)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ACCENT)
          .linearGradient({
            angle: 90,
            colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
          })
          .shadow({ radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2 })
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => {
            this.onPickFile();
          })
        Button('清空')
          .height(38)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(12)
          .padding({ left: 14, right: 14 })
          .margin({ left: 8 })
          .onClick(() => {
            this.onClearPickedFile();
          })
      }
      .width('100%')
      .margin({ top: 12 })

      TextInput({ placeholder: '资料标题，可用文件名或课程主题', text: this.newResourceTitle })
        .height(42)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.onTitleChange(value);
        })

      TextInput({ placeholder: '补充备注：文件用途、章节、要复习的问题', text: this.newResourceContent })
        .height(84)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .border({ width: 1, color: BORDER_SOFT })
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.onContentChange(value);
        })

      this.ProjectSelector('归属项目')

      Button('保存文件资料')
        .height(40)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.pickedFileUri.length > 0 ? SUCCESS : SURFACE_ALT)
        .fontColor(this.pickedFileUri.length > 0 ? '#FFFFFF' : TEXT_MUTED)
        .borderRadius(12)
        .margin({ top: 8 })
        .onClick(() => {
          this.onSavePickedFile();
        })

      Text(this.resourceMessage)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 10 })
    }
    .resourceCardStyle()
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private ProjectSelector(label: string) {
    Text(label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(TEXT_SUB)
      .alignSelf(ItemAlign.Start)
      .margin({ top: 8, bottom: 8 })
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(focusStore.projects, (project: FocusProject) => {
        Text(project.name)
          .height(30)
          .fontSize(12)
          .fontWeight(this.selectedResourceProjectId === project.id ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedResourceProjectId === project.id ? '#FFFFFF' : TEXT_SUB)
          .backgroundColor(this.selectedResourceProjectId === project.id ? project.color : SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .margin({ right: 6, bottom: 6 })
          .onClick(() => {
            this.onProjectChange(project.id);
          })
      }, (project: FocusProject) => project.id.toString())
    }
    .width('100%')
  }

  @Builder
  private ResourceAiCard() {
    Column() {
      Row() {
        Stack() {
          Image($r('app.media.focus_ui_ai_orb'))
            .resourceMicroAssetStyle(66)
            .borderRadius(18)
          Text('AI')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .backgroundColor('#660E1626')
            .borderRadius(8)
        }
        .margin({ right: 12 })
        Column() {
          Row() {
            Text('资料提炼')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_MAIN)
            Blank()
            Text(this.resourceInsightSourceLabel())
              .fontSize(10)
              .fontColor(this.latestResourceInsight.source === '远程 AI' ? VIOLET : TEXT_MUTED)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.latestResourceInsight.source === '远程 AI' ? VIOLET_SOFT : SURFACE_ALT)
              .borderRadius(8)
          }
          .width('100%')
          Text(this.selectedResourceTitle())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_MAIN)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
          Text(this.resourceAiStatusText())
            .fontSize(11)
            .fontColor(this.remoteAiReady ? SUCCESS : TEXT_MUTED)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.selectedResourceSummary())
        .fontSize(12)
        .fontColor(TEXT_SUB)
        .lineHeight(18)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding(12)
        .backgroundColor(CARD_SOFT)
        .borderRadius(12)
        .width('100%')
        .margin({ top: 14 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.selectedResourceKeyPoints(), (point: string) => {
          Text(point)
            .fontSize(11)
            .fontColor(TEXT_SUB)
            .backgroundColor(SURFACE_ALT)
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .margin({ right: 6, top: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }, (point: string) => point)
      }
      .width('100%')
      .margin({ top: 6 })

      Row() {
        this.ResourceMetric('建议任务', this.latestResourceInsight.nextTaskTitle, 'marker')
        Column()
          .width(1)
          .height(38)
          .backgroundColor(BORDER_SOFT)
          .margin({ left: 10, right: 10 })
        this.ResourceMetric('预计', `${this.latestResourceInsight.estimatedMinutes} 分钟`, 'timer')
      }
      .width('100%')
      .margin({ top: 14 })

      Row() {
        Button(this.resourceLoading ? '提炼中' : 'AI 提炼')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.remoteAiReady ? GRADIENT_PRIMARY_START : ACCENT_SOFT)
          .linearGradient(this.remoteAiReady ? {
            angle: 90,
            colors: [[GRADIENT_ACCENT_START, 0.0], [GRADIENT_ACCENT_END, 1.0]]
          } : undefined)
          .fontColor(this.remoteAiReady ? '#FFFFFF' : ACCENT)
          .borderRadius(10)
          .shadow(this.remoteAiReady ? {
            radius: 8, color: GLOW_BLUE, offsetX: 0, offsetY: 2
          } : { radius: 0 })
          .onClick(() => {
            this.onExtractResource(this.selectedResourceId);
          })
        Button('生成任务')
          .height(34)
          .layoutWeight(1)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(GRADIENT_SUCCESS_START)
          .linearGradient({
            angle: 90,
            colors: [[GRADIENT_SUCCESS_START, 0.0], [GRADIENT_SUCCESS_END, 1.0]]
          })
          .fontColor('#FFFFFF')
          .borderRadius(10)
          .margin({ left: 8 })
          .shadow({ radius: 8, color: '#1A34D399', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.onCreateTaskFromResource(this.selectedResourceId);
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Text(this.resourceMessage)
        .fontSize(11)
        .fontColor(TEXT_MUTED)
        .lineHeight(16)
        .margin({ top: 10 })
    }
    .resourceCardStyle()
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private ResourceMetric(label: string, value: string, icon: string) {
    Row() {
      FocusSmallUiAsset({ variant: icon, assetSize: 28 })
      Column() {
        Text(label)
          .fontSize(10)
          .fontColor(TEXT_MUTED)
        Text(value)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
    }
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private ResourceFilterBar() {
    Column() {
      Row() {
        Text(this.showArchivedResources ? '归档资料' : '活跃资料')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Button(this.showArchivedResources ? '看活跃' : '看归档')
          .height(30)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(SURFACE_ALT)
          .fontColor(TEXT_SUB)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.onShowArchivedChange(!this.showArchivedResources);
          })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        Text('全部项目')
          .height(30)
          .fontSize(12)
          .fontWeight(this.resourceFilterProjectId === 0 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.resourceFilterProjectId === 0 ? '#FFFFFF' : TEXT_SUB)
          .backgroundColor(this.resourceFilterProjectId === 0 ? TEXT_MAIN : SURFACE_ALT)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .margin({ right: 6, top: 10 })
          .onClick(() => {
            this.onFilterProjectChange(0);
          })
        ForEach(focusStore.projects, (project: FocusProject) => {
          Text(project.name)
            .height(30)
            .fontSize(12)
            .fontWeight(this.resourceFilterProjectId === project.id ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.resourceFilterProjectId === project.id ? '#FFFFFF' : TEXT_SUB)
            .backgroundColor(this.resourceFilterProjectId === project.id ? project.color : SURFACE_ALT)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ right: 6, top: 10 })
            .onClick(() => {
              this.onFilterProjectChange(this.resourceFilterProjectId === project.id ? 0 : project.id);
            })
        }, (project: FocusProject) => project.id.toString())
      }
      .width('100%')
    }
    .resourceCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private ResourceList() {
    Column() {
      Row() {
        Text('资料清单')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_MAIN)
        Blank()
        Text(`${this.filteredResources().length} 项`)
          .fontSize(11)
          .fontColor(TEXT_MUTED)
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.filteredResources().length === 0) {
        EmptyState({ title: this.showArchivedResources ? '暂无归档资料' : '暂无匹配资料', caption: '添加一段课堂笔记或切换筛选条件。', variant: 'inbox' })
      } else {
        ForEach(this.filteredResources(), (resource: StudyResource) => {
          this.ResourceCard(resource)
        }, (resource: StudyResource) => resource.id.toString())
      }
    }
    .resourceCardStyle()
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
  }

  @Builder
  private ResourceCard(resource: StudyResource) {
    Column() {
      Row() {
        Column() {
          FocusSmallUiAsset({ variant: resource.sourceType === 'pdf' || resource.sourceType === 'file' ? 'bars' : resource.sourceType === 'link' ? 'sync' : 'local', assetSize: 42 })
        }
        .width(42)
        .height(42)
        .margin({ right: 10 })

        Column() {
          Row() {
            Text(resource.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(resource.status === StudyResourceStatus.ARCHIVED ? TEXT_MUTED : TEXT_MAIN)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.resourceTypeName(resource.sourceType))
              .fontSize(10)
              .fontColor(TEXT_MUTED)
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor(SURFACE_ALT)
              .borderRadius(7)
              .margin({ left: 8 })
          }
          .width('100%')

          Row() {
            this.ProjectPill(resource.projectId)
            Text('·')
              .fontSize(10)
              .fontColor(TEXT_DIM)
              .margin({ left: 8, right: 8 })
            Text(resource.linkedTaskId > 0 ? `已生成：${this.taskTitleForResource(resource.linkedTaskId)}` : '未生成任务')
              .fontSize(11)
              .fontColor(resource.linkedTaskId > 0 ? SUCCESS : TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .margin({ top: 5 })

          Text(this.resourceHasExtractedInsight(resource) && resource.summary.length > 0 ?
            resource.summary :
            this.resourcePreview(resource.content))
            .fontSize(12)
            .fontColor(TEXT_SUB)
            .lineHeight(18)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 7 })

          if (this.resourceHasExtractedInsight(resource) && resource.keyPoints.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(resource.keyPoints.slice(0, 3), (point: string) => {
                Text(point)
                  .fontSize(10)
                  .fontColor(TEXT_MUTED)
                  .backgroundColor(CARD_SOFT)
                  .borderRadius(7)
                  .padding({ left: 7, right: 7, top: 3, bottom: 3 })
                  .margin({ right: 5, top: 5 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }, (point: string) => point)
            }
            .width('100%')
          }

          Row() {
            Button(this.selectedResourceId === resource.id ? '已选择' : '选择')
              .height(28)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.selectedResourceId === resource.id ? ACCENT : SURFACE_ALT)
              .fontColor(this.selectedResourceId === resource.id ? '#FFFFFF' : TEXT_SUB)
              .borderRadius(8)
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                this.onSelectResource(resource.id);
              })
            if (resource.status === StudyResourceStatus.ARCHIVED) {
              Button('恢复')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(SUCCESS_SOFT)
                .fontColor(SUCCESS)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 5 })
                .onClick(() => {
                  this.onRestoreResource(resource.id);
                })
            } else {
              Button('提炼')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(ACCENT_SOFT)
                .fontColor(ACCENT)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 5 })
                .onClick(() => {
                  this.onSelectResource(resource.id);
                  this.onExtractResource(resource.id);
                })
              Button('归档')
                .height(28)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(Color.Transparent)
                .fontColor(TEXT_MUTED)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .margin({ left: 5 })
                .onClick(() => {
                  this.onArchiveResource(resource.id);
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding({ left: 13, right: 10, top: 12, bottom: 12 })
    .backgroundColor(this.selectedResourceId === resource.id ? ACCENT_SOFT : '#FFFFFF')
    .borderRadius(14)
    .border({
      width: { left: 3 },
      color: { left: resource.status === StudyResourceStatus.ARCHIVED ? TEXT_DIM : focusStore.getProject(resource.projectId).color }
    })
    .margin({ bottom: 8 })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  private ProjectPill(projectId: number) {
    Row() {
      Column()
        .width(7)
        .height(7)
        .borderRadius(3.5)
        .backgroundColor(focusStore.getProject(projectId).color)
      Text(focusStore.getProject(projectId).name)
        .fontSize(11)
        .fontColor(TEXT_SUB)
        .margin({ left: 6 })
    }
  }
}

@Extend(Column)
function resourceCardStyle() {
  .width('100%')
  .padding(20)
  .backgroundColor(CARD_GLASS)
  .backdropBlur(CARD_GLASS_BLUR)
  .borderRadius(RADIUS_XL)
  .border({ width: 1, color: BORDER_SOFT })
  .shadow({ radius: SHADOW_FLOAT_RADIUS, color: SHADOW_FLOAT_COLOR, offsetX: SHADOW_FLOAT_OFFSET_X, offsetY: SHADOW_FLOAT_OFFSET_Y })
}

@Extend(Image)
function resourceMicroAssetStyle(size: number) {
  .width(size)
  .height(size)
  .objectFit(ImageFit.Cover)
  .borderRadius(Math.round(size / 4))
}
