/**
 * One menu line: Thai original + English translation.
 */
export interface MenuDish {
  id: string;
  thaiText: string;
  englishText: string;
}

export interface OcrLine {
  text: string;
  top: number;
  left: number;
}

export interface TranslationConfig {
  apiKey: string;
  endpoint: string;
}

export interface TtsConfig {
  apiKey: string;
  endpoint: string;
  languageCode: string;
}

export const DEFAULT_TRANSLATION_CONFIG: TranslationConfig = {
  apiKey: '',
  endpoint: 'https://translation.googleapis.com/language/translate/v2'
};

export const DEFAULT_TTS_CONFIG: TtsConfig = {
  apiKey: '',
  endpoint: 'https://texttospeech.googleapis.com/v1/text:synthesize',
  languageCode: 'th-TH'
};
