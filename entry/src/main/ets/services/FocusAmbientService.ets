import media from '@ohos.multimedia.media';
import { common } from '@kit.AbilityKit';

export type AmbientType = 'none' | 'outdoor' | 'ocean' | 'cricket';

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

  async play(type: AmbientType, context: common.UIAbilityContext): Promise<void> {
    if (type === 'none') {
      await this.stop();
      return;
    }
    if (this.isPlaying && this.currentType === type) {
      return;
    }
    await this.stop();
    this.currentType = type;
    const fileName: string = ambientFileName(type);
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
