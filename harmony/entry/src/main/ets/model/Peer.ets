import { PeerStatus } from './Status';

/*
 * A single peer as shown in the Peers list and the Peer detail screen.
 * Mirrors io.netbird.client.ui.home.Peer.
 *
 * @Observed + @ObjectLink let an item mutate in place (transfer counters,
 * latency) while a list that renders it re-renders only the affected row.
 */
@Observed
export class Peer {
  status: PeerStatus;
  ip: string;
  ipv6: string;
  fqdn: string;
  pubKey: string;
  latency: string;
  latencyMs: number;
  bytesRx: number;
  bytesTx: number;
  connStatusUpdate: string;
  relayed: boolean;
  rosenpassEnabled: boolean;
  lastWireguardHandshake: string;
  localIceCandidateType: string;
  remoteIceCandidateType: string;
  localIceCandidateEndpoint: string;
  remoteIceCandidateEndpoint: string;
  routes: string[];

  constructor(status: PeerStatus, ip: string, ipv6: string, fqdn: string, pubKey: string,
    latency: string, latencyMs: number, bytesRx: number, bytesTx: number,
    connStatusUpdate: string, relayed: boolean, rosenpassEnabled: boolean,
    lastWireguardHandshake: string, localIceCandidateType: string,
    remoteIceCandidateType: string, localIceCandidateEndpoint: string,
    remoteIceCandidateEndpoint: string, routes: string[]) {
    this.status = status;
    this.ip = ip;
    this.ipv6 = ipv6;
    this.fqdn = fqdn;
    this.pubKey = pubKey;
    this.latency = latency;
    this.latencyMs = latencyMs;
    this.bytesRx = bytesRx;
    this.bytesTx = bytesTx;
    this.connStatusUpdate = connStatusUpdate;
    this.relayed = relayed;
    this.rosenpassEnabled = rosenpassEnabled;
    this.lastWireguardHandshake = lastWireguardHandshake;
    this.localIceCandidateType = localIceCandidateType;
    this.remoteIceCandidateType = remoteIceCandidateType;
    this.localIceCandidateEndpoint = localIceCandidateEndpoint;
    this.remoteIceCandidateEndpoint = remoteIceCandidateEndpoint;
    this.routes = routes;
  }

  /** Display title: FQDN when present, otherwise the IP. */
  displayName(): string {
    if (this.fqdn !== null && this.fqdn.length > 0) {
      return this.fqdn;
    }
    return this.ip.length > 0 ? this.ip : '—';
  }
}

/** 列表排序：已连接优先，其余按显示名（FQDN 优先，回落 IP），对齐 Android PeersAdapter。 */
export class PeerSort {
  static compare(p1: Peer, p2: Peer): number {
    const c1: boolean = p1.status === PeerStatus.CONNECTED;
    const c2: boolean = p2.status === PeerStatus.CONNECTED;
    if (c1 !== c2) {
      return c1 ? -1 : 1;
    }
    const n1: string = p1.displayName().toLowerCase();
    const n2: string = p2.displayName().toLowerCase();
    if (n1 < n2) {
      return -1;
    }
    if (n1 > n2) {
      return 1;
    }
    return 0;
  }
}

