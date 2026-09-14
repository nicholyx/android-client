/*
 * Central constants: AppStorage keys used for cross-page reactive state, plus
 * well-known URLs. Keeping the keys in one place avoids the stringly-typed
 * duplication that makes AppStorage access error-prone.
 */
export class Keys {
  static readonly CONNECTION_STATE: string = 'nb_connection_state';
  static readonly PEERS: string = 'nb_peers';
  static readonly RESOURCES: string = 'nb_resources';
  static readonly FQDN: string = 'nb_fqdn';
  static readonly IP: string = 'nb_ip';
  static readonly IPV6: string = 'nb_ipv6';
  static readonly SESSION_EXPIRES: string = 'nb_session_expires';
  static readonly PROFILES: string = 'nb_profiles';
  static readonly ACTIVE_PROFILE_ID: string = 'nb_active_profile_id';
  static readonly SSH_SESSIONS: string = 'nb_ssh_sessions';
  static readonly THEME_MODE: string = 'nb_theme_mode';
  static readonly ADVANCED: string = 'nb_advanced';
  static readonly SPLIT_TUNNELING: string = 'nb_split_tunneling';
  static readonly FIRST_LAUNCH: string = 'nb_first_launch';
  static readonly TRACE_LOG: string = 'nb_trace_log';
}

export class Urls {
  static readonly DOCS: string = 'https://docs.netbird.io';
  static readonly LICENSE: string = 'https://netbird.io/license';
  static readonly PRIVACY: string = 'https://netbird.io/privacy';
  static readonly LEARN_WHY_NO_PEERS: string = 'https://docs.netbird.io/how-to-why-no-peers';
  static readonly CLOUD_MANAGEMENT: string = 'https://api.netbird.io';
}

/** Theme selection, mirroring the Android Advanced → Theme Mode picker. */
export enum ThemeMode {
  SYSTEM = 'system',
  LIGHT = 'light',
  DARK = 'dark'
}

/** Split-tunneling mode, mirroring SplitTunnelConfig.Mode on Android. */
export enum SplitTunnelMode {
  OFF = 'off',
  INCLUDE = 'include',
  EXCLUDE = 'exclude'
}
