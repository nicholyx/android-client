import { describe, it, expect } from '@ohos/hypium';
import { Formatters } from '../main/ets/common/Formatters';
import { StatusMapper, PeerStatus, ZERO_TIME } from '../main/ets/model/Status';
import { Resource, NetworkDomain } from '../main/ets/model/Resource';
import { Peer } from '../main/ets/model/Peer';
import { Profile } from '../main/ets/model/Profile';
import { SshSession, SshState } from '../main/ets/model/SshSession';

/*
 * Local unit tests (DevEco > Run Local Test). They cover the pure logic that has
 * no dependency on ArkUI globals ($r) or AppStorage, so they execute on the host
 * without a device. $r / AppStorage / UI behaviour lives in the instrumented
 * ohosTest suite, which runs on a real device or emulator.
 */
export default function logicTest() {
  describe('LogicTest', () => {

    it('formatters_bytes', 0, () => {
      expect(Formatters.bytes(0)).assertEqual('0 B');
      expect(Formatters.bytes(1024)).assertEqual('1 KB');
      expect(Formatters.bytes(1536)).assertEqual('1.5 KB');
      expect(Formatters.bytes(1048576)).assertEqual('1 MB');
    });

    it('formatters_session_countdown', 0, () => {
      const now: number = Math.floor(Date.now() / 1000);
      expect(Formatters.sessionCountdown(0)).assertEqual('');
      expect(Formatters.sessionCountdown(now - 10)).assertEqual('Session expired');
      expect(Formatters.sessionCountdown(now + 30)).assertEqual('Session expires in less than a minute');
      expect(Formatters.sessionCountdown(now + 5 * 60)).assertEqual('Session expires in 5 minutes');
      expect(Formatters.sessionCountdown(now + 60 * 60)).assertEqual('Session expires in 1 hour');
      expect(Formatters.sessionCountdown(now + 3 * 24 * 3600)).assertEqual('Session expires in 3 days');
    });

    it('formatters_time_ago_zero_time', 0, () => {
      expect(Formatters.timeAgo(ZERO_TIME)).assertEqual('-');
      expect(Formatters.timeAgo('')).assertEqual('-');
    });

    it('status_from_string', 0, () => {
      expect(StatusMapper.fromString('idle')).assertEqual(PeerStatus.IDLE);
      expect(StatusMapper.fromString('CONNECTED')).assertEqual(PeerStatus.CONNECTED);
      expect(StatusMapper.fromString('bogus')).assertEqual(PeerStatus.UNKNOWN);
      expect(StatusMapper.fromString(null)).assertEqual(PeerStatus.UNKNOWN);
    });

    it('status_is_never', 0, () => {
      expect(StatusMapper.isNever(ZERO_TIME)).assertTrue();
      expect(StatusMapper.isNever(null)).assertTrue();
      expect(StatusMapper.isNever('2026-09-13 09:12:33')).assertFalse();
    });

    it('resource_exit_node_detection', 0, () => {
      expect(Resource.isExitNodeAddress('0.0.0.0/0')).assertTrue();
      expect(Resource.isExitNodeAddress('::/0')).assertTrue();
      expect(Resource.isExitNodeAddress('0.0.0.0/0, ::/0')).assertTrue();
      expect(Resource.isExitNodeAddress('10.0.0.0/24')).assertFalse();
      expect(Resource.isExitNodeAddress(null)).assertFalse();

      const exit: Resource = new Resource(PeerStatus.CONNECTED, 'Exit', '0.0.0.0/0', 'p', false, []);
      const net: Resource = new Resource(PeerStatus.CONNECTED, 'Api', '10.0.0.0/24', 'p', true,
        [new NetworkDomain('a.internal', ['10.0.0.1'])]);
      expect(exit.isExitNode()).assertTrue();
      expect(net.isExitNode()).assertFalse();
      expect(net.domains.length).assertEqual(1);
    });

    it('peer_display_name', 0, () => {
      const p: Peer = new Peer(PeerStatus.CONNECTED, '100.72.1.1', '', 'host.netbird.cloud', '',
        '', 0, 0, 0, '', false, false, '', '', '', '', '', []);
      expect(p.displayName()).assertEqual('host.netbird.cloud');
      const q: Peer = new Peer(PeerStatus.IDLE, '100.72.1.2', '', '', '',
        '', 0, 0, 0, '', false, false, '', '', '', '', '', []);
      expect(q.displayName()).assertEqual('100.72.1.2');
    });

    it('profile_normalises_email', 0, () => {
      const prof: Profile = new Profile('id', 'Work', null, true, 'https://x', false);
      expect(prof.email).assertEqual('');
      expect(prof.isActive).assertTrue();
    });

    it('ssh_session_defaults', 0, () => {
      const s: SshSession = new SshSession('1', 'h', 22, 'root', 'pw', SshState.CONNECTING, '');
      expect(s.title).assertEqual('root@h');
      expect(SshSession.stateLabel(SshState.CONNECTED)).assertEqual('connected');
      expect(SshSession.stateLabel(SshState.CLOSED)).assertEqual('closed');
    });

  });
}
