import { PeerStatus } from './Status';

/*
 * A network resource (route / domain) shared with this peer, plus the routing
 * peers that carry it. Mirrors io.netbird.client.ui.home.Resource,
 * NetworkDomain and RoutingPeer.
 */

export class NetworkDomain {
  domain: string;
  resolved: string[];

  constructor(domain: string, resolved: string[]) {
    this.domain = domain;
    this.resolved = resolved;
  }
}

@Observed
export class Resource {
  status: PeerStatus;
  name: string;
  address: string;
  peer: string;
  isSelected: boolean;
  domains: NetworkDomain[];

  constructor(status: PeerStatus, name: string, address: string, peer: string,
    isSelected: boolean, domains: NetworkDomain[]) {
    this.status = status;
    this.name = name;
    this.address = address;
    this.peer = peer;
    this.isSelected = isSelected;
    this.domains = domains;
  }

  isExitNode(): boolean {
    return Resource.isExitNodeAddress(this.address);
  }

  /**
   * A route whose range covers all traffic (0.0.0.0/0 or ::/0) is an exit node.
   * Dual-stack exit nodes are reported as a single comma-joined field, e.g.
   * "0.0.0.0/0, ::/0", so each part is checked individually.
   */
  static isExitNodeAddress(address: string | null): boolean {
    if (address === null) {
      return false;
    }
    const parts: string[] = address.split(',');
    for (let i = 0; i < parts.length; i++) {
      const trimmed: string = parts[i].trim();
      if (trimmed === '0.0.0.0/0' || trimmed === '::/0') {
        return true;
      }
    }
    return false;
  }
}

export class RoutingPeer {
  status: PeerStatus;
  routes: string[];

  constructor(status: PeerStatus, routes: string[]) {
    this.status = status;
    this.routes = routes;
  }
}
