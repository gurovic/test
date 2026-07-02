import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TranslationConfig } from '../model/MenuDish';

interface GoogleTranslateResponse {
  data?: {
    translations?: Array<{ translatedText: string }>;
  };
}

/**
 * Cloud translation th → en.
 * Replace with Huawei ML Kit or DeepL if you prefer.
 */
export class TranslationService {
  private config: TranslationConfig;

  constructor(config: TranslationConfig) {
    this.config = config;
  }

  setApiKey(apiKey: string): void {
    this.config.apiKey = apiKey;
  }

  async translateThaiToEnglish(text: string): Promise<string> {
    if (!text || text.trim().length === 0) {
      return '';
    }

    if (!this.config.apiKey) {
      return `[EN] ${text}`;
    }

    const url = `${this.config.endpoint}?key=${encodeURIComponent(this.config.apiKey)}`;
    const body = JSON.stringify({
      q: text,
      source: 'th',
      target: 'en',
      format: 'text'
    });

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      if (response.responseCode !== 200) {
        throw new Error(`Translation HTTP ${response.responseCode}`);
      }

      const parsed = JSON.parse(response.result as string) as GoogleTranslateResponse;
      const translated = parsed.data?.translations?.[0]?.translatedText;
      return translated ?? text;
    } catch (error) {
      const err = error as BusinessError;
      throw new Error(`Translation failed: ${err.message ?? String(error)}`);
    } finally {
      httpRequest.destroy();
    }
  }

  async translateBatch(thaiLines: string[]): Promise<Map<string, string>> {
    const result = new Map<string, string>();
    for (const line of thaiLines) {
      const english = await this.translateThaiToEnglish(line);
      result.set(line, english);
    }
    return result;
  }
}
