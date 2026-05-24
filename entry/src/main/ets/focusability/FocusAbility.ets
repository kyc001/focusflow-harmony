import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0001;

export default class FocusAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.parseWant(want);
    hilog.info(DOMAIN, 'FocusAbility', 'onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.parseWant(want);
    hilog.info(DOMAIN, 'FocusAbility', 'onNewWant');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/FocusSolo', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'FocusAbility', 'load FocusSolo failed: %{public}s', JSON.stringify(err));
      }
    });
  }

  private parseWant(want: Want): void {
    const params = want.parameters;
    if (params !== undefined && params['taskTitle'] !== undefined) {
      AppStorage.setOrCreate<string>('focus.taskTitle', params['taskTitle'] as string);
    }
    if (params !== undefined && params['taskId'] !== undefined) {
      AppStorage.setOrCreate<number>('focus.taskId', params['taskId'] as number);
    }
  }
}
