# Engine / ArkTS 规范

覆盖 `harmony/entry/src/main/ets/engine/**`、`model/**`、`common/**` 及一切
ArkTS 逻辑代码。规则来源：PR #16 修复的 44 个真实编译错误、移植审查
（Issue #7–#10）、CI 首跑。

## 第一规则：真实编译器是唯一可靠门禁

`harmony/tools/static-verify.mjs` 做结构校验，**查不出 ArkTS 严格模式错误**。
PR #16 首次真实编译时暴露 44 个错误，静态验证此前全部绿。

- 每个改动 PR 合并前，本机必须跑一次：
  `hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon`
  （在 `harmony/` 目录下；环境变量见 `docs/TROUBLESHOOTING.md`）
- CI 的 harmony-build 工作流是第二道网，但它慢（分钟级）——本地先跑

## ArkTS 硬规则（每条都有真实报错）

### 命名与声明

- **自建类/函数不得与 ArkUI 内置组件重名**。`NavRouter` 工具类与内置
  `NavRouter` 组件冲突，报 `Value of type 'typeof NavRouter' is not callable`，
  已改名 `AppNav`（`common/NavRouter.ets`）。新增工具类前先确认名字不撞
  内置组件（NavList/NavRow/Toggle 等都是高危名）。
- **`@Observed` 必须紧贴它装饰的类**。在 `@Observed class Peer` 上方插入
  别的类会把装饰器「偷走」，报 `The type of the @ObjectLink property 'peer'
  can only be objects of classes decorated with @Observed`。新增类放到
  文件尾部（PeerSort 就是这么处理的）。

### 类型

- **函数/lambda 必须显式返回类型**（`arkts-no-implicit-return-types`）。
  给静态方法补上返回类型，调用方 lambda 的同类报错往往一起消失——
  根因修复优于逐处补。
- **`unknown` 必须显式收窄**。`ctx.pathInfo.param` 是 `unknown`，写
  `const param = ctx.pathInfo.param as Object | undefined` 再判断。
- **UI 属性参数的联合类型要贴 SDK 声明**。`Text(value)` 只收
  `string | Resource`，不是 `ResourceColor`；`DetailRow` 的 value 参数
  因此写成 `string | Resource`（`pages/PeerDetailPage.ets`）。
- **组件属性不得与基类成员重名**。`StatusDot` 的 `size` 与 CustomComponent
  基类冲突，改名 `dotSize`。

### 组件规则

- **`Blank()` 只能嵌在 Row/Column/Flex**（`pages/ProfilesPage.ets:199` 真实
  报错）；列表占位用 `Row()` 替代。
- **`TextInput` 的 placeholder 走构造参数**
  `TextInput({ text: this.input, placeholder: "command" })`，
  `.placeholder()` 属性形式在此 SDK 上不存在。
- **NavDestination 标题不接受 Resource**，且 `NavDestinationCustomTitle` 的
  `height` 必填。统一写法（六页面既有模式）：

  ```ts
  @Builder
  DestTitle() {
    Text($r('app.string.xxx'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }
  // ...
  .title({ builder: this.DestTitle, height: TitleHeight.MainOnly })
  ```

  `wrapBuilder`/全局 `@Builder` 都不行（WrappedBuilder 与 `(() => any)`
  不兼容），必须局部 `@Builder` + `this.` 引用。SDK 升级后重新评估。

## 引擎抽象层契约（架构级，不可破坏）

```
engine/
├── VpnEngine.ets        端口契约：run/stop/peers/resources/selectRoute/…
├── EngineEvents.ets      回调契约：onStateChanged/onPeersChanged/…
├── EngineManager.ets     单例门面：实现 EngineObserver，回调写 AppStorage
└── MockVpnEngine.ets     演示实现（有意为之）
```

- **页面只依赖 `EngineManager` + `AppStorage`**（`@StorageLink` 响应式），
  绝不直接 import 引擎实现
- **`EngineManager` 构造处是唯一引擎注入点**（`new MockVpnEngine()`）；
  接真实引擎 = 新增一个 `VpnEngine` 实现 + 改这一行，UI 零改动
- **AppStorage key 一律走 `common/Constants.ets` 的 `Keys`**——魔法字符串
  key 曾散落四页，PR #21 全部收敛；新增 key 先加进 `Keys`
- **`MockVpnEngine` 的演示性质声明不得删除**（类注释、README、SECURITY.md
  三处都有）；改它的行为必须同步 logic-tests

## 测试与验证

- **引擎/模型层改动必须补 `harmony/tools/logic-tests.mjs` 断言**——它把
  ArkTS 转译为 .mts 用 node --test 真实执行，是未来真实引擎接入的验收规格
  （MockVpnEngine 生命周期、竞态回归、PeerSort 排序都在这里）
- 竞态类修复必须带回归测试（范例：`MockVpnEngine rapid stop/run race`，
  PR #16——stop 的延迟 teardown 未记录句柄导致快速断开/重连卡态）
- 定时器句柄必须记录并在清理函数统一 clear（`clearTimers()` 模式）

## 资源与文案（逻辑层部分）

- 用户可感知文案一律走 `$r('app.string.*')`；PR #21 清理过一轮硬编码英文
- 纯逻辑层（Formatters 等）返回的文案暂允许英文常量——它们被 logic-tests
  断言，外置需随 i18n 体系（GitHub Issue #15）一起做
- 新增 string 资源按原格式最小 diff 插入（`{ "name": ..., "value": ... }`
  单行式），不要 json.dumps 整体重排（PR #20 教训：6 行变更变 612 行）
