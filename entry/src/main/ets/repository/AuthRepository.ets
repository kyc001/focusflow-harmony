import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

export interface LoginProfile {
  userId: number;
  username: string;
  nickname: string;
  token: string;
  guest: boolean;
}

const PREF_NAME: string = 'focus_auth';

export class AuthRepository {
  private pref?: preferences.Preferences;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    this.pref = await preferences.getPreferences(context, PREF_NAME);
  }

  async currentProfile(): Promise<LoginProfile | null> {
    if (this.pref === undefined) {
      return null;
    }
    const token: string = (await this.pref.get('auth.token', '')) as string;
    if (token.length === 0) {
      return null;
    }
    const username: string = (await this.pref.get('auth.username', 'guest')) as string;
    const nickname: string = (await this.pref.get('auth.nickname', '本地用户')) as string;
    const guest: boolean = (await this.pref.get('auth.guest', true)) as boolean;
    const profile: LoginProfile = {
      userId: guest ? 0 : 1,
      username: username,
      nickname: nickname,
      token: token,
      guest: guest
    };
    return profile;
  }

  async loginLocal(username: string, nickname: string): Promise<LoginProfile> {
    const safeUsername: string = username.trim().length === 0 ? 'local' : username.trim();
    const safeNickname: string = nickname.trim().length === 0 ? safeUsername : nickname.trim();
    const profile: LoginProfile = {
      userId: 1,
      username: safeUsername,
      nickname: safeNickname,
      token: `local-${Date.now()}`,
      guest: false
    };
    await this.save(profile);
    return profile;
  }

  async guest(): Promise<LoginProfile> {
    const profile: LoginProfile = {
      userId: 0,
      username: 'guest',
      nickname: '游客模式',
      token: `guest-${Date.now()}`,
      guest: true
    };
    await this.save(profile);
    return profile;
  }

  async logout(): Promise<void> {
    if (this.pref === undefined) {
      return;
    }
    await this.pref.delete('auth.token');
    await this.pref.flush();
  }

  private async save(profile: LoginProfile): Promise<void> {
    if (this.pref === undefined) {
      return;
    }
    await this.pref.put('auth.token', profile.token);
    await this.pref.put('auth.username', profile.username);
    await this.pref.put('auth.nickname', profile.nickname);
    await this.pref.put('auth.guest', profile.guest);
    await this.pref.flush();
  }
}

export const authRepository: AuthRepository = new AuthRepository();

