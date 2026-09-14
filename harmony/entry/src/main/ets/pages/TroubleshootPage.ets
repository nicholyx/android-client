import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { SectionHeader, ToggleRow } from '../components/SettingRows';
import { EngineManager } from '../engine/EngineManager';
import { AdvancedSettings } from '../model/Settings';

/*
 * Troubleshoot — the ArkUI equivalent of TroubleshootFragment. A logging toggle
 * for remote debug-bundle jobs and a debug-bundle section: anonymize switch plus
 * an upload action that asks the engine for a bundle key and surfaces it for
 * copying.
 */
@Component
export struct TroubleshootPage {
  @State allowRemoteJobs: boolean = false;
  @State anonymize: boolean = true;
  @State bundleKey: string = '';

  aboutToAppear(): void {
    this.allowRemoteJobs = EngineManager.getInstance().advanced().allowRemoteJobs;
  }

  private upload(): void {
    const key: string = EngineManager.getInstance().debugBundle(this.anonymize);
    this.bundleKey = key;
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, key);
    pasteboard.getSystemPasteboard().setData(data);
    promptAction.showToast({ message: 'Debug bundle key copied to clipboard' });
  }

  /* 本 SDK（5.0.1）的 NavDestination.title 不接受 Resource，用局部 @Builder
   * 渲染 $r 并显式给出 CustomTitle 必需的 height（此版 SDK 为必填字段）。 */
  @Builder
  DestTitle() {
    Text($r('app.string.menu_troubleshoot'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          SectionHeader({ title: $r('app.string.troubleshoot_section_logging') })
          ToggleRow({
            title: $r('app.string.troubleshoot_allow_remote_jobs'),
            subtitle: 'Lets your administrator request a debug bundle from this device.',
            isOn: $allowRemoteJobs,
            onToggle: (value: boolean) => {
              const s: AdvancedSettings = EngineManager.getInstance().advanced();
              s.allowRemoteJobs = value;
              EngineManager.getInstance().saveAdvanced(s);
            }
          })

          SectionHeader({ title: $r('app.string.troubleshoot_section_debug_bundle') })
          ToggleRow({ title: $r('app.string.troubleshoot_anonymize'), isOn: $anonymize })

          Row() {
            Button($r('app.string.troubleshoot_debug_bundle'))
              .width('90%')
              .height(48)
              .backgroundColor($r('app.color.nb_orange'))
              .fontColor($r('app.color.white'))
              .onClick(() => this.upload())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 12 })

          if (this.bundleKey.length > 0) {
            Text(this.bundleKey)
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor($r('app.color.nb_txt_light'))
              .width('90%')
              .textAlign(TextAlign.Center)
              .margin({ top: 12 })
          }

          Blank().height(24)
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title({ builder: this.DestTitle, height: TitleHeight.MainOnly })
    .backgroundColor($r('app.color.nb_bg'))
  }
}
