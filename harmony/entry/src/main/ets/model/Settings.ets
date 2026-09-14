/*
 * Advanced / Network & Security toggles, mirroring the flags the Android
 * AdvancedFragment reads and writes through the gomobile engine config.
 */
@Observed
export class AdvancedSettings {
  presharedKey: string = '';
  rosenpassEnabled: boolean = false;
  rosenpassPermissive: boolean = false;
  disableClientRoutes: boolean = false;
  disableServerRoutes: boolean = false;
  disableDns: boolean = false;
  disableFirewall: boolean = false;
  disableIpv6: boolean = false;
  allowSsh: boolean = false;
  blockInbound: boolean = false;
  forceRelay: boolean = false;
  allowRemoteJobs: boolean = false;
  traceLog: boolean = false;
}

/*
 * Split-tunneling selection. On Android this enumerates installed launcher
 * apps; HarmonyOS restricts that enumeration, so the model carries the mode
 * and an explicit list of bundle names the user manages.
 */
@Observed
export class SplitTunnelEntry {
  bundleName: string;
  label: string;
  selected: boolean;

  constructor(bundleName: string, label: string, selected: boolean) {
    this.bundleName = bundleName;
    this.label = label;
    this.selected = selected;
  }
}

@Observed
export class SplitTunnelConfig {
  mode: string = 'off';
  entries: SplitTunnelEntry[] = [];
}
