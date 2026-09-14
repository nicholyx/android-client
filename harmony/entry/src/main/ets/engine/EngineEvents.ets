import { Peer } from '../model/Peer';
import { Resource, RoutingPeer } from '../model/Resource';
import { ConnectionState } from '../model/ConnectionState';

/*
 * Callback surface the engine uses to push asynchronous updates to the UI,
 * mirroring the gomobile ConnectionListener / PeersStateListener the Android
 * client registers with the Go core.
 */

export interface ConnectionListener {
  onStateChanged(state: ConnectionState): void;
  onAddressChanged(fqdn: string, ip: string, ipv6: string): void;
}

export interface PeersStateListener {
  onPeersChanged(peers: Peer[]): void;
}

export interface ResourcesStateListener {
  onResourcesChanged(resources: Resource[], routingPeers: RoutingPeer[]): void;
}

export interface SessionEventListener {
  onSessionDeadlineChanged(expiresAtUnixSeconds: number): void;
  onSessionExpired(): void;
}

export interface EngineErrorListener {
  onError(message: string): void;
}

/** Aggregated bundle so a single observer can subscribe to everything. */
export interface EngineObserver extends ConnectionListener, PeersStateListener,
  ResourcesStateListener, SessionEventListener, EngineErrorListener {
}
