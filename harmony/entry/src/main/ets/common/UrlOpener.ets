import { Want, common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

/*
 * Opens an external https URL in the system browser, the HarmonyOS equivalent
 * of the Android CustomTabURLOpener / ACTION_VIEW intent used for docs, licence
 * and privacy links. HarmonyOS has no Custom Tabs, so this hands off to the
 * default browser ability via an implicit Want.
 */
export class UrlOpener {
  static open(context: common.UIAbilityContext, url: string): void {
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want).catch((err: Object) => {
      console.error(`[NetBird] failed to open ${url}: ${JSON.stringify(err)}`);
      promptAction.showToast({ message: `No browser available to open ${url}` });
    });
  }
}
