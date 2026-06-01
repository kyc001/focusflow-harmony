import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { DEFAULT_FOCUS_FORM_DATA, FocusFormData, focusFormSnapshotService } from '../services/FocusFormSnapshotService';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    const dimension: number = want.parameters?.['ohos.extension.form.dimension'] as number ?? 2;
    return formBindingData.createFormBindingData(this.loadFormData(dimension === 2));
  }

  onUpdateForm(formId: string) {
    formProvider.updateForm(formId, formBindingData.createFormBindingData(this.loadFormData(false))).catch((err: Error) => {
      console.error(`update form ${formId} failed: ${JSON.stringify(err)}`);
    });
  }

  onFormEvent(formId: string, message: string) {
    console.info(`form event ${formId}: ${message}`);
  }

  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }

  private loadFormData(isCompact: boolean): FocusFormData {
    try {
      return focusFormSnapshotService.loadSnapshotSync(this.context, isCompact);
    } catch (err) {
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
  }
}
