import { describe, it, expect } from '@ohos/hypium';
import { MockVpnEngine } from '../../../main/ets/engine/MockVpnEngine';
import { EngineManager } from '../../../main/ets/engine/EngineManager';
import { ConnectionState } from '../../../main/ets/model/ConnectionState';
import { PeerStatus, StatusMapper } from '../../../main/ets/model/Status';
import { Peer } from '../../../main/ets/model/Peer';
import { SshState } from '../../../main/ets/model/SshSession';
import { Keys } from '../../../main/ets/common/Constants';
import { EngineObserver } from '../../../main/ets/engine/EngineEvents';
import { Resource as NetResource, RoutingPeer } from '../../../main/ets/model/Resource';

/*
 * Instrumented engine/store tests (DevEco > Run 'ohosTest' on a device or
 * emulator). These run with the full ArkTS runtime, so they exercise the parts
 * the host-only local tests cannot: $r resource resolution, AppStorage bridging
 * and the asynchronous engine state machine with real timers.
 */
async function waitFor(pred: () => boolean, timeout: number = 6000): Promise<boolean> {
  const t0: number = Date.now();
  while (Date.now() - t0 < timeout) {
    if (pred()) {
      return true;
    }
    await new Promise<void>((r) => setTimeout(r, 50));
  }
  return pred();
}

export default function engineTest() {
  describe('EngineTest', () => {

    it('status_label_resource_resolves', 0, () => {
      const label: Resource = StatusMapper.labelResource(PeerStatus.CONNECTED);
      expect(label !== undefined && label !== null).assertTrue();
    });

    it('mock_engine_connect_lifecycle', 0, async () => {
      const eng: MockVpnEngine = new MockVpnEngine();
      const states: ConnectionState[] = [];
      let peers: Peer[] = [];
      const observer: EngineObserver = {
        onStateChanged: (s: ConnectionState) => states.push(s),
        onAddressChanged: (f: string, i: string, v6: string) => {},
        onPeersChanged: (p: Peer[]) => { peers = p; },
        onResourcesChanged: (r: NetResource[], rp: RoutingPeer[]) => {},
        onSessionDeadlineChanged: (t: number) => {},
        onSessionExpired: () => {},
        onError: (m: string) => {}
      };
      eng.setObserver(observer);
      expect(eng.isRunning()).assertFalse();

      eng.run(false);
      expect(eng.isRunning()).assertTrue();
      expect(states.includes(ConnectionState.CONNECTING)).assertTrue();

      const connected: boolean = await waitFor(() => states[states.length - 1] === ConnectionState.CONNECTED);
      expect(connected).assertTrue();
      expect(peers.length).assertEqual(6);
      expect(eng.exitNodes().length).assertEqual(1);
      expect(eng.sessionExpiresAt() > 0).assertTrue();

      eng.stop();
      const stopped: boolean = await waitFor(() => eng.peers().length === 0);
      expect(stopped).assertTrue();
      expect(eng.isRunning()).assertFalse();
    });

    it('engine_manager_bridges_to_appstorage', 0, async () => {
      const m: EngineManager = EngineManager.getInstance();
      m.init();
      expect(AppStorage.get<ConnectionState>(Keys.CONNECTION_STATE)).assertEqual(ConnectionState.DISCONNECTED);
      expect(AppStorage.get<boolean>(Keys.FIRST_LAUNCH)).assertTrue();

      m.switchConnection(true);
      const connected: boolean =
        await waitFor(() => AppStorage.get<ConnectionState>(Keys.CONNECTION_STATE) === ConnectionState.CONNECTED);
      expect(connected).assertTrue();
      expect((AppStorage.get<Peer[]>(Keys.PEERS) ?? []).length > 0).assertTrue();
      expect((AppStorage.get<string>(Keys.FQDN) ?? '').length > 0).assertTrue();

      const sess = m.addSshSession('10.0.0.5', 22, 'root', 'pw');
      const up: boolean = await waitFor(() =>
        (AppStorage.get<Object[]>(Keys.SSH_SESSIONS) ?? [])[0] !== undefined &&
        m.splitTunneling() !== undefined &&
        (AppStorage.get<Object[]>(Keys.SSH_SESSIONS) ?? []).length === 1);
      expect(up).assertTrue();
      m.removeSshSession(sess.id);

      m.stopEngine();
      const down: boolean =
        await waitFor(() => AppStorage.get<ConnectionState>(Keys.CONNECTION_STATE) === ConnectionState.DISCONNECTED);
      expect(down).assertTrue();
    });

    it('ssh_state_labels', 0, () => {
      expect(SshState.CONNECTED).assertEqual('connected');
    });

  });
}
