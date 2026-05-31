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
  outdoor: '室外.mp3',
  ocean: '海边.mp3',
  cricket: '虫鸣.mp3'
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
      this.player.fdSrc = fd;
      this.player.loop = true;
      await this.player.prepare();
      await this.player.play();
      this.isPlaying = true;
      console.info(`[FocusAmbient] Playing ${fileName}`);
    } catch (err) {
      console.error(`[FocusAmbient] Failed to play ${fileName}: ${JSON.stringify(err)}`);
      this.isPlaying = false;
    }
  }

  async stop(): Promise<void> {
    if (this.player !== undefined) {
      try {
        await this.player.stop();
        await this.player.release();
      } catch (err) {
        console.error(`[FocusAmbient] Failed to stop: ${JSON.stringify(err)}`);
      }
      this.player = undefined;
    }
    this.isPlaying = false;
    this.currentType = 'none';
  }

  getCurrentType(): AmbientType {
    return this.currentType;
  }

  getIsPlaying(): boolean {
    return this.isPlaying;
  }
}

export const focusAmbientService: FocusAmbientService = new FocusAmbientService();
