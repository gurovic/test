import { MenuDish } from '../model/MenuDish';
import { menuViewModel } from '../viewmodel/MenuViewModel';
import { cameraCaptureService } from '../services/CameraCaptureService';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State dishes: MenuDish[] = [];
  @State isScanning: boolean = false;
  @State isSpeaking: boolean = false;
  @State selectedDishId: string = '';
  @State statusMessage: string = '';
  @State apiKey: string = '';

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    menuViewModel.setContext(this.context);
  }

  build() {
    Column() {
      this.buildHeader()

      if (this.dishes.length === 0) {
        this.buildEmptyState()
      } else {
        this.buildDishList()
      }

      this.buildScanButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.surface'))
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
  }

  @Builder
  buildHeader() {
    Column({ space: 8 }) {
      Text('Thai Menu Order')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text($r('app.string.tap_to_speak'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      if (this.apiKey.length === 0) {
        TextInput({ placeholder: 'Google Cloud API key (Translate + TTS)' })
          .width('100%')
          .height(44)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.apiKey = value.trim();
            menuViewModel.setGoogleApiKey(this.apiKey);
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 16 })
  }

  @Builder
  buildEmptyState() {
    Column({ space: 12 }) {
      Text('📷')
        .fontSize(48)

      Text($r('app.string.no_dishes'))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildDishList() {
    List({ space: 10 }) {
      ForEach(this.dishes, (dish: MenuDish) => {
        ListItem() {
          this.buildDishCard(dish)
        }
      }, (dish: MenuDish) => dish.id)
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Off)
  }

  @Builder
  buildDishCard(dish: MenuDish) {
    Row() {
      Column({ space: 4 }) {
        Text(dish.englishText)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Text(dish.thaiText)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.selectedDishId === dish.id && this.isSpeaking ? '🔊' : '▶')
        .fontSize(22)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedDishId === dish.id ? $r('app.color.primary_light') : Color.White)
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.onDishTap(dish);
    })
  }

  @Builder
  buildScanButton() {
    Button(this.isScanning ? $r('app.string.scanning') : $r('app.string.scan_menu'))
      .width('100%')
      .height(52)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .backgroundColor($r('app.color.primary'))
      .enabled(!this.isScanning)
      .margin({ top: 12 })
      .onClick(() => {
        this.onScanTap();
      })
  }

  private async onScanTap(): Promise<void> {
    if (this.isScanning) {
      return;
    }

    this.isScanning = true;
    this.statusMessage = '';

    try {
      const pixelMap = await cameraCaptureService.capturePhoto(this.context);
      if (!pixelMap) {
        return;
      }

      const result = await menuViewModel.scanMenuFromPixelMap(pixelMap);
      this.dishes = result;

      if (result.length === 0) {
        promptAction.showToast({ message: $r('app.string.error_scan') });
      }
    } catch (error) {
      promptAction.showToast({
        message: $r('app.string.error_scan')
      });
      console.error(`Scan error: ${JSON.stringify(error)}`);
    } finally {
      this.isScanning = false;
    }
  }

  private async onDishTap(dish: MenuDish): Promise<void> {
    if (this.isSpeaking) {
      await menuViewModel.stopSpeaking();
    }

    this.selectedDishId = dish.id;
    this.isSpeaking = true;

    try {
      await menuViewModel.speakDish(dish);
    } catch (error) {
      promptAction.showToast({ message: 'Could not play Thai pronunciation' });
      console.error(`TTS error: ${JSON.stringify(error)}`);
    } finally {
      this.isSpeaking = false;
    }
  }
}
