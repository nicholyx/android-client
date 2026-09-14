# 架构说明

面向想改代码的人，重点写「为什么这样设计」以及被否掉的方案。

## 仓库全貌

```
├── app/            Android 应用层（Fragment/ViewModel/UI）
├── tool/           Android 服务层（VPNService、通知、磁贴、Preferences）
├── gomobile/       gomobile 绑定，把 NetBird Go 内核暴露给 Android
├── netbird/        Go 内核（git 子模块，指向 netbirdio/netbird）
├── harmony/        HarmonyOS NEXT 客户端（ArkTS/ArkUI）
│   ├── entry/src/main/ets/
│   │   ├── entryability/   EntryAbility：初始化 store + 加载窗口
│   │   ├── model/          数据模型（Peer/Status/Resource/Profile/SshSession/Settings）
│   │   ├── engine/         VPN 引擎抽象层（本文重点）
│   │   ├── common/         常量/格式化/主题/URL/路由
│   │   ├── components/     可复用 UI 组件
│   │   └── pages/          全部页面（Navigation + NavPathStack 单页路由）
│   └── tools/              Node 测试与静态验证（无需 SDK）
├── scripts/        lint.sh、check-commit-msg.sh
└── docs/           本目录
```

## 引擎抽象层（harmony 的核心决策）

### 为什么有这层

Android 的核心是 gomobile 封装的 NetBird Go 引擎 + Android `VpnService` 的
TUN 通道。HarmonyOS **没有 gomobile 运行时**，第三方应用也不能直接照搬
Android 式 VpnService。若 UI 直接调用引擎，移植就变成一次性重写；若 UI 与
引擎之间只有接口，真实引擎可以渐进接入。

### 端口契约

```
engine/
├── VpnEngine.ets        端口契约：run/stop/peers/resources/selectRoute/…
├── EngineEvents.ets     回调契约：onStateChanged/onPeersChanged/…
├── EngineManager.ets    单例门面：实现 EngineObserver，把回调写入 AppStorage
└── MockVpnEngine.ets    进程内模拟实现（有意为之，见下）
```

- 页面只依赖 `EngineManager` + `AppStorage`（`@StorageLink` 响应式刷新）。
- 引擎实现只依赖 `VpnEngine` 接口；`EngineManager` 构造处是唯一注入点
- 接入真实引擎 = 提供另一个 `VpnEngine` 实现 + 改一行注入，UI 零改动

### MockVpnEngine 是「有意为之」还是「偷懒」？

是有意为之。理由：

1. UI 先行可以在没有底层方案的阶段被真实点击、真实验收（引导页 → 连接 →
   peer 列表 → SSH 全流程可演示）
2. 它定义了「引擎必须表现成什么样」的可执行规格——新引擎接入时直接拿
   logic-tests 里的引擎测试当验收标准
3. 它是**演示声明**而不是伪装：README 与 SECURITY.md 都写明其演示性质，
   不把它当攻击面

被否掉的方案：在 UI 层用 `if (mock)` 分支模拟状态——那样 mock 逻辑散落各处，
真实引擎接入时删不干净。

### 真实引擎的两条可行路径（见 Issue「真实 VPN 引擎接入」）

1. **NAPI（推荐）**：Go 内核交叉编译为 `ohos` 目标 .so，NAPI 绑定调
   ArkTS；数据面用 HarmonyOS 系统能力建隧道
2. 重写数据面（兜底，工作量大）

两条路径实现同一个 `VpnEngine` 接口。定稿前先出调研结论记录到本文件。

## 状态流

```
EntryAbility.onCreate → EngineManager.getInstance().init()
  → seeds AppStorage（CONNECTION_STATE/PEERS/PROFILES/…）
页面 ← @StorageLink 响应 AppStorage
用户意图（点连接） → 页面 → EngineManager.switchConnection(on)
  → engine.run()/stop() → 回调 → EngineManager 写 AppStorage → 页面刷新
```

对应 Android 侧 `MainActivity(ServiceAccessor + StateListenerRegistry)` +
各 ViewModel 的合并；单一门面降低了跨页状态同步的心智负担。

## 与 Android 的对照

| Android | HarmonyOS | 说明 |
| --- | --- | --- |
| `mobile_navigation.xml` + BottomNav | `Navigation` + 5 Tab `Index.ets` | 单 Activity ↔ 单 Page |
| `ServiceAccessor` + `StateListenerRegistry` | `EngineManager` | 回调→状态的桥 |
| `VPNService`（前台服务） | 待接入（平台能力见 Issue） | 长时任务 + 常驻通知 |
| `PeersAdapter.sortPeers` | `PeerSort.compare` | 已连接优先 + 显示名 |
| `Preferences`/`ProfileManager` | 待持久化（Issue） | 每次冷启动重置是已知缺口 |
| xterm.js + WebView SSH | 原生终端视图（mock 回显） | 真实 SSH 见 Issue |

## 已知取舍记录

- **Peers 排序键用显示名而非 Android 的 fqdn**：无 FQDN 的 peer 按 fqdn
  （空串）排最前视觉上是乱序；显示名回落 IP 更符合直觉
- **NavDestination 标题用局部 @Builder**：SDK 5.0.1 的 `title()` 不接受
  Resource 且 CustomTitle 的 `height` 必填——升级 SDK 后可评估简化
- **`NavRouter` 工具类改名 `AppNav`**：与 ArkUI 内置 NavRouter 组件重名，
  编译期无法通过
- **AppStorage key 全部集中在 `Keys`**：跨页字符串 key 曾出现漂移风险
