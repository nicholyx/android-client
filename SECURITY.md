# 安全政策

## 报告漏洞

**请不要用公开 Issue 报告安全漏洞。**

使用 GitHub 的「 privately report a vulnerability 」功能私密上报
（仓库 Security 标签页 → Report a vulnerability），维护者会在 7 天内确认、
90 天内给出处置结论。

## 威胁模型（什么算安全漏洞）

本项目是 VPN 客户端，以下情况视为安全漏洞：

- **凭证泄露**：登录凭证、setup key、SSH 口令被写入日志、导出文件或崩溃报告
- **管理面伪造**：与 management 服务端的连接可被中间人劫持或证书校验被绕过
- **隧道失效**：流量在未建立/已断开隧道时经明文网络发出（VPN 客户端最经典的失效模式）
- **引擎注入**：打包进应用的引擎二进制可被替换或降级（供应链）
- **提权**：应用申请了超出 VPN 功能所需的系统能力/权限

以下情况**不**视为本仓库的安全漏洞：

- NetBird 内核（Go）本身的漏洞 → 请上报 [netbirdio/netbird](https://github.com/netbirdio/netbird/security/advisories)
- Android/HarmonyOS 平台自身的漏洞 → 请上报对应厂商
- 演示用 Mock 引擎的「假数据」（`harmony/entry/src/main/ets/engine/MockVpnEngine.ets`
  是有意为之的演示实现，不含真实凭证；真实引擎接入前它不是攻击面）

## 支持的版本

只修最新 main 分支；发布版本（Release）出问题请先确认在最新代码上是否复现。
