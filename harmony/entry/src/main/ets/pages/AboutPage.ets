import { bundleManager, common } from '@kit.AbilityKit';
import { Urls } from '../common/Constants';
import { UrlOpener } from '../common/UrlOpener';

/*
 * About — the ArkUI equivalent of AboutFragment. The wordmark, the version,
 * links to the licence and privacy policy, and the copyright line.
 */
@Component
export struct AboutPage {
  private open(url: string): void {
    UrlOpener.open(getContext(this) as common.UIAbilityContext, url);
  }

  @State versionLabel: string = '';

  aboutToAppear(): void {
    // 版本号读自应用包信息，不再硬编码。
    try {
      const info: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const prefix: string =
        getContext(this).resourceManager.getStringSync($r('app.string.about_version').id);
      this.versionLabel = `${prefix}${info.versionName}`;
    } catch (err) {
      console.error(`[NetBird] read version failed: ${JSON.stringify(err)}`);
    }
  }

  /* 此 SDK（5.0.1）的 NavDestination 标题不接受 Resource，用局部 @Builder 渲染 $r。 */
  @Builder
  DestTitle() {
    Text($r('app.string.menu_about'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }

  build() {
    NavDestination() {
      Column() {
        Blank().height(48)

        Text('NetBird')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.nb_txt'))

        Text(this.versionLabel)
          .fontSize(14)
          .fontColor($r('app.color.nb_txt_light'))
          .margin({ top: 8 })

        Blank().height(32)

        Text($r('app.string.about_license'))
          .fontSize(15)
          .fontColor($r('app.color.nb_orange'))
          .decoration({ type: TextDecorationType.Underline })
          .padding(10)
          .onClick(() => this.open(Urls.LICENSE))

        Text($r('app.string.about_privacy_policy'))
          .fontSize(15)
          .fontColor($r('app.color.nb_orange'))
          .decoration({ type: TextDecorationType.Underline })
          .padding(10)
          .onClick(() => this.open(Urls.PRIVACY))

        Blank()

        Text($r('app.string.about_rights'))
          .fontSize(12)
          .fontColor($r('app.color.nb_txt_light'))
          .margin({ bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .title({ builder: this.DestTitle, height: TitleHeight.MainOnly })
    .backgroundColor($r('app.color.nb_bg'))
  }
}
