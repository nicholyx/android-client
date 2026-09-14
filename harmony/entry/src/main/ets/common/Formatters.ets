/*
 * Display formatting helpers shared by the peer detail, home and resources
 * screens. Mirrors the formatting the Android adapters do inline (byte counts,
 * "time ago" for the last handshake, and the session-expiry countdown).
 */
export class Formatters {
  private static readonly UNITS: string[] = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  /** Human-readable byte count, e.g. 1_420_000 -> "1.4 MB". */
  static bytes(value: number): string {
    if (value <= 0) {
      return '0 B';
    }
    let amount: number = value;
    let unit: number = 0;
    while (amount >= 1024 && unit < Formatters.UNITS.length - 1) {
      amount /= 1024;
      unit++;
    }
    const rounded: number = unit === 0 ? amount : Math.round(amount * 10) / 10;
    return `${rounded} ${Formatters.UNITS[unit]}`;
  }

  /** Latency with colour band semantics: good under 150ms, high above 300ms. */
  static latencyColor(latencyMs: number): Resource {
    if (latencyMs <= 0) {
      return $r('app.color.nb_txt_light');
    }
    if (latencyMs < 150) {
      return $r('app.color.nb_latency_good');
    }
    if (latencyMs < 300) {
      return $r('app.color.nb_latency_high');
    }
    return $r('app.color.nb_danger');
  }

  /**
   * Session countdown text from a Unix-seconds deadline, matching the plurals
   * in the Android strings (minutes / hours / days).
   */
  static sessionCountdown(expiresAtUnixSeconds: number): string {
    if (expiresAtUnixSeconds <= 0) {
      return '';
    }
    const nowSeconds: number = Math.floor(Date.now() / 1000);
    const delta: number = expiresAtUnixSeconds - nowSeconds;
    if (delta <= 0) {
      return 'Session expired';
    }
    const minutes: number = Math.floor(delta / 60);
    if (minutes < 1) {
      return 'Session expires in less than a minute';
    }
    if (minutes < 60) {
      return minutes === 1 ? 'Session expires in 1 minute' : `Session expires in ${minutes} minutes`;
    }
    const hours: number = Math.floor(minutes / 60);
    if (hours < 24) {
      return hours === 1 ? 'Session expires in 1 hour' : `Session expires in ${hours} hours`;
    }
    const days: number = Math.floor(hours / 24);
    return days === 1 ? 'Session expires in 1 day' : `Session expires in ${days} days`;
  }

  /** Relative time from a "yyyy-MM-dd HH:mm:ss" UTC stamp. */
  static timeAgo(timestamp: string): string {
    if (timestamp === null || timestamp.length === 0 || timestamp === '0001-01-01 00:00:00') {
      return '-';
    }
    const parsed: number = Date.parse(timestamp.replace(' ', 'T') + 'Z');
    if (Number.isNaN(parsed)) {
      return timestamp;
    }
    const deltaSeconds: number = Math.floor((Date.now() - parsed) / 1000);
    if (deltaSeconds < 60) {
      return 'Just now';
    }
    const minutes: number = Math.floor(deltaSeconds / 60);
    if (minutes < 60) {
      return `${minutes}m ago`;
    }
    const hours: number = Math.floor(minutes / 60);
    if (hours < 24) {
      return `${hours}h ago`;
    }
    return `${Math.floor(hours / 24)}d ago`;
  }
}
