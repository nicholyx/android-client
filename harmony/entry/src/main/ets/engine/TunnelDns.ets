/*
 * 隧道内解析器的取舍规则（引擎层策略，非演示代码）。
 *
 * 移植自 Android 隧道构建逻辑，上游修过一次**静默解析失败**——
 * netbirdio/android-client PR #266 / 提交 be8ec8e。
 *
 * 原先的判据是「系统是否报告 Private DNS 活跃」。这个标志在 **Automatic
 * 模式**下也为真（只要当前网络的解析器支持 TLS，运营商与不少家庭网络默认
 * 如此），于是 NetBird 域名与自定义 DNS 区域会莫名其妙解析不了，而且能否
 * 解析**取决于重建隧道时手机当时所在的网络**——同一台设备换个网络就变。
 *
 * 真正会冲突的只有「**配置了** Private DNS 主机名」这一种情况：系统会把所有
 * 查询走 TLS 发给该主机并拒绝明文 DNS，隧道里的普通解析器一次也用不上。
 * 而 Automatic 模式下系统会先探测 TLS、探测失败回落明文 DNS，Private DNS
 * 关闭时更是根本不问——这两种情况下隧道解析器都工作正常。
 *
 * 所以判据从「活跃标志」换成「主机名」：只有主机名非空才排除。
 *
 * 鸿蒙当前还没有真实隧道（见 Roadmap 的真实引擎接入），本模块是该引擎
 * **必须遵循**的规则，先落在这里并测试覆盖，避免真实实现落地时把上游踩过的
 * 坑再踩一遍。
 */
export class TunnelDns {
  /**
   * 是否应当把解析器装进隧道。
   * 仅当平台把 Private DNS 钉在某个主机名上时返回 false（此时装了也访问不到）。
   */
  static shouldAddTunnelResolver(platformPrivateDnsHostname: string | null): boolean {
    return platformPrivateDnsHostname === null || platformPrivateDnsHostname.length === 0;
  }

  /**
   * 隧道实际装入的解析器地址；返回空串表示不装。
   *
   * 两个输入分别来自两处：`disableDns` 是用户在 Advanced → Disable DNS 的
   * 选择（对应 Android 的 `advanced_disable_dns`），`platformPrivateDnsHostname`
   * 是平台设置（Android 由 DNSWatch 从 ConnectivityManager 读取；鸿蒙暂无
   * 等价能力，真实引擎接入时再补）。
   */
  static tunnelResolver(disableDns: boolean, platformPrivateDnsHostname: string | null,
    resolver: string): string {
    if (disableDns) {
      return '';
    }
    return TunnelDns.shouldAddTunnelResolver(platformPrivateDnsHostname) ? resolver : '';
  }
}