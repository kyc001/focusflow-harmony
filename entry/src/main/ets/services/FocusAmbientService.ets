import media from '@ohos.multimedia.media';
import { common } from '@kit.AbilityKit';

export type AmbientType = 'none' | 'outdoor' | 'ocean' | 'cricket';

export interface AmbientOption {
  id: AmbientType;
  label: string;
  description: string;
}

interface AmbientFileMap {
  none: string;
  outdoor: string;
  ocean: string;
  cricket: string;
}

const AMBIENT_FILES: AmbientFileMap = {
  none: '',
  outdoor: 'outdoor.mp3',
  ocean: 'ocean.mp3',
  cricket: 'cricket.mp3'
};

export const AMBIENT_OPTIONS: AmbientOption[] = [
  { id: 'ocean', label: '海边', description: '稳定海浪声' },
  { id: 'outdoor', label: '室外', description: '轻环境底噪' },
  { id: 'cricket', label: '虫鸣', description: '夜间低频陪伴' },
  { id: 'none', label: '关闭', description: '安静专注' }
];

export function normalizeAmbientType(value: string): AmbientType {
  if (value === 'outdoor' || value === '室外' || value === '雨声' || value === '咖啡馆' || value === '白噪声') {
    return 'outdoor';
  }
  if (value === 'ocean' || value === '海边') {
    return 'ocean';
  }
  if (value === 'cricket' || value === '虫鸣' || value === '键盘') {
    return 'cricket';
  }
  return 'none';
}

export function ambientDisplayName(value: string): string {
  const type: AmbientType = normalizeAmbientType(value);
  const option: AmbientOption | undefined = AMBIENT_OPTIONS.find((item: AmbientOption) => item.id === type);
  return option === undefined ? '关闭' : option.label;
}

function ambientFileName(type: AmbientType): string {
  if (type === 'outdoor') {
    return AMBIENT_FILES.outdoor;
  }
  if (type === 'ocean') {
    return AMBIENT_FILES.ocean;
  }
  if (type === 'cricket') {
    return AMBIENT_FILES.cricket;
  }
  return AMBIENT_FILES.none;
}

export class FocusAmbientService {
  private player?: media.AVPlayer;
  private currentType: AmbientType = 'none';
  private isPlaying: boolean = false;
  private currentContext?: common.UIAbilityContext;
  private currentFileName: string = '';

  async play(type: AmbientType | string, context: common.UIAbilityContext): Promise<void> {
    const normalizedType: AmbientType = normalizeAmbientType(type);
    if (normalizedType === 'none') {
      await this.stop();
      return;
    }
    if (this.isPlaying && this.currentType === normalizedType) {
      return;
    }
    await this.stop();
    this.currentType = normalizedType;
    const fileName: string = ambientFileName(normalizedType);
    if (fileName.length === 0) {
      return;
    }
    try {
      this.player = await media.createAVPlayer();
      this.player.on('stateChange', (state: string) => {
        console.info(`[FocusAmbient] AVPlayer state: ${state}`);
      });
      this.player.on('error', (err: Error) => {
        console.error(`[FocusAmbient] AVPlayer error: ${JSON.stringify(err)}`);
      });
      const fd = context.resourceManager.getRawFdSync(fileName);
      this.currentContext = context;
      this.currentFileName = fileName;
      this.player.fdSrc = {
        fd: fd.fd,
        offset: fd.offset,
        length: fd.length
      };
      await this.waitForPlayerState('initialized');
      await this.player.prepare();
      await this.waitForPlayerState('prepared');
      this.player.loop = true;
      await this.player.play();
      this.isPlaying = true;
      console.info(`[FocusAmbient] Playing ${fileName}`);
    } catch (err) {
      console.error(`[FocusAmbient] Failed to play ${fileName}: ${JSON.stringify(err)}`);
      this.isPlaying = false;
      await this.releasePlayer();
    }
  }

  async stop(): Promise<void> {
    await this.releasePlayer();
    this.isPlaying = false;
    this.currentType = 'none';
  }

  private async releasePlayer(): Promise<void> {
    if (this.player !== undefined) {
      try {
        await this.player.stop();
      } catch (err) {
        console.warn(`[FocusAmbient] Failed to stop player: ${JSON.stringify(err)}`);
      }
      try {
        await this.player.release();
      } catch (err) {
        console.error(`[FocusAmbient] Failed to release player: ${JSON.stringify(err)}`);
      }
      this.player = undefined;
    }
    if (this.currentContext !== undefined && this.currentFileName.length > 0) {
      try {
        this.currentContext.resourceManager.closeRawFdSync(this.currentFileName);
      } catch (err) {
        console.warn(`[FocusAmbient] Failed to close raw fd ${this.currentFileName}: ${JSON.stringify(err)}`);
      }
      this.currentContext = undefined;
      this.currentFileName = '';
    }
  }

  private async waitForPlayerState(targetState: media.AVPlayerState): Promise<void> {
    const player: media.AVPlayer | undefined = this.player;
    if (player === undefined || player.state === targetState) {
      return;
    }
    await new Promise<void>((resolve, reject) => {
      let timerId: number = -1;
      const onStateChange = (state: media.AVPlayerState) => {
        if (state === targetState) {
          cleanup();
          resolve();
        } else if (state === 'error' || state === 'released') {
          cleanup();
          reject(new Error(`AVPlayer reached ${state} before ${targetState}`));
        }
      };
      const cleanup = () => {
        if (timerId >= 0) {
          clearTimeout(timerId);
        }
        player.off('stateChange', onStateChange);
      };
      timerId = setTimeout(() => {
        cleanup();
        reject(new Error(`Timed out waiting for AVPlayer ${targetState}, current=${player.state}`));
      }, 3000);
      player.on('stateChange', onStateChange);
      onStateChange(player.state);
    });
  }

  getCurrentType(): AmbientType {
    return this.currentType;
  }

  getIsPlaying(): boolean {
    return this.isPlaying;
  }
}

export const focusAmbientService: FocusAmbientService = new FocusAmbientService();
