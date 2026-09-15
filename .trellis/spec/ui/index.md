# UI / ArkUI 规范

覆盖 `harmony/entry/src/main/ets/pages/**`、`components/**`、
`entry/src/main/resources/**`。规则来源：移植审查（Issue #8/#9/#10）与
对应修复 PR #19/#20/#21。

## 页面与路由

- 单 Page 架构：只有 `pages/Index.ets` 有 `@Entry`，其余页面全是
  `NavDestination`；路由表在 `Index.ets` 的 PageMap 与 `common/NavRouter.ets`
  的 `Routes`——**新增页面必须三处同步**（Routes 枚举、PageMap、
  `resources/base/profile/main_pages.json` 不需要动，它只含 pages/Index）
- 页面跳转用 `AppNav.push(Routes.X, param)`，参数对象放页面文件底部导出
  （范例 `SshTarget`）；param 是 `unknown`，接收端先 `as` 收窄
- 标题统一用局部 `@Builder DestTitle` 模式（见 engine/index.md「组件规则」）

## 交互模式（对齐 Android 语义基准）

- **破坏性操作必须确认**：删除 SSH 会话、profile 切换/登出/删除一律
  `AlertDialog.show`（范例 `pages/ProfilesPage.ets`，对齐 Android
  `ProfilesFragment.createDialog`）。确认文案用资源 key
  （`*_confirm` 已有 4 条）
- **行内按钮与整行点击解耦**：列表行内嵌套可点元素时，内层加
  `.hitTestBehavior(HitTestMode.Block)` 阻断冒泡——SSH 删除按钮曾同时
  触发整行的进终端跳转（PR #20）
- **列表排序语义**：Peers 用 `PeerSort.compare`（已连接优先、按显示名），
  Networks 按名称；新列表沿用「对齐 Android 适配器 + 显示名优先」原则
- **按 id 精确匹配实体**，不用 host+user 这类可重复字段（SSH 会话串扰
  教训，PR #20）
- **关键交互带无障碍 id**：`connect_toggle`、`connection_status`、
  `first_install_continue`、`tab_0..tab_4`——设备端 UI 测试
  （`entry/src/ohosTest/`）靠它们定位

## 资源

- **文案一律 `$r('app.string.*')`**，不允许硬编码（PR #21 清理过一轮）；
  toast 等拼句用 `resourceManager.getStringSync($r(...).id)` 取前缀再拼接
- **颜色必须走资源**（`base/element/color.json` + `dark/element/color.json`
  成对添加）——明暗主题靠限定目录切换，硬编码色值会破坏暗色 parity
  （`static-verify.mjs` 会查 dark/base 对账）
- 版本号等动态信息经 `bundleManager.getBundleInfoForSelfSync` 读取，不硬编码
- 新增资源条目按原格式最小 diff 插入（见 engine/index.md）
- 引用不存在的资源 key 会编译失败（`Unknown resource name`）——新增 key
  先落 string.json 再引用；`sys.symbol.*` 图标只用 static-verify 白名单
  里已验证过的，新图标需在 DevEco 里确认存在后再用（`doc_on_doc` 不在
  符号表的真实教训）

## 状态管理

- 跨页状态一律 `AppStorage` + `@StorageLink`，key 走 `Keys` 常量
- **派生文案必须落 `@State` 才会重渲染**：倒计时文本曾绑定为方法调用
  `Text(Formatters.sessionCountdown(...))`，定时器自增的 tick 未被 build()
  引用导致永不刷新（PR #16）。模式：`@State xxxText` + 显式重算函数 +
  `setInterval`/`@Watch` 驱动
- `aboutToAppear` 建的定时器必须在 `aboutToDisappear` 清理（成对出现）
