import { Peer } from '../model/Peer';
import { StatusMapper } from '../model/Status';
import { Keys } from '../common/Constants';
import { Formatters } from '../common/Formatters';
import { StatusDot } from '../components/StatusDot';
import { Routes, AppNav } from '../common/NavRouter';
import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';

/*
 * Peer detail — the ArkUI equivalent of PeerDetailFragment. Reads the peer IP
 * from the navigation param, finds the live Peer in the store and renders the
 * labelled rows (IP, connection type, latency, transfer, ICE, public key) the
 * desktop app shows, plus an SSH action.
 */
@Component
export struct PeerDetailPage {
  @StorageLink(Keys.PEERS) peers: Peer[] = [];
  @State peerIp: string = '';

  private peer(): Peer | null {
    for (let i = 0; i < this.peers.length; i++) {
      if (this.peers[i].ip === this.peerIp) {
        return this.peers[i];
      }
    }
    return null;
  }

  private copy(text: string): void {
    if (text.length === 0 || text === '-') {
      return;
    }
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data);
    promptAction.showToast({ message: $r('app.string.peer_detail_copied') });
  }

  @Builder
  DetailRow(label: Resource, value: string | Resource, mono: boolean, valueColor: ResourceColor, copyable: boolean) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.nb_txt_light'))
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor(valueColor)
        .fontFamily(mono ? 'monospace' : '')
        .textAlign(TextAlign.End)
        .layoutWeight(1.2)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .padding({ left: 20, right: 20, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    // 逐行复制对齐 Android 详情页的行级交互，不再是整卡只复制 IP。
    .onClick(() => {
      if (copyable) {
        this.copy(value as string);
      }
    })
  }

  /* 本 SDK（5.0.1）的 NavDestination.title 不接受 Resource，用局部 @Builder
   * 渲染 $r 并显式给出 CustomTitle 必需的 height（此版 SDK 为必填字段）。 */
  @Builder
  DestTitle() {
    Text($r('app.string.peer_detail_title'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }

  build() {
    NavDestination() {
      if (this.peer() !== null) {
        Scroll() {
          Column() {
            // Header
            Row() {
              StatusDot({ status: this.peer()!.status, dotSize: 10 })
              Column() {
                Text(this.peer()!.displayName())
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.nb_txt'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(StatusMapper.labelResource(this.peer()!.status))
                  .fontSize(13)
                  .fontColor($r('app.color.nb_txt_light'))
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 10 })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 12 })
            .alignItems(VerticalAlign.Center)

            // Address card
            Column() {
              this.DetailRow($r('app.string.peer_detail_netbird_ip'), this.peer()!.ip, true, $r('app.color.nb_txt'), true)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_netbird_ipv6'),
                this.peer()!.ipv6.length > 0 ? this.peer()!.ipv6 : '-', true, $r('app.color.nb_txt'), true)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_public_key'),
                this.peer()!.pubKey, true, $r('app.color.nb_txt'), true)
            }
            .backgroundColor($r('app.color.info_row_bg'))
            .borderRadius(12)
            .border({ width: 1, color: $r('app.color.info_row_stroke') })
            .margin({ left: 20, right: 20, top: 4 })

            // Connection card
            Column() {
              this.DetailRow($r('app.string.peer_detail_connection'),
                this.peer()!.relayed ? $r('app.string.peer_detail_connection_relayed') : $r('app.string.peer_detail_connection_p2p'), false, $r('app.color.nb_txt'), false)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_latency'),
                this.peer()!.latencyMs > 0 ? `${this.peer()!.latencyMs} ms` : '-', false,
                Formatters.latencyColor(this.peer()!.latencyMs), false)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_rosenpass'),
                this.peer()!.rosenpassEnabled ? $r('app.string.peer_detail_yes') : $r('app.string.peer_detail_no'), false, $r('app.color.nb_txt'), false)
            }
            .backgroundColor($r('app.color.info_row_bg'))
            .borderRadius(12)
            .border({ width: 1, color: $r('app.color.info_row_stroke') })
            .margin({ left: 20, right: 20, top: 16 })

            // Transfer card
            Column() {
              this.DetailRow($r('app.string.peer_detail_bytes_received'),
                Formatters.bytes(this.peer()!.bytesRx), true, $r('app.color.nb_transfer_rx'), false)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_bytes_sent'),
                Formatters.bytes(this.peer()!.bytesTx), true, $r('app.color.nb_txt'), false)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_status_since'),
                Formatters.timeAgo(this.peer()!.connStatusUpdate), false, $r('app.color.nb_txt'), false)
            }
            .backgroundColor($r('app.color.info_row_bg'))
            .borderRadius(12)
            .border({ width: 1, color: $r('app.color.info_row_stroke') })
            .margin({ left: 20, right: 20, top: 16 })

            // ICE card
            Column() {
              this.DetailRow($r('app.string.peer_detail_local_ice'),
                this.ice(this.peer()!.localIceCandidateEndpoint, this.peer()!.localIceCandidateType),
                true, $r('app.color.nb_txt'), false)
              Divider().color($r('app.color.nb_gray_separator'))
              this.DetailRow($r('app.string.peer_detail_remote_ice'),
                this.ice(this.peer()!.remoteIceCandidateEndpoint, this.peer()!.remoteIceCandidateType),
                true, $r('app.color.nb_txt'), false)
            }
            .backgroundColor($r('app.color.info_row_bg'))
            .borderRadius(12)
            .border({ width: 1, color: $r('app.color.info_row_stroke') })
            .margin({ left: 20, right: 20, top: 16 })

            // Resources / routes
            if (this.peer()!.routes.length > 0) {
              Text($r('app.string.peer_detail_networks'))
                .fontSize(13)
                .fontColor($r('app.color.nb_txt_light'))
                .textCase(TextCase.UpperCase)
                .width('100%')
                .padding({ left: 20, right: 20, top: 20, bottom: 8 })
              Column() {
                ForEach(this.peer()!.routes, (route: string, index: number) => {
                  if (index > 0) {
                    Divider().color($r('app.color.nb_gray_separator'))
                  }
                  Row() {
                    Text(route)
                      .fontSize(14)
                      .fontFamily('monospace')
                      .fontColor($r('app.color.nb_txt'))
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .constraintSize({ minHeight: 44 })
                  .padding({ left: 20, right: 20 })
                }, (route: string) => route)
              }
              .backgroundColor($r('app.color.info_row_bg'))
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.info_row_stroke') })
              .margin({ left: 20, right: 20 })
            }

            // SSH action
            Button($r('app.string.peers_action_ssh'))
              .width('90%')
              .height(48)
              .backgroundColor($r('app.color.nb_orange'))
              .fontColor($r('app.color.white'))
              .margin({ top: 24, bottom: 24 })
              .onClick(() => {
                const p: Peer | null = this.peer();
                if (p !== null) {
                  AppNav.push(Routes.SSH_TERMINAL, new SshTarget(p.ip, 22, 'root'));
                }
              })
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      } else {
        Column() {
          Text($r('app.string.peer_not_found'))
            .fontSize(15)
            .fontColor($r('app.color.nb_txt_light'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .title({ builder: this.DestTitle, height: TitleHeight.MainOnly })
    .backgroundColor($r('app.color.nb_bg'))
    .onReady((ctx: NavDestinationContext) => {
      const param = ctx.pathInfo.param as Object | undefined;
      if (typeof param === 'string') {
        this.peerIp = param as string;
      }
    })
  }

  private ice(endpoint: string, type: string): string {
    if (endpoint.length === 0) {
      return '-';
    }
    return type.length > 0 ? `${endpoint} (${type})` : endpoint;
  }
}

/** Param object passed when opening the SSH terminal for a peer. */
export class SshTarget {
  host: string;
  port: number;
  user: string;
  /** 关联的 SSH 会话 id；从 peer 详情直连时为空串（无会话记录）。 */
  sessionId: string;

  constructor(host: string, port: number, user: string, sessionId: string = '') {
    this.host = host;
    this.port = port;
    this.user = user;
    this.sessionId = sessionId;
  }
}
