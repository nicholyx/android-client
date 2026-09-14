# NetBird HarmonyOS 客户端

本工程是 NetBird Android 客户端（`../app`、`../tool`）向 **HarmonyOS NEXT** 的迁移版本，
采用华为官方**最新标准技术栈**构建，未使用任何已废弃的框架：

| 维度 | 采用的标准方案 | 说明 |
| --- | --- | --- |
| 应用模型 | **Stage 模型**（UIAbility / WindowStage） | 非 FA 模型 |
| 开发语言 | **ArkTS**（强类型 TypeScript 超集） | 非 JS/eTS 旧写法 |
| UI 框架 | **ArkUI 声明式**（`@Component` / `@Builder` / `build()`） | 非 XML 布局 |
| 路由 | **`Navigation` + `NavPathStack` + `navDestination`** | 官方推荐，替代旧 `router` |
| 状态管理 | **`AppStorage` + `@StorageLink/@StorageProp` + `@Observed/@ObjectLink`** | 跨页面响应式 |
| 图标 | **`SymbolGlyph` + `sys.symbol.*`** 系统符号 | 无位图依赖，随主题自适应 |
| 构建 | **hvigor + ohpm**（`build-profile.json5` / `oh-package.json5`） | DevEco Studio 5.x / API 12 |
| 明暗主题 | `resources/base` 与 `resources/dark` 限定目录 + `setColorMode` | 跟随系统或手动切换 |

---

## 目录结构

```
harmony/
├── AppScope/                      # 应用级配置（包名、版本、应用图标）
│   ├── app.json5
│   └── resources/base/…
├── entry/                         # 主 HAP 模块
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/      # 应用入口 EntryAbility
│   │   │   ├── model/             # 数据模型（Peer/Status/Resource/Profile/SshSession/Settings）
│   │   │   ├── engine/            # VPN 引擎抽象层（见下文）
│   │   │   ├── common/            # 常量、格式化、主题、URL、路由
│   │   │   ├── components/        # 可复用 UI 组件（状态点、列表项、设置行）
│   │   │   └── pages/             # 全部页面
│   │   ├── resources/             # base / dark 颜色、字符串、尺寸、图标
│   │   └── module.json5
│   ├── build-profile.json5
│   ├── oh-package.json5
│   └── obfuscation-rules.txt
├── build-profile.json5            # 工程级构建配置（API 12 / HarmonyOS）
├── oh-package.json5
├── hvigorfile.ts
└── hvigor/hvigor-config.json5
```

## 页面与 Android 对照

| HarmonyOS 页面 (`entry/src/main/ets/pages`) | 对应 Android |
| --- | --- |
| `Index.ets`（`Navigation` + 底部 5 Tab） | `MainActivity` + `mobile_navigation.xml` + BottomNav |
| `HomePage.ets` | `HomeFragment` / `fragment_home.xml` |
| `PeersPage.ets` | `PeersFragment` |
| `PeerDetailPage.ets` | `PeerDetailFragment` |
| `NetworksPage.ets` | `NetworksFragment`（Resources） |
| `SshSessionsPage.ets` | `SshSessionsFragment` |
| `SettingsPage.ets` | `SettingsFragment` |
| `AdvancedPage.ets` | `AdvancedFragment`（Network & Security + 主题） |
| `SplitTunnelingPage.ets` | `SplitTunnelingFragment` |
| `TroubleshootPage.ets` | `TroubleshootFragment` |
| `AboutPage.ets` | `AboutFragment` |
| `ProfilesPage.ets` | `ProfilesFragment` + `ProfileEditorDialog` |
| `FirstInstallPage.ets` | `FirstInstallFragment` |
| `SshTerminalPage.ets` | `SSHTerminalFragment`（xterm.js WebView → 原生终端视图） |

设计系统（颜色 / 明暗主题 / 字符串 / 尺寸）已从 `app/src/main/res/values{,-night}` 完整迁移到
`resources/base` 与 `resources/dark`，品牌橙 `#F58431`、卡片圆角、分隔线等均与 Android 版一致。

---

## 关键架构说明：VPN 引擎抽象层

Android 版的核心是一个 **Go 引擎（gomobile，经 JNI 调用）**，由 `tool/VPNService` +
`EngineRunner` 封装，并依赖 Android 的 `VpnService` 建立 TUN 通道。

HarmonyOS **没有 gomobile 运行时**，且第三方应用不能直接使用 Android 式的 `VpnService`。
因此本工程把「UI ↔ 核心」的边界抽象成一个清晰的接口，UI 层只依赖抽象、与具体实现解耦：

```
engine/
├── VpnEngine.ets        # 端口契约：run/stop/peers/resources/selectRoute/exitNode/… 
├── EngineEvents.ets     # 回调契约：连接状态、地址、Peer 列表、会话到期
├── MockVpnEngine.ets    # 可用的进程内实现，驱动整套 UI 端到端跑通
└── EngineManager.ets    # 单例门面：持有引擎、把回调写入 AppStorage、暴露 UI 意图
```

- 当前默认注入 **`MockVpnEngine`**：它模拟「connecting → connected」状态迁移、生成带混合状态的
  Peer/Resource 数据集、每 2 秒刷新流量计数、维护会话到期时间，因此**全部界面都可真实交互演示**。
- **接入真实引擎**时，只需提供另一个 `VpnEngine` 实现并在 `EngineManager` 构造函数中替换
  `new MockVpnEngine()`，UI/页面/状态层**无需任何改动**。真实实现的两条可行路径：
  1. 将 NetBird 的 Go 核心通过 **HarmonyOS NAPI（.so）** 交叉编译并以 ArkTS 绑定调用；
  2. 基于 HarmonyOS 的网络/隧道能力重写数据面。
  两者都实现同一个 `VpnEngine` 接口即可。

`EngineManager` 对应 Android 侧 `MainActivity(ServiceAccessor + StateListenerRegistry)`、
`VPNService`、`EngineRunner` 与各 `ViewModel` 的合并：它统一持有状态并把引擎回调桥接到
`AppStorage`，页面通过 `@StorageLink` 自动响应式刷新。

---

## 构建与运行

1. 安装 **DevEco Studio 5.x（或更新）**，并通过 SDK Manager 安装 **HarmonyOS API 12** 及以上。
2. `File > Open` 打开本 `harmony/` 目录（不是仓库根目录）。
3. 首次打开会自动执行 `ohpm install` 与 hvigor sync。
4. 连接 HarmonyOS 真机或启动模拟器，点击 **Run 'entry'**。
5. 真机运行需在 `File > Project Structure > Signing Configs` 配置自动签名。

> 命令行构建：在 `harmony/` 下执行 `hvigorw assembleHap --mode module -p product=default`
> （需本机已安装 DevEco 提供的 hvigor/ohpm 工具链）。

## 已知迁移取舍

- **SSH 终端**：Android 用 `assets/terminal` 下的 xterm.js + WebView。此处改为原生等宽滚动视图 +
  命令行 + 快捷键行；若需完整 xterm，可用 ArkUI `Web` 组件加载迁移后的 `rawfile` 资源。
- **分屏隧道（Split tunneling）**：HarmonyOS 不像 Android 那样开放枚举全部已安装应用，故应用列表
  来自本地配置项，模式（Off/Include/Exclude）逻辑保留。
- **快捷设置磁贴 / 前台服务通知 / Always-on VPN**：依赖平台专有能力，需在真实引擎接入阶段用
  HarmonyOS 的对应能力（服务卡片、常驻通知等）单独实现。
- **SSO 登录**：Android 用 Custom Tabs；HarmonyOS 无 Custom Tabs，`common/UrlOpener.ets` 通过
  隐式 Want 交由系统浏览器完成，设备码流程可按同样方式扩展。

---

## 测试与验证

工程自带四层验证，前两层**无需 HarmonyOS SDK，仅需 Node 18+ 即可自动化执行**：

| 层级 | 位置 | 运行方式 | 覆盖内容 |
| --- | --- | --- | --- |
| ① 静态验证引擎 | `tools/static-verify.mjs` | `node tools/static-verify.mjs` | 配置/JSON5、资源与暗色 parity、页面与 `@Entry`/路由表、`@Component` 均有 `build()`、import/export 解析、`$r` 资源存在性、`sys.symbol` 白名单、装饰器规则、括号平衡、`any` 禁用、引擎接口实现完整性 |
| ② 可执行逻辑/引擎测试 | `tools/logic-tests.mjs` | `node tools/logic-tests.mjs` | 将 ArkTS 逻辑模块转译为 `.mts` 并用 `node --test` **真实运行**：Formatters、StatusMapper、ConnectionStateMapper、Resource 出口节点判定、各模型、`MockVpnEngine` 连接/断开状态机、`EngineManager` 存储/多 Profile/SSH 会话生命周期 |
| 一键全部 | `tools/run-all-tests.mjs` | `node tools/run-all-tests.mjs` | 依次执行 ①② 并汇总 |
| ③ 鸿蒙原生单元测试 | `entry/src/test/` | DevEco Studio → Run Local Test | `@ohos/hypium`，覆盖不依赖 `$r`/`AppStorage` 的纯逻辑 |
| ④ 鸿蒙端到端 UI 测试 | `entry/src/ohosTest/` | DevEco Studio → Run 'ohosTest'（真机/模拟器） | `@kit.TestKit` 的 `Driver`：拉起 `EntryAbility`、关闭首次引导、点击连接开关驱动状态、遍历底部 5 个 Tab 并断言界面元素 |

③④ 为 HarmonyOS 官方标准测试工程（含 `TestAbility`、`OpenHarmonyTestRunner`、`test_pages`），
需在 DevEco Studio + 设备/模拟器上运行。为便于 UI 定位，关键交互元素已加无障碍 id：
`connect_toggle`、`connection_status`、`first_install_continue`、`tab_0..tab_4`。

当前本机（无 DevEco/SDK）已自动化执行 ①②，结果：

```
静态验证：PASS 54 / FAIL 0 / WARN 0
逻辑与引擎：tests 15 / pass 15 / fail 0
```
