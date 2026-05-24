import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

interface FocusFormData {
  title: string;
  subtitle: string;
  progress: string;
  task1: string;
  task2: string;
  task3: string;
}

const DEFAULT_FORM_DATA: FocusFormData = {
  title: 'Focus 今日',
  subtitle: '本地学习闭环',
  progress: '4/6 番茄',
  task1: 'HW4 报告复盘',
  task2: '数据库索引总结',
  task3: '协程 Demo 排练'
};

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    return formBindingData.createFormBindingData(DEFAULT_FORM_DATA);
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

