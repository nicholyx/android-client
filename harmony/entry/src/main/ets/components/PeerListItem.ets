import { Peer } from '../model/Peer';
import { StatusMapper } from '../model/Status';
import { StatusDot } from './StatusDot';

/*
 * One row of the Peers list, mirroring list_item_peer.xml: status dot, the
 * FQDN (or IP), the IP beneath it, and the latency on the right colour-banded
 * by the value. Tapping opens the detail screen; the SSH action is surfaced on
 * the detail screen and via long-press here.
 */
@Component
export struct PeerListItem {
  @ObjectLink peer: Peer;
  onTap: (peer: Peer) => void = () => {};

  build() {
    Row() {
      StatusDot({ status: this.peer.status, size: 9 })

      Column() {
        Text(this.peer.displayName())
          .fontSize(15)
          .fontColor($r('app.color.nb_txt'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.peer.ip)
          .fontSize(12)
          .fontColor($r('app.color.nb_txt_light'))
          .margin({ top: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Column() {
        Text(StatusMapper.labelResource(this.peer.status))
          .fontSize(12)
          .fontColor($r('app.color.nb_txt_light'))
        if (this.peer.latencyMs > 0) {
          Text(`${this.peer.latencyMs} ms`)
            .fontSize(12)
            .fontColor(this.latencyColor())
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.info_row_bg'))
    .onClick(() => this.onTap(this.peer))
  }

  private latencyColor(): Resource {
    if (this.peer.latencyMs <= 0) {
      return $r('app.color.nb_txt_light');
    }
    if (this.peer.latencyMs < 150) {
      return $r('app.color.nb_latency_good');
    }
    if (this.peer.latencyMs < 300) {
      return $r('app.color.nb_latency_high');
    }
    return $r('app.color.nb_danger');
  }
}
