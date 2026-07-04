import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { OcrLine } from '../model/MenuDish';

const THAI_CHAR_PATTERN: RegExp = /[\u0E00-\u0E7F]/;

/**
 * On-device OCR via Core Vision Kit.
 * Note: built-in OCR may not include Thai on all devices — use CloudOcrService as fallback.
 */
export class OcrService {
  async recognizeFromPixelMap(pixelMap: image.PixelMap): Promise<string> {
    const visionInfo: textRecognition.VisionInfo = { pixelMap: pixelMap };
    const config: textRecognition.TextRecognitionConfiguration = {
      isDirectionDetectionSupported: true
    };

    try {
      const result = await textRecognition.recognizeText(visionInfo, config);
      return result.value ?? '';
    } catch (error) {
      const err = error as BusinessError;
      throw new Error(`OCR failed: ${err.code} ${err.message}`);
    }
  }

  /**
   * Split raw OCR text into candidate dish lines.
   * Filters price-only lines and lines without Thai script.
   */
  parseMenuLines(rawText: string): string[] {
    const lines = rawText
      .split(/\r?\n/)
      .map((line: string) => line.trim())
      .filter((line: string) => line.length > 0);

    return lines.filter((line: string) => {
      if (!THAI_CHAR_PATTERN.test(line)) {
        return false;
      }
      if (/^\d+([.,]\d+)?\s*(฿|baht|THB)?$/i.test(line)) {
        return false;
      }
      if (/^[\d\s.,฿\-–—]+$/.test(line)) {
        return false;
      }
      return true;
    });
  }

  /**
   * Structured lines from OCR blocks when the API returns geometry (future use).
   */
  sortLinesByPosition(lines: OcrLine[]): string[] {
    return lines
      .sort((a: OcrLine, b: OcrLine) => {
        if (Math.abs(a.top - b.top) < 20) {
          return a.left - b.left;
        }
        return a.top - b.top;
      })
      .map((line: OcrLine) => line.text.trim())
      .filter((text: string) => text.length > 0 && THAI_CHAR_PATTERN.test(text));
  }
}

export const ocrService = new OcrService();
