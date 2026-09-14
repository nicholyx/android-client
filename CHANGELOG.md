# 更新日志

本项目的全部显著改动记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增

- HarmonyOS NEXT 客户端（`harmony/`）：Stage 模型 + ArkTS + ArkUI 声明式 +
  Navigation 路由，13 个页面对齐 Android 全部 Fragment；VPN 引擎抽象层
  （`VpnEngine` 端口契约 + `EngineManager` 单例门面），当前注入 MockVpnEngine
  驱动全部界面端到端演示，接入真实引擎时 UI 层零改动
- CI 门禁：harmony 测试（Node 无 SDK）、脚本 shellcheck、Conventional Commits
  校验、zizmor 工作流安全扫描（--strict 基线 0 findings）、`CI 总览` 汇总 job
- HarmonyOS HAP 自动构建工作流：commandline-tools 5.0.5.200 在 GitHub runner
  真实编译，产物上传 artifact 供安装测试（自动构建不发布 Release）
- 仓库自动化：PR 路径标签、首次贡献者欢迎、stale 处置、OSSF Scorecard、
  dependabot（Actions 生态 + 7 天 cooldown）
- Release 工作流：`v*` tag 触发，构建 HAP 附件 + CHANGELOG 版本段 +
  GitHub 原生发布说明；预发布 tag 不标 latest
- 治理文件：CONTRIBUTING、SECURITY（含威胁模型）、SUPPORT、CODEOWNERS、
  Issue/PR 模板
- 文档：USAGE / ARCHITECTURE / TROUBLESHOOTING / MAINTAINER_GUIDE 四件套
- 测试：PeerSort 排序、MockVpnEngine 快速断开/重连竞态回归、
  sessionCountdown ceil 语义断言

### 修复

- MockVpnEngine.stop() 的延迟 teardown 竞态：快速断开/重连不再被旧回调清空
  状态卡在 DISCONNECTED
- 会话倒计时文本此前永不刷新（自增的 tick 未被 build() 引用），并改 ceil 取整
  对齐 Android formatSessionExpiry
- SSH 终端按 sessionId 精确匹配会话（同 host 同 user 的两条会话此前串扰）；
  SSH 删除、profile 切换/登出/删除补确认对话框；删除按钮阻断事件冒泡
- Peers/Networks 列表补排序（已连接优先/按名称），对齐 Android 适配器
- FirstInstall 自建服务器地址此前只进 toast 即被丢弃，现真实写入 profile
- Advanced 的开关不再把半输入态 PSK 误落盘（仅显式保存按钮落盘）；
  rosenpass permissive 与主开关联动门控
- 详情页逐行复制（IP/IPv6/公钥），硬编码英文文案外置到资源，魔法存储 key
  收敛到 Keys 常量，版本号改经 bundleManager 读取

### 变更

- harmony 编译目标升至 SDK 5.0.1(13)（与 commandline-tools 5.0.5.200 自带
  SDK 一致），compatibleSdkVersion 保持 5.0.0(12) 兼容旧设备
- hvigor-config.json5 移除本版 schema 不允许的 pluginRepository 键
