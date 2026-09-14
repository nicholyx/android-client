import { PeerStatus, StatusMapper } from '../model/Status';

/*
 * Small circular status dot used across the peer list, resource list and the
 * home profile chip. Colour comes from the status.
 */
@Component
export struct StatusDot {
  @Prop status: PeerStatus = PeerStatus.UNKNOWN;
  @Prop size: number = 8;

  build() {
    Circle()
      .width(this.size)
      .height(this.size)
      .fill(StatusMapper.colorResource(this.status))
  }
}
