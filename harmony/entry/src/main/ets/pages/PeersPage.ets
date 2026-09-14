import { Peer } from '../model/Peer';
import { PeerStatus } from '../model/Status';
import { Keys, Urls } from '../common/Constants';
import { PeerListItem } from '../components/PeerListItem';
import { Routes, NavRouter } from '../common/NavRouter';
import { UrlOpener } from '../common/UrlOpener';
import { common } from '@kit.AbilityKit';

enum PeerFilter {
  ALL = 'all',
  IDLE = 'idle',
  CONNECTING = 'connecting',
  CONNECTED = 'connected'
}

/*
 * Peers screen — the ArkUI equivalent of PeersFragment. A connected-count
 * header, a search field, filter chips and the peer list; tapping a row opens
 * the detail screen. The empty state mirrors layout_zero_peer.
 */
@Component
export struct PeersPage {
  @StorageLink(Keys.PEERS) peers: Peer[] = [];
  @State query: string = '';
  @State filter: PeerFilter = PeerFilter.ALL;

  private connectedCount(): number {
    return this.peers.filter((p: Peer): boolean => p.status === PeerStatus.CONNECTED).length;
  }

  private filtered(): Peer[] {
    const q: string = this.query.trim().toLowerCase();
    return this.peers.filter((p: Peer): boolean => {
      if (this.filter !== PeerFilter.ALL && p.status !== this.filter.toString()) {
        return false;
      }
      if (q.length === 0) {
        return true;
      }
      return p.displayName().toLowerCase().includes(q) || p.ip.toLowerCase().includes(q);
    });
  }

  @Builder
  FilterChip(label: Resource, value: PeerFilter) {
    Text(label)
      .fontSize(13)
      .fontColor(this.filter === value ? $r('app.color.white') : $r('app.color.nb_txt'))
      .backgroundColor(this.filter === value ? $r('app.color.nb_orange') : $r('app.color.nb_gray_bg'))
      .borderRadius(16)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .onClick(() => {
        this.filter = value;
      })
  }

  build() {
    Column() {
      // Header
      Row() {
        Text() {
          Span(`${this.connectedCount()}`)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.nb_txt'))
          Span(' of ')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.nb_txt'))
          Span(`${this.peers.length}`)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.nb_txt'))
          Span(' Peers connected')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.nb_txt'))
        }
        .fontSize(16)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      // Search
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(16)
          .fontColor([$r('app.color.nb_txt_light')])
          .margin({ right: 8 })
        TextInput({ placeholder: 'Search peers', text: this.query })
          .placeholderColor($r('app.color.nb_txt_light'))
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.nb_txt'))
          .layoutWeight(1)
          .height(40)
          .onChange((value: string) => {
            this.query = value;
          })
      }
      .width('90%')
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.info_row_bg'))
      .borderRadius(10)
      .border({ width: 1, color: $r('app.color.info_row_stroke') })

      // Filters
      Row({ space: 8 }) {
        this.FilterChip($r('app.string.peer_filter_all'), PeerFilter.ALL)
        this.FilterChip($r('app.string.peer_filter_idle'), PeerFilter.IDLE)
        this.FilterChip($r('app.string.peer_filter_connecting'), PeerFilter.CONNECTING)
        this.FilterChip($r('app.string.peer_filter_connected'), PeerFilter.CONNECTED)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 8 })

      if (this.peers.length === 0) {
        this.EmptyState()
      } else {
        List() {
          ForEach(this.filtered(), (peer: Peer) => {
            ListItem() {
              PeerListItem({
                peer: peer,
                onTap: (p: Peer) => NavRouter.push(Routes.PEER_DETAIL, p.ip)
              })
            }
          }, (peer: Peer) => peer.ip + peer.fqdn)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: $r('app.color.nb_gray_separator') })
        .padding({ bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.nb_bg_peers'))
  }

  @Builder
  EmptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.externaldrive'))
        .fontSize(56)
        .fontColor([$r('app.color.nb_txt_light')])
        .margin({ bottom: 16 })
      Text($r('app.string.zero_peers_no_machines'))
        .fontSize(15)
        .fontColor($r('app.color.nb_txt_light'))
        .textAlign(TextAlign.Center)
        .width('70%')
      Button($r('app.string.zero_peers_btn_learn_why'))
        .fontSize(14)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.nb_orange'))
        .margin({ top: 12 })
        .onClick(() => UrlOpener.open(getContext(this) as common.UIAbilityContext, Urls.LEARN_WHY_NO_PEERS))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
