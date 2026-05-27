import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { createDefaultSettings } from '../data/SeedData';
import { FocusSettings } from '../models/FocusModels';

const PREF_NAME: string = 'focus_settings';
const MIN_FOCUS_MINUTES: number = 10;
const MAX_FOCUS_MINUTES: number = 60;
const MIN_SHORT_BREAK_MINUTES: number = 3;
const MAX_SHORT_BREAK_MINUTES: number = 15;
const MIN_LONG_BREAK_MINUTES: number = 10;
const MAX_LONG_BREAK_MINUTES: number = 30;

export class FocusSettingsService {
  private pref?: preferences.Preferences;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
    } catch (err) {
      this.pref = undefined;
    }
  }

  defaultSettings(): FocusSettings {
    return createDefaultSettings();
  }

  async loadSettings(): Promise<FocusSettings> {
    const defaults: FocusSettings = this.defaultSettings();
    if (this.pref === undefined) {
      return defaults;
    }
    try {
      const settings: FocusSettings = {
        focusMinutes: (await this.pref.get('timer.focusMinutes', defaults.focusMinutes)) as number,
        shortBreakMinutes: (await this.pref.get('timer.shortBreakMinutes', defaults.shortBreakMinutes)) as number,
        longBreakMinutes: (await this.pref.get('timer.longBreakMinutes', defaults.longBreakMinutes)) as number,
        themeColor: (await this.pref.get('appearance.themeColor', defaults.themeColor)) as string,
        noise: (await this.pref.get('audio.noise', defaults.noise)) as string,
        notificationEnabled: (await this.pref.get('notification.enabled', defaults.notificationEnabled)) as boolean
      };
      return this.normalize(settings);
    } catch (err) {
      return defaults;
    }
  }

  async saveSettings(settings: FocusSettings): Promise<FocusSettings> {
    const normalized: FocusSettings = this.normalize(settings);
    if (this.pref === undefined) {
      return normalized;
    }
    try {
      await this.pref.put('timer.focusMinutes', normalized.focusMinutes);
      await this.pref.put('timer.shortBreakMinutes', normalized.shortBreakMinutes);
      await this.pref.put('timer.longBreakMinutes', normalized.longBreakMinutes);
      await this.pref.put('appearance.themeColor', normalized.themeColor);
      await this.pref.put('audio.noise', normalized.noise);
      await this.pref.put('notification.enabled', normalized.notificationEnabled);
      await this.pref.flush();
    } catch (err) {
      return normalized;
    }
    return normalized;
  }

  normalize(settings: FocusSettings): FocusSettings {
    const defaults: FocusSettings = this.defaultSettings();
    return {
      focusMinutes: this.clampMinutes(settings.focusMinutes, MIN_FOCUS_MINUTES, MAX_FOCUS_MINUTES, defaults.focusMinutes),
      shortBreakMinutes: this.clampMinutes(
        settings.shortBreakMinutes,
        MIN_SHORT_BREAK_MINUTES,
        MAX_SHORT_BREAK_MINUTES,
        defaults.shortBreakMinutes
      ),
      longBreakMinutes: this.clampMinutes(
        settings.longBreakMinutes,
        MIN_LONG_BREAK_MINUTES,
        MAX_LONG_BREAK_MINUTES,
        defaults.longBreakMinutes
      ),
      themeColor: settings.themeColor.trim().length === 0 ? defaults.themeColor : settings.themeColor.trim(),
      noise: settings.noise.trim().length === 0 ? defaults.noise : settings.noise.trim(),
      notificationEnabled: settings.notificationEnabled
    };
  }

  private clampMinutes(value: number, min: number, max: number, fallback: number): number {
    if (value !== value) {
      return fallback;
    }
    return Math.max(min, Math.min(max, Math.round(value)));
  }
}

export const focusSettingsService: FocusSettingsService = new FocusSettingsService();
