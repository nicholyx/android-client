import { common } from '@kit.AbilityKit';
import { ToggleRow, SectionHeader } from '../components/SettingRows';
import { EngineManager } from '../engine/EngineManager';
import { AdvancedSettings } from '../model/Settings';
import { ThemeMode } from '../common/Constants';
import { ThemeUtil } from '../common/ThemeUtil';

/*
 * Advanced / Network & Security — the ArkUI equivalent of AdvancedFragment.
 * Pre-shared key, Rosenpass, the disable-* network flags, force-relay and the
 * theme-mode picker. Local @State mirrors the persisted AdvancedSettings; every
 * change is written back through the EngineManager so a reconnect picks it up.
 */
@Component
export struct AdvancedPage {
  @StorageLink('nb_theme_mode') themeMode: ThemeMode = ThemeMode.SYSTEM;

  @State presharedKey: string = '';
  @State rosenpassEnabled: boolean = false;
  @State rosenpassPermissive: boolean = false;
  @State disableClientRoutes: boolean = false;
  @State disableServerRoutes: boolean = false;
  @State disableDns: boolean = false;
  @State disableFirewall: boolean = false;
  @State disableIpv6: boolean = false;
  @State allowSsh: boolean = false;
  @State blockInbound: boolean = false;
  @State forceRelay: boolean = false;
  @State traceLog: boolean = false;

  aboutToAppear(): void {
    const s: AdvancedSettings = EngineManager.getInstance().advanced();
    this.presharedKey = s.presharedKey;
    this.rosenpassEnabled = s.rosenpassEnabled;
    this.rosenpassPermissive = s.rosenpassPermissive;
    this.disableClientRoutes = s.disableClientRoutes;
    this.disableServerRoutes = s.disableServerRoutes;
    this.disableDns = s.disableDns;
    this.disableFirewall = s.disableFirewall;
    this.disableIpv6 = s.disableIpv6;
    this.allowSsh = s.allowSsh;
    this.blockInbound = s.blockInbound;
    this.forceRelay = s.forceRelay;
    this.traceLog = s.traceLog;
  }

  private persist(): void {
    const s: AdvancedSettings = new AdvancedSettings();
    s.presharedKey = this.presharedKey;
    s.rosenpassEnabled = this.rosenpassEnabled;
    s.rosenpassPermissive = this.rosenpassPermissive;
    s.disableClientRoutes = this.disableClientRoutes;
    s.disableServerRoutes = this.disableServerRoutes;
    s.disableDns = this.disableDns;
    s.disableFirewall = this.disableFirewall;
    s.disableIpv6 = this.disableIpv6;
    s.allowSsh = this.allowSsh;
    s.blockInbound = this.blockInbound;
    s.forceRelay = this.forceRelay;
    s.traceLog = this.traceLog;
    EngineManager.getInstance().saveAdvanced(s);
  }

  @Builder
  ThemeOption(label: Resource, mode: ThemeMode) {
    Text(label)
      .fontSize(14)
      .fontColor(this.themeMode === mode ? $r('app.color.white') : $r('app.color.nb_txt'))
      .backgroundColor(this.themeMode === mode ? $r('app.color.nb_orange') : Color.Transparent)
      .borderRadius(6)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.themeMode = mode;
        EngineManager.getInstance().setThemeMode(mode);
        ThemeUtil.apply(getContext(this) as common.UIAbilityContext, mode);
      })
  }

  /* 本 SDK（5.0.1）的 NavDestination.title 不接受 Resource，用局部 @Builder
   * 渲染 $r 并显式给出 CustomTitle 必需的 height（此版 SDK 为必填字段）。 */
  @Builder
  DestTitle() {
    Text($r('app.string.menu_advanced'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          SectionHeader({ title: $r('app.string.advanced_section_presharedkey') })
          Row() {
            TextInput({ placeholder: 'Add a pre-shared key', text: this.presharedKey })
              .layoutWeight(1)
              .height(44)
              .backgroundColor($r('app.color.nb_gray_bg'))
              .fontColor($r('app.color.nb_txt'))
              .onChange((value: string) => {
                this.presharedKey = value;
              })
            Button($r('app.string.advanced_save'))
              .height(44)
              .backgroundColor($r('app.color.nb_orange'))
              .fontColor($r('app.color.white'))
              .margin({ left: 8 })
              .onClick(() => this.persist())
          }
          .width('100%')
          .padding({ left: 20, right: 20 })

          Text($r('app.string.advanced_details'))
            .fontSize(12)
            .fontColor($r('app.color.nb_txt_light'))
            .width('100%')
            .padding({ left: 20, right: 20, top: 8 })

          SectionHeader({ title: $r('app.string.advanced_section_rosenpass') })
          ToggleRow({
            title: $r('app.string.advanced_rosenpass'),
            isOn: $rosenpassEnabled,
            onToggle: () => this.persist()
          })
          ToggleRow({
            title: $r('app.string.advanced_rosenpass_permissive'),
            isOn: $rosenpassPermissive,
            onToggle: () => this.persist()
          })

          SectionHeader({ title: $r('app.string.advanced_title_network_security') })
          ToggleRow({ title: $r('app.string.advanced_disable_client_routes'), isOn: $disableClientRoutes, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_disable_server_routes'), isOn: $disableServerRoutes, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_disable_dns'), isOn: $disableDns, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_disable_firewall'), isOn: $disableFirewall, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_disable_ipv6'), isOn: $disableIpv6, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_allow_ssh'), isOn: $allowSsh, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_block_inbound'), isOn: $blockInbound, onToggle: () => this.persist() })
          ToggleRow({ title: $r('app.string.advanced_force_relay_conn'), isOn: $forceRelay, onToggle: () => this.persist() })

          SectionHeader({ title: $r('app.string.advanced_section_appearance') })
          Text($r('app.string.advanced_theme_title'))
            .fontSize(15)
            .fontColor($r('app.color.nb_txt'))
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 8 })
          Row({ space: 8 }) {
            this.ThemeOption($r('app.string.advanced_theme_system'), ThemeMode.SYSTEM)
            this.ThemeOption($r('app.string.advanced_theme_light'), ThemeMode.LIGHT)
            this.ThemeOption($r('app.string.advanced_theme_dark'), ThemeMode.DARK)
          }
          .width('90%')
          .padding(4)
          .backgroundColor($r('app.color.nb_segment_track'))
          .borderRadius(8)
          .margin({ bottom: 12 })

          SectionHeader({ title: $r('app.string.troubleshoot_section_logging') })
          ToggleRow({ title: $r('app.string.advanced_tracelog'), isOn: $traceLog, onToggle: () => this.persist() })

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
