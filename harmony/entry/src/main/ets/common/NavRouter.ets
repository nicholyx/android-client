/*
 * Route names for the Navigation stack plus a tiny holder so any component can
 * push a sub-page without threading the NavPathStack through every constructor.
 * This replaces the Android NavController the fragments looked up from the host.
 */
export class Routes {
  static readonly PEER_DETAIL: string = 'PeerDetail';
  static readonly ADVANCED: string = 'Advanced';
  static readonly SPLIT_TUNNELING: string = 'SplitTunneling';
  static readonly TROUBLESHOOT: string = 'Troubleshoot';
  static readonly ABOUT: string = 'About';
  static readonly PROFILES: string = 'Profiles';
  static readonly FIRST_INSTALL: string = 'FirstInstall';
  static readonly SSH_TERMINAL: string = 'SshTerminal';
}

export class AppNav {
  private static stack: NavPathStack | null = null;

  static bind(stack: NavPathStack): void {
    AppNav.stack = stack;
  }

  static push(name: string, param?: Object): void {
    if (AppNav.stack !== null) {
      AppNav.stack.pushPathByName(name, param);
    }
  }

  static pop(): void {
    if (AppNav.stack !== null) {
      AppNav.stack.pop();
    }
  }

  /** Replace the whole stack, used to jump to first-run onboarding. */
  static reset(name: string): void {
    if (AppNav.stack !== null) {
      AppNav.stack.clear();
      AppNav.stack.pushPathByName(name, undefined);
    }
  }
}
