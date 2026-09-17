import { Peer } from '../model/Peer';
import { Resource } from '../model/Resource';
import { AdvancedSettings } from '../model/Settings';
import { EngineObserver } from './EngineEvents';

/*
 * The seam between the UI and the NetBird core.
 *
 * On Android the core is a Go library reached over JNI (io.netbird.gomobile),
 * wrapped by EngineRunner inside the VpnService. HarmonyOS has no gomobile
 * runtime, so this interface is the porting contract: a real integration plugs
 * a native engine (a HarmonyOS NAPI/.so build of the NetBird Go core, or a
 * re-implementation over the platform VPN API) behind this same surface, while
 * MockVpnEngine keeps the whole app runnable and demonstrable in the meantime.
 *
 * Everything the Android ServiceAccessor / EngineRunner exposed to the UI is
 * represented here so the ArkTS pages depend only on this abstraction.
 */
export interface VpnEngine {
  /** Start the tunnel, triggering SSO login when the profile needs it. */
  run(useDeviceCodeFlow: boolean): void;

  /** Stop the tunnel. */
  stop(): void;

  /** True while the run loop is active. */
  isRunning(): boolean;

  /** Engine status label ("Connected", "NeedsLogin", ...). */
  status(): string;

  /** Unix seconds at which the current auth session expires, 0 when unknown. */
  sessionExpiresAt(): number;

  /**
   * 隧道当前装入的解析器地址，空串表示没有装。
   *
   * 对齐 Android `IFace.prepareDnsSetting`：只有「用户禁用了 NetBird DNS」或
   * 「平台把 Private DNS 钉在某个主机名上」时才不装——判据与来由见
   * `TunnelDns.ets`（上游 PR #266 修过一次静默解析失败）。
   */
  tunnelDnsServer(): string;

  /**
   * 把高级设置下发给引擎。
   *
   * 对齐 Android 把用户配置传给 Go 内核的路径；在此之前鸿蒙侧的高级设置只写进
   * AppStorage，从未到达引擎层，开关是「只有界面、没有行为」的。
   * MockVpnEngine 目前只消费其中的 disableDns，其余字段由真实引擎接入时接上。
   */
  setAdvancedOptions(settings: AdvancedSettings): void;

  peers(): Peer[];

  resources(): Resource[];

  /** Routing peers that carry the shared resources, for the Resources screen. */
  exitNodes(): Resource[];

  selectRoute(route: string): void;

  deselectRoute(route: string): void;

  selectExitNode(peerAddress: string): void;

  /** Re-authenticate to push the session deadline out. */
  extendAuthSession(): void;

  cancelExtendAuthSession(): void;

  /** Produce a debug bundle key (Troubleshoot screen). */
  debugBundle(anonymize: boolean): string;

  /** Register / unregister the UI observer. */
  setObserver(observer: EngineObserver | null): void;
}
