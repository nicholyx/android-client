import { Peer } from '../model/Peer';
import { Resource } from '../model/Resource';
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
