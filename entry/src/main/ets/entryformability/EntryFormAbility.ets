import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

interface FocusFormData {
  title: string;
  subtitle: string;
  progress: string;
  task1: string;
  task2: string;
  task3: string;
  isCompact: boolean;
}

const DEFAULT_FORM_DATA: FocusFormData = {
  title: '知序 今日',
  subtitle: '本地学习闭环',
  progress: '4/6 番茄',
  task1: 'HW4 报告复盘',
  task2: '数据库索引总结',
  task3: '协程 Demo 排练',
  isCompact: false
};

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    const dimension: number = want.parameters?.['ohos.extension.form.dimension'] as number ?? 2;
    const data: FocusFormData = {
      title: DEFAULT_FORM_DATA.title,
      subtitle: DEFAULT_FORM_DATA.subtitle,
      progress: DEFAULT_FORM_DATA.progress,
      task1: DEFAULT_FORM_DATA.task1,
      task2: DEFAULT_FORM_DATA.task2,
      task3: DEFAULT_FORM_DATA.task3,
      isCompact: dimension === 2
    };
    return formBindingData.createFormBindingData(data);
  }

  onUpdateForm(formId: string) {
    console.info(`update form ${formId}`);
  }

  onFormEvent(formId: string, message: string) {
    console.info(`form event ${formId}: ${message}`);
  }

  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }
}
