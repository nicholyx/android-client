import { EngineManager } from '../engine/EngineManager';
import { Urls } from '../common/Constants';
import { promptAction } from '@kit.ArkUI';

/*
 * First-run onboarding — the ArkUI equivalent of FirstInstallFragment. Shown as
 * a full-screen overlay by Index until the user commits to NetBird Cloud or a
 * self-hosted management server, at which point it clears the first-launch flag.
 */
@Component
export struct FirstInstallPage {
  @State isCloud: boolean = true;
  @State url: string = '';

  private continueSetup(): void {
    if (!this.isCloud && this.url.trim().length === 0) {
      promptAction.showToast({ message: 'Please enter a valid URL, e.g. https://netbird.selfhosted.com:443' });
      return;
    }
    const serverUrl: string = this.isCloud ? Urls.CLOUD_MANAGEMENT : this.url.trim();
    const manager: EngineManager = EngineManager.getInstance();
    // Point the default profile at the chosen server, then dismiss onboarding.
    manager.switchProfile('default');
    manager.clearFirstLaunch();
    promptAction.showToast({ message: `Using ${serverUrl}` });
  }

  build() {
    Column() {
      Blank().height(80)

      Text('NetBird')
        .fontSize(38)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.nb_txt'))

      Text($r('app.string.firstinstall_setup_description'))
        .fontSize(15)
        .fontColor($r('app.color.nb_txt_light'))
        .textAlign(TextAlign.Center)
        .width('80%')
        .margin({ top: 16 })

      Blank().height(48)

      Row() {
        Text($r('app.string.profiles_dialog_server_cloud'))
          .fontSize(15)
          .fontColor(this.isCloud ? $r('app.color.white') : $r('app.color.nb_txt'))
          .backgroundColor(this.isCloud ? $r('app.color.nb_orange') : Color.Transparent)
          .borderRadius(6)
          .padding({ top: 10, bottom: 10 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.isCloud = true;
          })
        Text($r('app.string.profiles_dialog_server_self_hosted'))
          .fontSize(15)
          .fontColor(!this.isCloud ? $r('app.color.white') : $r('app.color.nb_txt'))
          .backgroundColor(!this.isCloud ? $r('app.color.nb_orange') : Color.Transparent)
          .borderRadius(6)
          .padding({ top: 10, bottom: 10 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.isCloud = false;
          })
      }
      .width('80%')
      .padding(4)
      .backgroundColor($r('app.color.nb_segment_track'))
      .borderRadius(8)

      if (!this.isCloud) {
        TextInput({ placeholder: 'https://netbird.selfhosted.com:443', text: this.url })
          .width('80%')
          .height(48)
          .backgroundColor($r('app.color.info_row_bg'))
          .fontColor($r('app.color.nb_txt'))
          .margin({ top: 20 })
          .onChange((value: string) => {
            this.url = value;
          })
      }

      Blank()

      Button($r('app.string.firstinstall_continue'))
        .id('first_install_continue')
        .width('80%')
        .height(52)
        .backgroundColor($r('app.color.nb_orange'))
        .fontColor($r('app.color.white'))
        .fontSize(16)
        .margin({ bottom: 48 })
        .onClick(() => this.continueSetup())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.nb_bg_home'))
    .alignItems(HorizontalAlign.Center)
  }
}
