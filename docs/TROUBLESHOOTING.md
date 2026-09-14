# 排错手册

现象（保留报错原文）→ 原因 → 解决。每条注明「什么情况下不该用这个方案」。

## HarmonyOS 构建

### `SDK component missing. Please verify the integrity of your SDK.`

- **原因**：`build-profile.json5` 的 `compileSdkVersion` 指向的 SDK 版本在
  commandline-tools 里不存在。例如工程锁 `5.0.0(12)`，而工具链 5.0.5.200 自带
  的 SDK 是 `5.0.1(13)`——hvigor 按项目要求的版本号扫描，扫不到就报这句。
- **解决**：把 `compileSdkVersion`/`targetSdkVersion` 升到工具链自带的版本
  （`5.0.1(13)`），`compatibleSdkVersion` 保持 `5.0.0(12)` 兼容旧设备。
- **不该用的场景**：如果你能从华为官网装齐 5.0.0(12) 的 SDK，锁定旧版本
  编译也是合理选择——本仓库选升级是因为 CI 上的工具链包只带一个 SDK。

### `Error: Hvigor config file .../hvigor/hvigor-config.json5 does not exist.`

- **原因**：在仓库根目录执行了 `hvigorw`。
- **解决**：`cd harmony` 后再执行——hvigor 工程根是 `harmony/` 子目录。

### hvigor 报 `pluginRepository` 不在 allowed values

- **原因**：旧版/手写的 `hvigor-config.json5` 带 `pluginRepository` 键，
  hvigor 5.x 的 schema 不允许。
- **解决**：删掉该键，顶层只保留 modelVersion/dependencies/execution/
  logging/debugging/nodeOptions/properties。

### `ERROR: Found exception: FetchError: request to https://mirrors.tools.huawei.com/ohpm/...`

- **原因**：ohpm 默认注册表是华为内网镜像，公网不可达。
- **解决**：`ohpm config set registry https://ohpm.openharmony.cn/ohpm/`
- **不该用的场景**：企业内网若能直连内网镜像，保留默认更快。

### `Argument of type 'Resource' is not assignable to ... NavDestination title`

- **原因**：SDK 5.0.1 的 `NavDestination.title()` 不接受 Resource，
  `NavDestinationCustomTitle` 的 `height` 还是必填字段。
- **解决**：按页面内局部 `@Builder DestTitle()` + `.title({ builder:
  this.DestTitle, height: TitleHeight.MainOnly })` 的既有写法。

### `Value of type 'typeof NavRouter' is not callable`

- **原因**：自建路由工具类与 ArkUI 内置 `NavRouter` 组件重名，编译器解析到
  内置组件。
- **解决**：不要起与内置组件同名的类名（已改名 `AppNav`）。

### `@ObjectLink` 报 `can only be objects of classes decorated with @Observed`

- **原因**：多见于装饰器与类声明被拆开——在 `@Observed` 与 `class` 之间插了
  别的类，装饰器「落到」了新类上。
- **解决**：检查 `@Observed` 紧贴自己的目标类；新增类放到文件尾部。

### ArkTS 报 `arkts-no-implicit-return-types`

- **原因**：ArkTS 严格模式要求函数/lambda 显式返回类型；静态验证工具查不出，
  只有真实编译器会报。
- **解决**：补显式返回类型。给静态方法补返回类型时，调用方 lambda 的同类
  报错会一起消失（根因修复优于逐处补）。

## CI

### 提交规范检查失败

- **报错**：`✗ 提交标题不符合 Conventional Commits：...`
- **解决**：`type(scope): 标题` 格式；PR 标题与区间内每个提交都要合规
  （squash 合并后 PR 标题就是提交信息）。

### zizmor 报 cache-poisoning / dangerous-triggers

- **解决**：先看能不能根治（如 release.yml 直接去缓存）；确需豁免时在
  `.github/zizmor.yml` 增加条目并写明**可验证的安全依据**，禁止无据豁免。

### fork 上 Actions 没有跑

- **原因**：fork 的 Actions 默认关闭或需要手动批准首次 workflow。
- **解决**：仓库 Settings → Actions → 允许 all actions；首次触发的
  workflow 在 Actions 页面手动批准。

## 工程卫生

### 中文内容里混入 U+FFFD 替换字符

- **原因**：多轮编辑/转码把非法字节替换成 U+FFFD，肉眼难察觉。
- **解决**：`bash scripts/lint.sh` 第 4 步会扫描全部 tracked 文本文件；
  编辑中文内容后必跑。历史上它至少三次抓到提交信息/文档里的混入。

### git add 目录时带入了 oh_modules

- **原因**：`harmony/.gitignore` 写 `/oh_modules` 只匹配顶层；依赖装在
  `harmony/entry/oh_modules`。
- **解决**：gitignore 用 `oh_modules/`（无前导斜杠，匹配任意层级）。
