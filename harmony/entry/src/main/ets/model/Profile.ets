/*
 * A saved connection profile. Mirrors io.netbird.client.tool.Profile: a
 * management-server binding the user authenticates against. Exactly one is
 * active at a time.
 */
@Observed
export class Profile {
  id: string;
  name: string;
  email: string;
  isActive: boolean;
  /** Management server base URL, e.g. https://api.netbird.io. */
  serverUrl: string;
  /** True for NetBird Cloud, false for a self-hosted management server. */
  isCloud: boolean;

  constructor(id: string, name: string, email: string, isActive: boolean,
    serverUrl: string, isCloud: boolean) {
    this.id = id;
    this.name = name;
    this.email = email === null ? '' : email;
    this.isActive = isActive;
    this.serverUrl = serverUrl;
    this.isCloud = isCloud;
  }
}
