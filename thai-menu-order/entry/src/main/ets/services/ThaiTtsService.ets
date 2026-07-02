import { http } from '@kit.NetworkKit';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TtsConfig } from '../model/MenuDish';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

interface GoogleTtsResponse {
  audioContent?: string;
}

/**
 * Thai TTS via Google Cloud Text-to-Speech (or compatible API).
 * HarmonyOS Core Speech Kit does not support th-TH natively.
 */
export class ThaiTtsService {
  private config: TtsConfig;
  private avPlayer: media.AVPlayer | null = null;
  private isPlaying: boolean = false;
  private context: common.UIAbilityContext | null = null;

  constructor(config: TtsConfig) {
    this.config = config;
  }

  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  setApiKey(apiKey: string): void {
    this.config.apiKey = apiKey;
  }

  async speakThai(text: string): Promise<void> {
    if (!text || text.trim().length === 0) {
      return;
    }

    await this.stop();

    if (!this.config.apiKey) {
      console.warn('TTS API key not set');
      return;
    }

    const audioBase64 = await this.synthesize(text);
    await this.playBase64Mp3(audioBase64);
  }

  async stop(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.stop();
        await this.avPlayer.release();
      } catch (_e) {
        // ignore
      }
      this.avPlayer = null;
    }
    this.isPlaying = false;
  }

  isBusy(): boolean {
    return this.isPlaying;
  }

  private async synthesize(text: string): Promise<string> {
    const url = `${this.config.endpoint}?key=${encodeURIComponent(this.config.apiKey)}`;
    const body = JSON.stringify({
      input: { text: text },
      voice: {
        languageCode: this.config.languageCode,
        name: 'th-TH-Standard-A'
      },
      audioConfig: {
        audioEncoding: 'MP3',
        speakingRate: 0.9,
        pitch: 0
      }
    });

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 20000,
        readTimeout: 20000
      });

      if (response.responseCode !== 200) {
        throw new Error(`TTS HTTP ${response.responseCode}`);
      }

      const parsed = JSON.parse(response.result as string) as GoogleTtsResponse;
      if (!parsed.audioContent) {
        throw new Error('Empty TTS audio');
      }
      return parsed.audioContent;
    } finally {
      httpRequest.destroy();
    }
  }

  private async playBase64Mp3(base64Audio: string): Promise<void> {
    if (!this.context) {
      throw new Error('UIAbilityContext not set for TTS playback');
    }

    const helper = new util.Base64Helper();
    const audioBytes = helper.decodeSync(base64Audio, util.Type.MIME);
    const filePath = `${this.context.cacheDir}/tts_${Date.now()}.mp3`;

    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, audioBytes.buffer);
    fileIo.closeSync(file);

    this.avPlayer = await media.createAVPlayer();
    this.isPlaying = true;

    return new Promise<void>((resolve, reject) => {
      const player = this.avPlayer;
      if (!player) {
        reject(new Error('AVPlayer not created'));
        return;
      }

      player.on('stateChange', async (state: string) => {
        if (state === 'initialized') {
          await player.prepare();
          await player.play();
        }
        if (state === 'completed' || state === 'stopped') {
          this.isPlaying = false;
          resolve();
        }
      });

      player.on('error', (err: BusinessError) => {
        this.isPlaying = false;
        reject(new Error(`Playback error: ${err.message}`));
      });

      player.url = filePath;
    });
  }
}
