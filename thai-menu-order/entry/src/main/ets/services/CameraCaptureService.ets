import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/**
 * Captures a still photo from the system camera picker and returns PixelMap for OCR.
 */
export class CameraCaptureService {
  async capturePhoto(context: common.UIAbilityContext): Promise<image.PixelMap | null> {
    try {
      const pickerResult = await cameraPicker.pick(
        context,
        [cameraPicker.PickerMediaType.PHOTO],
        {
          cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
        }
      );

      if (!pickerResult || !pickerResult.resultUri) {
        return null;
      }

      return await this.uriToPixelMap(pickerResult.resultUri);
    } catch (error) {
      console.error(`Camera capture failed: ${JSON.stringify(error)}`);
      return null;
    }
  }

  private async uriToPixelMap(uri: string): Promise<image.PixelMap> {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const imageSource = image.createImageSource(file.fd);
    const pixelMap = await imageSource.createPixelMap();
    fileIo.closeSync(file);
    return pixelMap;
  }
}

export const cameraCaptureService = new CameraCaptureService();
