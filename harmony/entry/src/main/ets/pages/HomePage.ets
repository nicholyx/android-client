import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { ConnectionState, ConnectionStateMapper } from '../model/ConnectionState';
import { Resource as NetResource } from '../model/Resource';
import { Profile } from '../model/Profile';
import { EngineManager } from '../engine/EngineManager';
import { Keys } from '../common/Constants';
import { Formatters } from '../common/Formatters';
import { Routes, AppNav } from '../common/NavRouter';

/*
 * Home screen — the ArkUI equivalent of HomeFragment/fragment_home.xml.
 * Profile chip on top, the NetBird wordmark, the connect toggle, the connection
 * status, the tunnel address with an expandable copy panel, and the session /
 * exit-node rows pinned to the bottom.
 */
@Component
export struct HomePage {
  @StorageLink(Keys.CONNECTION_STATE) connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  @StorageLink(Keys.FQDN) fqdn: string = '';
  @StorageLink(Keys.IP) ip: string = '';
  @StorageLink(Keys.IPV6) ipv6: string = '';
  @StorageLink(Keys.SESSION_EXPIRES) @Watch('refreshCountdown') sessionExpires: number = 0;
  @StorageLink(Keys.RESOURCES) resources: NetResource[] = [];
  @StorageLink(Keys.ACTIVE_PROFILE_ID) activeProfileId: string = '';
  @StorageLink(Keys.PROFILES) profiles: Profile[] = [];

  @State infoExpanded: boolean = false;
  @State exitNodeSheet: boolean = false;
  // 倒计时文案必须落成 @State 才会重渲染：此前 sessionTick 自增但 build() 从未
  // 引用它，倒计时文本实际永不刷新。
  @State sessionCountdownText: string = '';

  private sessionTimer: number = -1;

  aboutToAppear(): void {
    this.refreshCountdown();
    // 每分钟重算一次倒计时文案，与 Android home 行为一致。
    this.sessionTimer = setInterval(() => {
      this.refreshCountdown();
    }, 60_000);
  }

  aboutToDisappear(): void {
    if (this.sessionTimer !== -1) {
      clearInterval(this.sessionTimer);
      this.sessionTimer = -1;
    }
  }

  private refreshCountdown(): void {
    this.sessionCountdownText = Formatters.sessionCountdown(this.sessionExpires);
  }

  private activeProfileName(): string {
    const active: Profile | null = EngineManager.getInstance().activeProfile();
    return active !== null ? active.name : 'default';
  }

  private selectedExitNode(): NetResource | null {
    for (let i = 0; i < this.resources.length; i++) {
      const r: NetResource = this.resources[i];
      if (r.isExitNode() && r.isSelected) {
        return r;
      }
    }
    return null;
  }

  private isOn(): boolean {
    return ConnectionStateMapper.isOn(this.connectionState);
  }

  private copy(text: string): void {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data);
    promptAction.showToast({ message: 'Copied' });
  }

  @Builder
  InfoRow(value: string) {
    Row() {
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.nb_txt'))
        .fontFamily('monospace')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text($r('app.string.peer_detail_copy'))
        .fontSize(13)
        .fontColor($r('app.color.nb_orange'))
        .padding({ left: 10, right: 4, top: 6, bottom: 6 })
        .onClick(() => this.copy(value))
    }
    .width('100%')
    .constraintSize({ minHeight: 44 })
    .padding({ left: 16, right: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ExitNodeSheet() {
    Column() {
      Text($r('app.string.exit_node_title'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.nb_txt'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(16)

      ForEach(this.exitNodes(), (node: NetResource) => {
        Row() {
          Column() {
            Text(node.name)
              .fontSize(15)
              .fontColor($r('app.color.nb_txt'))
            Text(node.peer)
              .fontSize(12)
              .fontColor($r('app.color.nb_txt_light'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (node.isSelected) {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(18)
              .fontColor([$r('app.color.nb_orange')])
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => {
          EngineManager.getInstance().selectExitNode(node.address);
          this.exitNodeSheet = false;
        })
      }, (node: NetResource) => node.address)

      Button($r('app.string.exit_node_picker_none'))
        .width('90%')
        .backgroundColor($r('app.color.nb_gray_light'))
        .fontColor($r('app.color.nb_txt'))
        .margin({ top: 8, bottom: 20 })
        .onClick(() => {
          EngineManager.getInstance().selectExitNode('');
          this.exitNodeSheet = false;
        })
    }
    .width('100%')
    .backgroundColor($r('app.color.nb_sheet_bg'))
  }

  private exitNodes(): NetResource[] {
    return this.resources.filter((r: NetResource): boolean => r.isExitNode());
  }

  build() {
    Column() {
      // Profile chip
      Row() {
        Circle().width(8).height(8).fill($r('app.color.status_connected'))
        Text(this.activeProfileName())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.nb_txt'))
          .margin({ left: 8 })
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(14)
          .fontColor([$r('app.color.nb_txt')])
          .margin({ left: 4 })
      }
      .padding({ left: 16, right: 10, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.nb_chip_bg'))
      .borderRadius(20)
      .border({ width: 1, color: $r('app.color.nb_chip_border') })
      .margin({ top: 12 })
      .onClick(() => AppNav.push(Routes.PROFILES))

      // Wordmark + toggle + status block
      Column() {
        Text('NetBird')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.nb_txt'))
          .letterSpacing(0.5)
          .margin({ top: 24 })

        Toggle({ type: ToggleType.Switch, isOn: this.isOn() })
          .id('connect_toggle')
          .width(92)
          .height(44)
          .selectedColor($r('app.color.connect_track_on'))
          .switchPointColor($r('app.color.connect_thumb_on'))
          .margin({ top: 24 })
          .onChange((on: boolean) => {
            if (on !== this.isOn()) {
              EngineManager.getInstance().switchConnection(on);
            }
          })

        Text(ConnectionStateMapper.labelResource(this.connectionState))
          .id('connection_status')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.nb_txt'))
          .margin({ top: 24 })

        if (this.fqdn.length > 0) {
          Text(this.fqdn)
            .fontSize(15)
            .fontFamily('monospace')
            .fontColor($r('app.color.nb_txt'))
            .margin({ top: 16 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (this.ip.length > 0) {
          Row() {
            Text(`${this.ip}/16`)
              .fontSize(14)
              .fontFamily('monospace')
              .fontColor($r('app.color.nb_txt_light'))
            SymbolGlyph(this.infoExpanded
              ? $r('sys.symbol.chevron_up')
              : $r('sys.symbol.chevron_down'))
              .fontSize(14)
              .fontColor([$r('app.color.nb_txt_light')])
              .margin({ left: 4 })
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .margin({ top: 6 })
          .onClick(() => {
            this.infoExpanded = !this.infoExpanded;
          })
        }

        if (this.infoExpanded && this.ip.length > 0) {
          Column() {
            this.InfoRow(this.ip.length > 0 ? `${this.ip}/16` : '–')
            Divider().color($r('app.color.info_row_stroke'))
            if (this.ipv6.length > 0) {
              this.InfoRow(this.ipv6)
            }
          }
          .width('90%')
          .backgroundColor($r('app.color.info_row_bg'))
          .borderRadius(10)
          .border({ width: 1, color: $r('app.color.info_row_stroke') })
          .margin({ top: 12 })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .width('100%')

      // Session expiry row
      if (this.sessionExpires > 0) {
        Row() {
          SymbolGlyph($r('sys.symbol.clock'))
            .fontSize(22)
            .fontColor([$r('app.color.nb_txt_light')])
          Column() {
            Text(this.sessionCountdownText)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.nb_txt'))
            Text($r('app.string.session_banner_hint'))
              .fontSize(13)
              .fontColor($r('app.color.nb_txt_light'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 16 })
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([$r('app.color.nb_txt_light')])
        }
        .width('90%')
        .constraintSize({ minHeight: 56 })
        .padding({ left: 16, right: 12 })
        .backgroundColor($r('app.color.info_row_bg'))
        .borderRadius(12)
        .border({ width: 1, color: $r('app.color.info_row_stroke') })
        .margin({ bottom: 12 })
        .onClick(() => {
          // 只在会话截止时间真的后移时提示，对齐 Android 的 extend 流程语义；
          // 引擎拒绝延长（如未到期）时不弹假 toast。
          const before: number = AppStorage.get<number>(Keys.SESSION_EXPIRES) ?? 0;
          EngineManager.getInstance().extendSession();
          const after: number = AppStorage.get<number>(Keys.SESSION_EXPIRES) ?? 0;
          if (after > before) {
            promptAction.showToast({ message: $r('app.string.session_extended') });
          }
        })
      }

      // Exit node row
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_up'))
          .fontSize(22)
          .fontColor([$r('app.color.nb_txt_light')])
        Column() {
          Text($r('app.string.exit_node_title'))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.nb_txt'))
          Text(this.exitNodeStatus())
            .fontSize(13)
            .fontColor($r('app.color.nb_txt_light'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 16 })
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(16)
          .fontColor([$r('app.color.nb_txt_light')])
      }
      .width('90%')
      .constraintSize({ minHeight: 56 })
      .padding({ left: 16, right: 12 })
      .backgroundColor($r('app.color.info_row_bg'))
      .borderRadius(12)
      .border({ width: 1, color: $r('app.color.info_row_stroke') })
      .opacity(this.exitNodes().length > 0 ? 1 : 0.5)
      .margin({ bottom: 20 })
      .onClick(() => {
        if (this.exitNodes().length > 0) {
          this.exitNodeSheet = true;
        }
      })
      .bindSheet(this.exitNodeSheet, this.ExitNodeSheet(), {
        height: SheetSize.FIT_CONTENT,
        showClose: true,
        onDisappear: () => {
          this.exitNodeSheet = false;
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.nb_bg_home'))
  }

  private exitNodeStatus(): string | Resource {
    const selected: NetResource | null = this.selectedExitNode();
    if (selected !== null) {
      return selected.name;
    }
    return this.exitNodes().length > 0 ? $r('app.string.exit_node_none') : $r('app.string.exit_node_unavailable');
  }
}
