import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { ThemeMode } from './Constants';

/*
 * Applies the user's theme selection to the whole application, the HarmonyOS
 * analogue of the Android AppCompatDelegate.setDefaultNightMode() call the
 * ThemePickerSheet makes. Colour resources resolve from base/ or dark/ based
 * on the mode set here, so every screen follows automatically.
 */
export class ThemeUtil {
  static apply(context: common.UIAbilityContext, mode: ThemeMode): void {
    let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (mode === ThemeMode.LIGHT) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === ThemeMode.DARK) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    try {
      context.getApplicationContext().setColorMode(colorMode);
    } catch (err) {
      console.error(`[NetBird] failed to set color mode: ${JSON.stringify(err)}`);
    }
  }
}
