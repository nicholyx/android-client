/*
 * Peer / resource connection status.
 *
 * Mirrors io.netbird.client.ui.home.Status from the Android client. The wire
 * values ("idle" / "connecting" / "connected") are what the engine reports;
 * the UI derives a translated label and a status colour from the enum.
 */

export enum PeerStatus {
  IDLE = 'idle',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  UNKNOWN = 'unknown'
}

/** Go's zero time, as formatted by the engine binding. Means "no value yet". */
export const ZERO_TIME: string = '0001-01-01 00:00:00';

export class StatusMapper {
  /** Translated string-resource label for a status. */
  static labelResource(status: PeerStatus): Resource {
    switch (status) {
      case PeerStatus.IDLE:
        return $r('app.string.peer_status_idle');
      case PeerStatus.CONNECTING:
        return $r('app.string.peer_status_connecting');
      case PeerStatus.CONNECTED:
        return $r('app.string.peer_status_connected');
      default:
        return $r('app.string.peer_status_unknown');
    }
  }

  /** Colour resource of the small status dot for a status. */
  static colorResource(status: PeerStatus): Resource {
    switch (status) {
      case PeerStatus.CONNECTED:
        return $r('app.color.status_connected');
      case PeerStatus.CONNECTING:
        return $r('app.color.status_connecting');
      case PeerStatus.IDLE:
        return $r('app.color.status_idle');
      default:
        return $r('app.color.status_disconnected');
    }
  }

  static fromString(status: string | null): PeerStatus {
    if (status === null) {
      return PeerStatus.UNKNOWN;
    }
    const lower: string = status.toLowerCase();
    if (lower === 'idle') {
      return PeerStatus.IDLE;
    }
    if (lower === 'connecting') {
      return PeerStatus.CONNECTING;
    }
    if (lower === 'connected') {
      return PeerStatus.CONNECTED;
    }
    return PeerStatus.UNKNOWN;
  }

  /** True when the timestamp is Go's zero value, i.e. the event never happened. */
  static isNever(timestamp: string | null): boolean {
    return timestamp === null || timestamp.length === 0 || timestamp === ZERO_TIME;
  }
}
