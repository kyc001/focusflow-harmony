import notificationManager from '@ohos.notificationManager';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';

export class FocusNotificationService {
  static async requestPermission(): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification();
      return true;
    } catch (err) {
      console.error(`request notification permission failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  static async publishBasic(title: string, text: string): Promise<void> {
    try {
      await notificationManager.publish({
        id: Date.now() % 100000,
        notificationSlotType: notificationManager.SlotType.CONTENT_INFORMATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: text
          }
        }
      });
    } catch (err) {
      console.error(`publish notification failed: ${JSON.stringify(err)}`);
    }
  }
}

export class FocusBackgroundService {
  private static delayId: number = -1;

  static startPomodoroGuard(): string {
    try {
      const info: backgroundTaskManager.DelaySuspendInfo = backgroundTaskManager.requestSuspendDelay('Focus pomodoro running', () => {
        console.info('focus suspend delay callback');
      });
      FocusBackgroundService.delayId = info.requestId;
      return `后台延迟任务已申请，剩余 ${info.actualDelayTime} ms`;
    } catch (err) {
      console.error(`request background task failed: ${JSON.stringify(err)}`);
      return '后台任务申请失败，页面计时仍可继续';
    }
  }

  static stopPomodoroGuard(): string {
    if (FocusBackgroundService.delayId < 0) {
      return '暂无后台任务';
    }
    try {
      backgroundTaskManager.cancelSuspendDelay(FocusBackgroundService.delayId);
      FocusBackgroundService.delayId = -1;
      return '后台任务已释放';
    } catch (err) {
      console.error(`cancel background task failed: ${JSON.stringify(err)}`);
      return '后台任务释放失败';
    }
  }
}

