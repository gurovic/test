import { MenuDish, DEFAULT_TRANSLATION_CONFIG, DEFAULT_TTS_CONFIG } from '../model/MenuDish';
import { ocrService } from './OcrService';
import { TranslationService } from './TranslationService';
import { ThaiTtsService } from './ThaiTtsService';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';

/**
 * Orchestrates scan → parse → translate → speak flow.
 */
export class MenuViewModel {
  private translationService: TranslationService;
  private ttsService: ThaiTtsService;
  private context: common.UIAbilityContext | null = null;

  constructor() {
    this.translationService = new TranslationService(DEFAULT_TRANSLATION_CONFIG);
    this.ttsService = new ThaiTtsService(DEFAULT_TTS_CONFIG);
  }

  setContext(context: common.UIAbilityContext): void {
    this.context = context;
    this.ttsService.setContext(context);
  }

  setGoogleApiKey(apiKey: string): void {
    this.translationService.setApiKey(apiKey);
    this.ttsService.setApiKey(apiKey);
  }

  async scanMenuFromPixelMap(pixelMap: image.PixelMap): Promise<MenuDish[]> {
    const rawText = await ocrService.recognizeFromPixelMap(pixelMap);
    const thaiLines = ocrService.parseMenuLines(rawText);

    if (thaiLines.length === 0) {
      return [];
    }

    const translations = await this.translationService.translateBatch(thaiLines);
    const dishes: MenuDish[] = [];

    thaiLines.forEach((thaiText: string, index: number) => {
      dishes.push({
        id: `dish_${index}_${Date.now()}`,
        thaiText: thaiText,
        englishText: translations.get(thaiText) ?? thaiText
      });
    });

    return dishes;
  }

  async speakDish(dish: MenuDish): Promise<void> {
    await this.ttsService.speakThai(dish.thaiText);
  }

  async stopSpeaking(): Promise<void> {
    await this.ttsService.stop();
  }
}

export const menuViewModel = new MenuViewModel();
