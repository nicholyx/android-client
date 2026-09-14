/*
 * Overall tunnel connection state driven by the engine, mirroring the
 * ConnectionState enum in the Android MainActivity and the desktop tray states.
 */

export enum ConnectionState {
  UNKNOWN = 'unknown',
  CONNECTED = 'connected',
  CONNECTING = 'connecting',
  DISCONNECTING = 'disconnecting',
  DISCONNECTED = 'disconnected',
  NO_NETWORK = 'no_network',
  NEEDS_LOGIN = 'needs_login'
}

export class ConnectionStateMapper {
  /** Translated status label shown under the connect toggle on the home screen. */
  static labelResource(state: ConnectionState): Resource {
    switch (state) {
      case ConnectionState.CONNECTED:
        return $r('app.string.main_status_connected');
      case ConnectionState.CONNECTING:
        return $r('app.string.main_status_connecting');
      case ConnectionState.DISCONNECTING:
        return $r('app.string.main_status_disconnecting');
      case ConnectionState.NO_NETWORK:
        return $r('app.string.main_status_no_network');
      case ConnectionState.NEEDS_LOGIN:
        return $r('app.string.main_status_login_required');
      default:
        return $r('app.string.main_status_disconnected');
    }
  }

  /** True while the tunnel is up or coming up (drives the home toggle). */
  static isOn(state: ConnectionState): boolean {
    return state === ConnectionState.CONNECTED || state === ConnectionState.CONNECTING;
  }
}
