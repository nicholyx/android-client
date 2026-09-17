import { VpnEngine } from './VpnEngine';
import { MockVpnEngine } from './MockVpnEngine';
import { EngineObserver } from './EngineEvents';
import { Peer } from '../model/Peer';
import { Resource, RoutingPeer } from '../model/Resource';
import { ConnectionState } from '../model/ConnectionState';
import { Profile } from '../model/Profile';
import { SshSession, SshState } from '../model/SshSession';
import { AdvancedSettings, SplitTunnelConfig, SplitTunnelEntry } from '../model/Settings';
import { Keys, ThemeMode, SplitTunnelMode } from '../common/Constants';

/*
 * Application-wide reactive store and the single owner of the VPN engine.
 *
 * The Android client spread this across MainActivity (a ServiceAccessor +
 * StateListenerRegistry), VPNService, EngineRunner and a handful of ViewModels.
 * Here it collapses into one singleton: it owns the active VpnEngine, bridges
 * the engine's push callbacks into AppStorage, and exposes the intents the
 * pages fire (connect, switch profile, pick exit node, add SSH session, ...).
 *
 * Pages bind to the AppStorage keys with @StorageLink/@StorageProp, so any
 * engine callback re-renders exactly the views that read the changed value.
 */
export class EngineManager implements EngineObserver {
  private static instance: EngineManager | null = null;
  private engine: VpnEngine;
  private initialised: boolean = false;

  private constructor() {
    // The porting seam: replace MockVpnEngine with the native engine build.
    this.engine = new MockVpnEngine();
  }

  static getInstance(): EngineManager {
    if (EngineManager.instance === null) {
      EngineManager.instance = new EngineManager();
    }
    return EngineManager.instance;
  }

  /** Seed AppStorage defaults and subscribe to the engine. Call once from EntryAbility. */
  init(): void {
    if (this.initialised) {
      return;
    }
    this.initialised = true;

    AppStorage.setOrCreate<ConnectionState>(Keys.CONNECTION_STATE, ConnectionState.DISCONNECTED);
    AppStorage.setOrCreate<Peer[]>(Keys.PEERS, []);
    AppStorage.setOrCreate<Resource[]>(Keys.RESOURCES, []);
    AppStorage.setOrCreate<string>(Keys.FQDN, '');
    AppStorage.setOrCreate<string>(Keys.IP, '');
    AppStorage.setOrCreate<string>(Keys.IPV6, '');
    AppStorage.setOrCreate<number>(Keys.SESSION_EXPIRES, 0);
    AppStorage.setOrCreate<SshSession[]>(Keys.SSH_SESSIONS, []);
    AppStorage.setOrCreate<ThemeMode>(Keys.THEME_MODE, ThemeMode.SYSTEM);
    AppStorage.setOrCreate<AdvancedSettings>(Keys.ADVANCED, new AdvancedSettings());
    AppStorage.setOrCreate<boolean>(Keys.FIRST_LAUNCH, true);

    const split: SplitTunnelConfig = new SplitTunnelConfig();
    split.mode = SplitTunnelMode.OFF;
    split.entries = [
      new SplitTunnelEntry('com.example.browser', 'Browser', false),
      new SplitTunnelEntry('com.example.mail', 'Mail', false),
      new SplitTunnelEntry('com.example.maps', 'Maps', false)
    ];
    AppStorage.setOrCreate<SplitTunnelConfig>(Keys.SPLIT_TUNNELING, split);

    // A single default profile, matching the desktop/Android first-run state.
    const defaultProfile: Profile =
      new Profile('default', 'default', '', true, 'https://api.netbird.io', true);
    AppStorage.setOrCreate<Profile[]>(Keys.PROFILES, [defaultProfile]);
    AppStorage.setOrCreate<string>(Keys.ACTIVE_PROFILE_ID, 'default');

    this.engine.setObserver(this);
  }

  // ---- EngineObserver: bridge engine callbacks into AppStorage ----

  onStateChanged(state: ConnectionState): void {
    AppStorage.set<ConnectionState>(Keys.CONNECTION_STATE, state);
  }

  onAddressChanged(fqdn: string, ip: string, ipv6: string): void {
    AppStorage.set<string>(Keys.FQDN, fqdn);
    AppStorage.set<string>(Keys.IP, ip);
    AppStorage.set<string>(Keys.IPV6, ipv6);
  }

  onPeersChanged(peers: Peer[]): void {
    AppStorage.set<Peer[]>(Keys.PEERS, peers);
  }

  onResourcesChanged(resources: Resource[], routingPeers: RoutingPeer[]): void {
    AppStorage.set<Resource[]>(Keys.RESOURCES, resources);
    // 路由 peer 状态供 Resources 页展示（此前参数被忽略）。
    AppStorage.set<RoutingPeer[]>(Keys.ROUTING_PEERS, routingPeers.slice());
  }

  onSessionDeadlineChanged(expiresAtUnixSeconds: number): void {
    AppStorage.set<number>(Keys.SESSION_EXPIRES, expiresAtUnixSeconds);
  }

  onSessionExpired(): void {
    AppStorage.set<ConnectionState>(Keys.CONNECTION_STATE, ConnectionState.NEEDS_LOGIN);
  }

  onError(message: string): void {
    console.error(`[NetBird] engine error: ${message}`);
  }

  // ---- Intents fired by the UI ----

  /** Toggle handler for the home connect switch. */
  switchConnection(on: boolean): void {
    if (on) {
      this.engine.run(false);
    } else {
      this.engine.stop();
    }
  }

  stopEngine(): void {
    this.engine.stop();
  }

  isRunning(): boolean {
    return this.engine.isRunning();
  }

  refreshPeers(): Peer[] {
    return this.engine.peers();
  }

  selectRoute(route: string): void {
    this.engine.selectRoute(route);
  }

  deselectRoute(route: string): void {
    this.engine.deselectRoute(route);
  }

  selectExitNode(peerAddress: string): void {
    this.engine.selectExitNode(peerAddress);
  }

  exitNodes(): Resource[] {
    return this.engine.exitNodes();
  }

  extendSession(): void {
    this.engine.extendAuthSession();
  }

  debugBundle(anonymize: boolean): string {
    return this.engine.debugBundle(anonymize);
  }

  // ---- Profiles ----

  activeProfile(): Profile | null {
    const profiles: Profile[] = AppStorage.get<Profile[]>(Keys.PROFILES) ?? [];
    const activeId: string = AppStorage.get<string>(Keys.ACTIVE_PROFILE_ID) ?? '';
    for (let i = 0; i < profiles.length; i++) {
      if (profiles[i].id === activeId) {
        return profiles[i];
      }
    }
    return profiles.length > 0 ? profiles[0] : null;
  }

  addProfile(name: string, serverUrl: string, isCloud: boolean): void {
    const profiles: Profile[] = (AppStorage.get<Profile[]>(Keys.PROFILES) ?? []).slice();
    const id: string = `profile-${Date.now()}`;
    profiles.push(new Profile(id, name, '', false, serverUrl, isCloud));
    AppStorage.set<Profile[]>(Keys.PROFILES, profiles);
  }

  switchProfile(id: string): void {
    const profiles: Profile[] = (AppStorage.get<Profile[]>(Keys.PROFILES) ?? []).slice();
    profiles.forEach((p: Profile) => {
      p.isActive = p.id === id;
    });
    AppStorage.set<Profile[]>(Keys.PROFILES, profiles);
    AppStorage.set<string>(Keys.ACTIVE_PROFILE_ID, id);
    // Switching profile drops the current connection, as on Android.
    this.engine.stop();
  }

  removeProfile(id: string): void {
    const profiles: Profile[] = (AppStorage.get<Profile[]>(Keys.PROFILES) ?? []).slice();
    const next: Profile[] = profiles.filter((p: Profile): boolean => p.id !== id);
    AppStorage.set<Profile[]>(Keys.PROFILES, next);
    if ((AppStorage.get<string>(Keys.ACTIVE_PROFILE_ID) ?? '') === id && next.length > 0) {
      this.switchProfile(next[0].id);
    }
  }

  /** 把自建服务器地址写进 profile（FirstInstall 引导页选择后调用）。 */
  updateProfileServerUrl(id: string, serverUrl: string): void {
    const profiles: Profile[] = (AppStorage.get<Profile[]>(Keys.PROFILES) ?? []).slice();
    profiles.forEach((p: Profile) => {
      if (p.id === id) {
        p.serverUrl = serverUrl;
      }
    });
    AppStorage.set<Profile[]>(Keys.PROFILES, profiles);
  }

  logoutProfile(id: string): void {
    const profiles: Profile[] = (AppStorage.get<Profile[]>(Keys.PROFILES) ?? []).slice();
    profiles.forEach((p: Profile) => {
      if (p.id === id) {
        p.email = '';
      }
    });
    AppStorage.set<Profile[]>(Keys.PROFILES, profiles);
  }

  // ---- SSH sessions ----

  addSshSession(host: string, port: number, user: string, password: string): SshSession {
    const sessions: SshSession[] = (AppStorage.get<SshSession[]>(Keys.SSH_SESSIONS) ?? []).slice();
    const session: SshSession =
      new SshSession(`ssh-${Date.now()}`, host, port, user, password, SshState.CONNECTING, '');
    sessions.push(session);
    AppStorage.set<SshSession[]>(Keys.SSH_SESSIONS, sessions);
    this.simulateSshConnect(session.id);
    return session;
  }

  removeSshSession(id: string): void {
    const sessions: SshSession[] = (AppStorage.get<SshSession[]>(Keys.SSH_SESSIONS) ?? []).slice();
    AppStorage.set<SshSession[]>(Keys.SSH_SESSIONS,
      sessions.filter((s: SshSession): boolean => s.id !== id));
  }

  private simulateSshConnect(id: string): void {
    setTimeout(() => {
      const sessions: SshSession[] = (AppStorage.get<SshSession[]>(Keys.SSH_SESSIONS) ?? []).slice();
      sessions.forEach((s: SshSession) => {
        if (s.id === id) {
          s.state = SshState.CONNECTED;
          s.output = `Connected to ${s.user}@${s.host}:${s.port}\r\n$ `;
        }
      });
      AppStorage.set<SshSession[]>(Keys.SSH_SESSIONS, sessions);
    }, 1200);
  }

  // ---- Preferences ----

  setThemeMode(mode: ThemeMode): void {
    AppStorage.set<ThemeMode>(Keys.THEME_MODE, mode);
  }

  advanced(): AdvancedSettings {
    return AppStorage.get<AdvancedSettings>(Keys.ADVANCED) ?? new AdvancedSettings();
  }

  saveAdvanced(settings: AdvancedSettings): void {
    AppStorage.set<AdvancedSettings>(Keys.ADVANCED, settings);
    // 下发给引擎：在此之前高级设置只停在 AppStorage，开关是「有界面、无行为」的。
    this.engine.setAdvancedOptions(settings);
  }

  splitTunneling(): SplitTunnelConfig {
    return AppStorage.get<SplitTunnelConfig>(Keys.SPLIT_TUNNELING) ?? new SplitTunnelConfig();
  }

  saveSplitTunneling(config: SplitTunnelConfig): void {
    AppStorage.set<SplitTunnelConfig>(Keys.SPLIT_TUNNELING, config);
  }

  clearFirstLaunch(): void {
    AppStorage.set<boolean>(Keys.FIRST_LAUNCH, false);
  }
}
