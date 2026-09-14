# 使用手册

从零跑起来：构建、安装、测试、拿包。

## 前置条件

| 端 | 工具 | 版本要求 |
| --- | --- | --- |
| Android | Android Studio + JDK | SDK 与 JDK 由 `gradle/gradle-daemon-jvm.properties` 锁定 |
| Android | Go + NDK | 由 `build-android-lib.sh` 解析（构建 gomobile 引擎时需要） |
| HarmonyOS | DevEco Studio | 5.x 及以上 |
| HarmonyOS | commandline-tools | 5.0.5.200（与工程 SDK 目标匹配，见下） |
| 两端通用 | Node.js | ≥ 18（跑 harmony 逻辑测试与静态验证，无需任何 SDK） |

克隆时带子模块（`netbird` 是 Go 内核）：

```shell
git clone --recursive <仓库地址>
```

## 快速验证（不装任何 SDK）

```shell
bash scripts/lint.sh                                # 与 CI 同一套：harmony 测试 + shellcheck + 提交规范 + 乱码扫描
cd harmony && node tools/run-all-tests.mjs          # 仅 harmony 测试
```

通过标准：静态验证 0 FAIL、逻辑测试全部 pass。这两层在 CI 的
「HarmonyOS 静态验证与逻辑测试」检查中原样执行。

## 构建 Android

```shell
bash build-android-lib.sh      # 先构建 NetBird Go 库（gomobile）
./gradlew assembleDebug        # 再打 APK
```

产物：`app/build/outputs/apk/debug/`。CI 里 `build-debug` 工作流做同样的事。

## 构建 HarmonyOS HAP

### DevEco Studio（推荐，含签名）

1. `File > Open` 打开 `harmony/` 子目录（不是仓库根目录）
2. 首次打开自动执行 `ohpm install` 与 hvigor sync
3. `File > Project Structure > Signing Configs` 勾选 **Automatically generate
   signature**（需登录华为账号，AGC 签发调试证书）
4. 连接真机或模拟器，Run 'entry'

### 命令行（无签名，出 unsigned 包）

```shell
cd harmony
ohpm config set registry https://ohpm.openharmony.cn/ohpm/   # 默认注册表内网不可达
ohpm install --all
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

产物：`harmony/entry/build/default/outputs/default/entry-default-unsigned.hap`。
需要设置：

- `DEVECO_SDK_HOME=<commandline-tools 路径>/sdk`
- `PATH` 加入 `<commandline-tools>/bin`（hvigorw、ohpm）

### CI 打包

`.github/workflows/harmony-build.yml` 在 PR / push（限 `harmony/**`）与手动
触发时构建，产物在 run 页面的 artifact **harmony-hap-debug** 下载。

**签名说明**：CI/命令行产物是 unsigned 包，真机安装需要华为 AGC 签发的调试
证书。两种方式：

1. DevEco 自动签名（个人测试最快）
2. 把 `.p12` 证书、`.cer`、`.p7b` profile 与口令配成仓库 Secrets，接入
   `hap-sign-tool` 签名步骤（规划中，见 Roadmap）

**发布**：Release 由维护者人工验收后打 `v*` tag 触发（release.yml），自动
构建产物永远不会直接进入 Release。

## 测试分层

| 层级 | 位置 | 运行方式 | 覆盖 |
| --- | --- | --- | --- |
| 静态验证 | `harmony/tools/static-verify.mjs` | Node 即可 | 配置/资源 parity/路由/装饰器/资源引用/字符串 key 覆盖 |
| 逻辑与引擎 | `harmony/tools/logic-tests.mjs` | Node 即可 | Formatters、状态机、MockVpnEngine、EngineManager 真实执行 |
| hypium 单测 | `harmony/entry/src/test/` | DevEco → Run Local Test | 不依赖 UI 的纯逻辑 |
| 端到端 UI | `harmony/entry/src/ohosTest/` | DevEco → Run 'ohosTest'（真机/模拟器） | 拉起应用、走引导页、点连接开关、遍历 Tab |

CI 跑前两层；后两层在设备上跑（CI 无 HarmonyOS 模拟器）。发版前设备层必须
人工跑一遍。
