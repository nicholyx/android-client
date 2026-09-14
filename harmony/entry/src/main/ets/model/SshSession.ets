/*
 * An SSH session shown in the SSH tab. Mirrors the shape of the Android
 * SshSession / SshSessionStore entries: a target host, credentials and the
 * rolling terminal output buffer.
 */

export enum SshState {
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  PASSWORD_REQUIRED = 'password_required',
  CLOSED = 'closed',
  ERROR = 'error'
}

@Observed
export class SshSession {
  id: string;
  host: string;
  port: number;
  user: string;
  password: string;
  state: SshState;
  /** Terminal title, defaults to user@host. */
  title: string;
  /** Accumulated terminal output. */
  output: string;

  constructor(id: string, host: string, port: number, user: string, password: string,
    state: SshState, title: string) {
    this.id = id;
    this.host = host;
    this.port = port;
    this.user = user;
    this.password = password;
    this.state = state;
    this.title = title.length > 0 ? title : `${user}@${host}`;
    this.output = '';
  }

  static stateLabel(state: SshState): string {
    switch (state) {
      case SshState.CONNECTING:
        return 'connecting';
      case SshState.CONNECTED:
        return 'connected';
      case SshState.PASSWORD_REQUIRED:
        return 'password required';
      case SshState.ERROR:
        return 'error';
      default:
        return 'closed';
    }
  }
}
