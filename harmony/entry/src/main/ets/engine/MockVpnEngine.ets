import { VpnEngine } from './VpnEngine';
import { EngineObserver } from './EngineEvents';
import { Peer } from '../model/Peer';
import { PeerStatus, StatusMapper } from '../model/Status';
import { Resource, NetworkDomain, RoutingPeer } from '../model/Resource';
import { ConnectionState } from '../model/ConnectionState';

/*
 * A fully in-process stand-in for the Go core so the HarmonyOS client is
 * runnable end to end without the native engine. It reproduces the observable
 * behaviour the UI depends on: a connecting -> connected transition on run(),
 * a peer set with mixed statuses that ticks its transfer counters and latency,
 * shared resources including exit nodes, and a session deadline.
 *
 * Swapping in a real engine means providing another VpnEngine implementation;
 * nothing above EngineManager changes.
 */
export class MockVpnEngine implements VpnEngine {
  private observer: EngineObserver | null = null;
  private running: boolean = false;
  private connectTimer: number = -1;
  private tickTimer: number = -1;
  // stop() 的延迟 teardown 句柄：不记录的话，teardown 期间重新 run() 会被旧
  // 回调清空状态并 emit DISCONNECTED（快速断开/重连的状态机竞态）。
  private teardownTimer: number = -1;
  private currentState: ConnectionState = ConnectionState.DISCONNECTED;
  private sessionDeadline: number = 0;
  private peerSet: Peer[] = [];
  private resourceSet: Resource[] = [];

  private static readonly FQDN: string = 'harmony-phone.netbird.cloud';
  private static readonly IP: string = '100.72.68.65';
  private static readonly IPV6: string = 'fd00:cafe::65';

  setObserver(observer: EngineObserver | null): void {
    this.observer = observer;
    if (observer !== null) {
      // Replay current state to a freshly-registered observer, as the real
      // engine does on bind.
      observer.onStateChanged(this.currentState);
      if (this.running) {
        observer.onAddressChanged(MockVpnEngine.FQDN, MockVpnEngine.IP, MockVpnEngine.IPV6);
        observer.onPeersChanged(this.peerSet);
        observer.onResourcesChanged(this.resourceSet, []);
      }
    }
  }

  isRunning(): boolean {
    return this.running;
  }

  status(): string {
    return this.currentState;
  }

  sessionExpiresAt(): number {
    return this.sessionDeadline;
  }

  peers(): Peer[] {
    return this.peerSet;
  }

  resources(): Resource[] {
    return this.resourceSet;
  }

  exitNodes(): Resource[] {
    return this.resourceSet.filter((r: Resource): boolean => r.isExitNode());
  }

  run(useDeviceCodeFlow: boolean): void {
    if (this.running) {
      return;
    }
    // 清掉尚未执行的 stop() teardown，避免它在本轮连接建立后清空状态。
    this.clearTimers();
    this.running = true;
    this.buildDataset();
    this.emitState(ConnectionState.CONNECTING);

    // Simulate the tunnel coming up.
    this.connectTimer = setTimeout(() => {
      this.emitState(ConnectionState.CONNECTED);
      this.emitAddress();
      this.sessionDeadline = Math.floor(Date.now() / 1000) + 12 * 3600;
      this.notifySession();
      this.notifyPeers();
      this.notifyResources();
      this.startTicking();
    }, 1800);
  }

  stop(): void {
    if (!this.running) {
      return;
    }
    this.running = false;
    this.clearTimers();
    this.emitState(ConnectionState.DISCONNECTING);
    this.teardownTimer = setTimeout(() => {
      this.teardownTimer = -1;
      if (this.running) {
        return; // teardown 期间又被 run() 了：本轮 teardown 作废
      }
      this.sessionDeadline = 0;
      this.peerSet = [];
      this.resourceSet = [];
      this.notifyPeers();
      this.notifyResources();
      this.emitState(ConnectionState.DISCONNECTED);
    }, 900);
  }

  selectRoute(route: string): void {
    this.markResource(route, true);
  }

  deselectRoute(route: string): void {
    this.markResource(route, false);
  }

  selectExitNode(peerAddress: string): void {
    this.resourceSet.forEach((r: Resource) => {
      if (r.isExitNode()) {
        r.isSelected = r.address === peerAddress;
      }
    });
    this.notifyResources();
  }

  extendAuthSession(): void {
    this.sessionDeadline = Math.floor(Date.now() / 1000) + 12 * 3600;
    this.notifySession();
  }

  cancelExtendAuthSession(): void {
    // No pending browser flow to tear down in the mock.
  }

  debugBundle(anonymize: boolean): string {
    const stamp: string = new Date().toISOString().replace(/[:.]/g, '-');
    return `netbird-debug-${anonymize ? 'anon-' : ''}${stamp}`;
  }

  private markResource(route: string, selected: boolean): void {
    this.resourceSet.forEach((r: Resource) => {
      if (r.address === route) {
        r.isSelected = selected;
      }
    });
    this.notifyResources();
  }

  private buildDataset(): void {
    this.peerSet = [
      MockVpnEngine.makePeer(PeerStatus.CONNECTED, 'build-server.netbird.cloud', '100.72.10.11',
        '22ms', 22, 1_420_000, 880_000, false, ['10.0.0.0/24']),
      MockVpnEngine.makePeer(PeerStatus.CONNECTED, 'db-primary.netbird.cloud', '100.72.10.20',
        '48ms', 48, 9_120_000, 3_540_000, true, ['192.168.16.0/22']),
      MockVpnEngine.makePeer(PeerStatus.CONNECTING, 'staging-web.netbird.cloud', '100.72.10.31',
        '', 0, 0, 0, false, []),
      MockVpnEngine.makePeer(PeerStatus.IDLE, 'ci-runner-07.netbird.cloud', '100.72.10.44',
        '', 0, 0, 0, false, []),
      MockVpnEngine.makePeer(PeerStatus.CONNECTED, 'aws-frankfurt-exit.netbird.cloud', '100.72.10.90',
        '13ms', 13, 512_000, 2_240_000, true, ['0.0.0.0/0']),
      MockVpnEngine.makePeer(PeerStatus.IDLE, 'dev-laptop-mia.netbird.cloud', '100.72.10.55',
        '', 0, 0, 0, false, [])
    ];

    this.resourceSet = [
      new Resource(PeerStatus.CONNECTED, 'Internal API', '10.0.0.0/24', 'build-server.netbird.cloud',
        true, [new NetworkDomain('api.internal', ['10.0.0.5'])]),
      new Resource(PeerStatus.CONNECTED, 'Database subnet', '192.168.16.0/22', 'db-primary.netbird.cloud',
        true, [new NetworkDomain('db.internal', ['192.168.16.10'])]),
      new Resource(PeerStatus.IDLE, 'Grafana', '172.16.4.0/24', 'ci-runner-07.netbird.cloud',
        false, [new NetworkDomain('grafana.internal', ['172.16.4.9'])]),
      new Resource(PeerStatus.CONNECTED, 'Exit node (Frankfurt)', '0.0.0.0/0', 'aws-frankfurt-exit.netbird.cloud',
        false, [])
    ];
  }

  private static makePeer(status: PeerStatus, fqdn: string, ip: string, latency: string,
    latencyMs: number, rx: number, tx: number, relayed: boolean, routes: string[]): Peer {
    return new Peer(status, ip, 'fd00:cafe::' + ip.split('.')[3], fqdn,
      'pub-' + fqdn.substring(0, 6), latency, latencyMs, rx, tx,
      status === PeerStatus.IDLE ? '0001-01-01 00:00:00' : '2026-09-13 09:12:33',
      relayed, false, status === PeerStatus.CONNECTED ? '2026-09-13 09:12:30' : '0001-01-01 00:00:00',
      'host', relayed ? 'relay' : 'host', '192.0.2.10:51820',
      relayed ? 'relay.netbird.io:443' : '203.0.113.7:51820', routes);
  }

  private startTicking(): void {
    // Live counters so the detail screen has something to poll.
    this.tickTimer = setInterval(() => {
      if (!this.running) {
        return;
      }
      this.peerSet.forEach((p: Peer) => {
        if (p.status === PeerStatus.CONNECTED) {
          p.bytesRx += Math.floor(Math.random() * 40_000);
          p.bytesTx += Math.floor(Math.random() * 20_000);
        }
      });
      this.notifyPeers();
    }, 2000);
  }

  private clearTimers(): void {
    if (this.connectTimer !== -1) {
      clearTimeout(this.connectTimer);
      this.connectTimer = -1;
    }
    if (this.tickTimer !== -1) {
      clearInterval(this.tickTimer);
      this.tickTimer = -1;
    }
    if (this.teardownTimer !== -1) {
      clearTimeout(this.teardownTimer);
      this.teardownTimer = -1;
    }
  }

  private emitState(state: ConnectionState): void {
    this.currentState = state;
    if (this.observer !== null) {
      this.observer.onStateChanged(state);
    }
  }

  private emitAddress(): void {
    if (this.observer !== null) {
      this.observer.onAddressChanged(MockVpnEngine.FQDN, MockVpnEngine.IP, MockVpnEngine.IPV6);
    }
  }

  private notifyPeers(): void {
    if (this.observer !== null) {
      this.observer.onPeersChanged(this.peerSet.slice());
    }
  }

  private notifyResources(): void {
    if (this.observer !== null) {
      this.observer.onResourcesChanged(this.resourceSet.slice(), this.routingPeers());
    }
  }

  /** 按真实引擎的语义，把带路由的已连接 peer 汇总为路由归属表。 */
  private routingPeers(): RoutingPeer[] {
    return this.peerSet
      .filter((p: Peer): boolean => p.status === PeerStatus.CONNECTED && p.routes.length > 0)
      .map((p: Peer): RoutingPeer => new RoutingPeer(p.status, p.routes.slice()));
  }

  private notifySession(): void {
    if (this.observer !== null) {
      this.observer.onSessionDeadlineChanged(this.sessionDeadline);
    }
  }

  /** Unused import guard: StatusMapper referenced for parity with real engine mapping. */
  static mapStatus(raw: string): PeerStatus {
    return StatusMapper.fromString(raw);
  }
}
