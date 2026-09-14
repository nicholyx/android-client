// Executable behaviour tests for the pure-logic and engine layers of the
// NetBird HarmonyOS client. The harness transpiles the ArkTS modules into
// .mts and runs this file with `node --test --experimental-transform-types`.
import './shim.mts';
import { test } from 'node:test';
import assert from 'node:assert';

import { Formatters } from './common/Formatters.mts';
import { StatusMapper, PeerStatus, ZERO_TIME } from './model/Status.mts';
import { ConnectionState, ConnectionStateMapper } from './model/ConnectionState.mts';
import { Resource, NetworkDomain } from './model/Resource.mts';
import { Peer } from './model/Peer.mts';
import { Profile } from './model/Profile.mts';
import { SshSession, SshState } from './model/SshSession.mts';
import { AdvancedSettings } from './model/Settings.mts';
import { Keys, SplitTunnelMode } from './common/Constants.mts';
import { MockVpnEngine } from './engine/MockVpnEngine.mts';
import { EngineManager } from './engine/EngineManager.mts';

async function waitFor(pred, timeout = 5000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeout) {
    if (pred()) return true;
    await new Promise((r) => setTimeout(r, 40));
  }
  return pred();
}

// ----------------------------- Formatters -----------------------------
test('Formatters.bytes humanises counts', () => {
  assert.equal(Formatters.bytes(0), '0 B');
  assert.equal(Formatters.bytes(1024), '1 KB');
  assert.equal(Formatters.bytes(1536), '1.5 KB');
  assert.equal(Formatters.bytes(1048576), '1 MB');
});

test('Formatters.latencyColor bands by latency', () => {
  assert.equal(Formatters.latencyColor(0), 'app.color.nb_txt_light');
  assert.equal(Formatters.latencyColor(50), 'app.color.nb_latency_good');
  assert.equal(Formatters.latencyColor(200), 'app.color.nb_latency_high');
  assert.equal(Formatters.latencyColor(400), 'app.color.nb_danger');
});

test('Formatters.sessionCountdown matches Android plurals', () => {
  const now = Math.floor(Date.now() / 1000);
  assert.equal(Formatters.sessionCountdown(0), '');
  assert.equal(Formatters.sessionCountdown(now - 10), 'Session expired');
  assert.equal(Formatters.sessionCountdown(now + 30), 'Session expires in less than a minute');
  assert.equal(Formatters.sessionCountdown(now + 5 * 60), 'Session expires in 5 minutes');
  assert.equal(Formatters.sessionCountdown(now + 60 * 60), 'Session expires in 1 hour');
  assert.equal(Formatters.sessionCountdown(now + 3 * 24 * 3600), 'Session expires in 3 days');
});

test('Formatters.timeAgo handles Go zero time', () => {
  assert.equal(Formatters.timeAgo(ZERO_TIME), '-');
  assert.equal(Formatters.timeAgo(''), '-');
});

// ----------------------------- StatusMapper -----------------------------
test('StatusMapper.fromString maps wire values', () => {
  assert.equal(StatusMapper.fromString('idle'), PeerStatus.IDLE);
  assert.equal(StatusMapper.fromString('CONNECTED'), PeerStatus.CONNECTED);
  assert.equal(StatusMapper.fromString('bogus'), PeerStatus.UNKNOWN);
  assert.equal(StatusMapper.fromString(null), PeerStatus.UNKNOWN);
});

test('StatusMapper.isNever detects the zero time', () => {
  assert.ok(StatusMapper.isNever(ZERO_TIME));
  assert.ok(StatusMapper.isNever(null));
  assert.ok(!StatusMapper.isNever('2026-09-13 09:12:33'));
});

test('StatusMapper colour/label resources resolve', () => {
  assert.equal(StatusMapper.colorResource(PeerStatus.CONNECTED), 'app.color.status_connected');
  assert.equal(StatusMapper.labelResource(PeerStatus.IDLE), 'app.string.peer_status_idle');
});

// -------------------------- ConnectionState --------------------------
test('ConnectionStateMapper.isOn reflects tunnel up/coming-up', () => {
  assert.ok(ConnectionStateMapper.isOn(ConnectionState.CONNECTED));
  assert.ok(ConnectionStateMapper.isOn(ConnectionState.CONNECTING));
  assert.ok(!ConnectionStateMapper.isOn(ConnectionState.DISCONNECTED));
  assert.ok(!ConnectionStateMapper.isOn(ConnectionState.NO_NETWORK));
  assert.equal(ConnectionStateMapper.labelResource(ConnectionState.NEEDS_LOGIN), 'app.string.main_status_login_required');
});

// ----------------------------- Resource -----------------------------
test('Resource.isExitNodeAddress detects full-range routes', () => {
  assert.ok(Resource.isExitNodeAddress('0.0.0.0/0'));
  assert.ok(Resource.isExitNodeAddress('::/0'));
  assert.ok(Resource.isExitNodeAddress('0.0.0.0/0, ::/0'));
  assert.ok(!Resource.isExitNodeAddress('10.0.0.0/24'));
  assert.ok(!Resource.isExitNodeAddress(null));
});

test('Resource.isExitNode instance helper', () => {
  const exit = new Resource(PeerStatus.CONNECTED, 'Exit', '0.0.0.0/0', 'p', false, []);
  const net = new Resource(PeerStatus.CONNECTED, 'Api', '10.0.0.0/24', 'p', true, [new NetworkDomain('a.internal', ['10.0.0.1'])]);
  assert.ok(exit.isExitNode());
  assert.ok(!net.isExitNode());
  assert.equal(net.domains.length, 1);
});

// ----------------------------- Peer / Profile / Ssh -----------------------------
test('Peer.displayName prefers FQDN then IP', () => {
  const p = new Peer(PeerStatus.CONNECTED, '100.72.1.1', '', 'host.netbird.cloud', '', '', 0, 0, 0, '', false, false, '', '', '', '', '', []);
  assert.equal(p.displayName(), 'host.netbird.cloud');
  const q = new Peer(PeerStatus.IDLE, '100.72.1.2', '', '', '', '', 0, 0, 0, '', false, false, '', '', '', '', '', []);
  assert.equal(q.displayName(), '100.72.1.2');
});

test('Profile normalises null email', () => {
  const prof = new Profile('id', 'Work', null, true, 'https://x', false);
  assert.equal(prof.email, '');
  assert.ok(prof.isActive);
});

test('SshSession default title and state label', () => {
  const s = new SshSession('1', 'h', 22, 'root', 'pw', SshState.CONNECTING, '');
  assert.equal(s.title, 'root@h');
  assert.equal(SshSession.stateLabel(SshState.CONNECTED), 'connected');
  assert.equal(SshSession.stateLabel(SshState.CLOSED), 'closed');
});

// ----------------------------- MockVpnEngine -----------------------------
test('MockVpnEngine full connect/stop lifecycle', async () => {
  const eng = new MockVpnEngine();
  const states = [];
  let addr = null;
  let peers = [];
  eng.setObserver({
    onStateChanged: (s) => states.push(s),
    onAddressChanged: (f, i, v6) => { addr = { f, i, v6 }; },
    onPeersChanged: (p) => { peers = p; },
    onResourcesChanged: () => {},
    onSessionDeadlineChanged: () => {},
    onSessionExpired: () => {},
    onError: () => {},
  });

  assert.equal(eng.isRunning(), false, 'starts stopped');
  eng.run(false);
  assert.equal(eng.isRunning(), true);
  assert.ok(states.includes(ConnectionState.CONNECTING), 'emits CONNECTING immediately');

  assert.ok(await waitFor(() => states.includes(ConnectionState.CONNECTED)), 'reaches CONNECTED');
  assert.ok(addr && addr.i === '100.72.68.65', 'emits tunnel address');
  assert.equal(peers.length, 6, 'six peers generated');
  assert.equal(eng.exitNodes().length, 1, 'exactly one exit node');
  assert.ok(eng.sessionExpiresAt() > 0, 'session deadline set');

  eng.selectRoute('10.0.0.0/24');
  assert.ok(eng.resources().find((r) => r.address === '10.0.0.0/24').isSelected);
  eng.deselectRoute('10.0.0.0/24');
  assert.ok(!eng.resources().find((r) => r.address === '10.0.0.0/24').isSelected);

  const en = eng.exitNodes()[0];
  eng.selectExitNode(en.address);
  assert.ok(eng.exitNodes().find((r) => r.address === en.address).isSelected);

  assert.match(eng.debugBundle(true), /netbird-debug-anon-/);
  assert.match(eng.debugBundle(false), /^netbird-debug-2/);

  eng.stop();
  assert.ok(states.includes(ConnectionState.DISCONNECTING));
  // Note: setObserver replays the initial DISCONNECTED, so wait on the teardown
  // post-condition (last emitted state + cleared peers), not states.includes().
  assert.ok(
    await waitFor(() => eng.peers().length === 0 && states[states.length - 1] === ConnectionState.DISCONNECTED),
    'reaches DISCONNECTED and clears peers');
  assert.equal(eng.isRunning(), false);
  assert.equal(eng.peers().length, 0, 'peers cleared on stop');
});

// ----------------------------- EngineManager -----------------------------
test('EngineManager seeds store, manages profiles and connects', async () => {
  const m = EngineManager.getInstance();
  m.init();
  const g = (k) => globalThis.AppStorage.get(k);

  assert.equal(g(Keys.CONNECTION_STATE), ConnectionState.DISCONNECTED);
  assert.equal(g(Keys.PROFILES).length, 1);
  assert.equal(g(Keys.ACTIVE_PROFILE_ID), 'default');
  assert.equal(g(Keys.FIRST_LAUNCH), true);

  // profiles lifecycle
  m.addProfile('Work', 'https://corp.example.com', false);
  assert.equal(g(Keys.PROFILES).length, 2);
  const workId = g(Keys.PROFILES)[1].id;
  m.switchProfile(workId);
  assert.equal(g(Keys.ACTIVE_PROFILE_ID), workId);
  assert.equal(m.activeProfile().name, 'Work');
  m.logoutProfile(workId);
  assert.equal(g(Keys.PROFILES).find((p) => p.id === workId).email, '');
  m.removeProfile(workId);
  assert.equal(g(Keys.PROFILES).length, 1);
  assert.equal(g(Keys.ACTIVE_PROFILE_ID), 'default', 'removing active falls back');

  // advanced settings round-trip
  const s = new AdvancedSettings();
  s.forceRelay = true;
  m.saveAdvanced(s);
  assert.equal(m.advanced().forceRelay, true);

  // split tunneling default mode
  assert.equal(m.splitTunneling().mode, SplitTunnelMode.OFF);

  // connect through the manager -> AppStorage reflects engine callbacks
  m.switchConnection(true);
  assert.ok(await waitFor(() => g(Keys.CONNECTION_STATE) === ConnectionState.CONNECTED), 'manager connects');
  assert.ok(g(Keys.PEERS).length > 0, 'peers published to store');
  assert.ok(g(Keys.RESOURCES).length > 0, 'resources published to store');
  assert.ok(g(Keys.FQDN).length > 0, 'fqdn published to store');

  // ssh session lifecycle
  const sess = m.addSshSession('10.0.0.5', 22, 'root', 'pw');
  assert.equal(g(Keys.SSH_SESSIONS).length, 1);
  assert.ok(await waitFor(() => g(Keys.SSH_SESSIONS)[0].state === SshState.CONNECTED), 'ssh connects');
  m.removeSshSession(sess.id);
  assert.equal(g(Keys.SSH_SESSIONS).length, 0);

  // first-launch + teardown
  m.clearFirstLaunch();
  assert.equal(g(Keys.FIRST_LAUNCH), false);
  m.stopEngine();
  assert.ok(await waitFor(() => g(Keys.CONNECTION_STATE) === ConnectionState.DISCONNECTED), 'manager disconnects');
});
