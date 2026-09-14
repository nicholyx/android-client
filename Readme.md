<br/>
<div align="center">
<p align="center">
  <img width="234" src="https://raw.githubusercontent.com/netbirdio/netbird/main/docs/media/logo-full.png"/>
</p>
  <p>
     <a href="https://github.com/netbirdio/netbird/blob/main/LICENSE">
       <img height="20" src="https://www.gnu.org/graphics/gplv3-88x31.png" />
     </a>
    <a href="https://docs.netbird.io/slack-url">
        <img src="https://img.shields.io/badge/slack-@netbird-red.svg?logo=slack"/>
     </a>    
  </p>
</div>


<p align="center">
<strong>
  Start using NetBird at <a href="https://netbird.io/pricing">netbird.io</a>
  <br/>
  See <a href="https://netbird.io/docs/">Documentation</a>
  <br/>
   Join our <a href="https://docs.netbird.io/slack-url">Slack channel</a>
  <br/>

</strong>
</p>

<br>

# NetBird Android client

The NetBird Android client allows connections from mobile devices running Android to private resources in the NetBird network.

## Screenshots

<p align="center">
  <img src="docs/screenshots/mainscreen.png" alt="mainscreen" width="250" style="margin-right: 10px;"/>
  <img src="docs/screenshots/peer-overview.png" alt="peer-overview" width="250" style="margin-right: 10px;"/>
  <img src="docs/screenshots/peer-detail.png" alt="peer-detail" width="250"/>
</p>

## Install
You can download and install the app from the Google Play Store:

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" alt="Get it on Google Play" height="80">](https://play.google.com/store/apps/details?id=io.netbird.client)


## HarmonyOS NEXT client

本仓库同时维护 **HarmonyOS NEXT** 客户端（`harmony/` 子目录），采用 Stage 模型 +
ArkTS + ArkUI 声明式 + Navigation 路由的官方最新标准技术栈，页面与 Android 版
逐一对齐；VPN 引擎经抽象层隔离，当前注入 MockVpnEngine 驱动全部界面端到端演示，
真实引擎接入时 UI 层零改动（详见架构文档）。

CI 自动构建可安装的 HAP 测试包（Actions 页面 artifact `harmony-hap-debug` 下载，
unsigned，真机安装需 AGC 调试证书）；Release 仅在人工验收后由维护者打 tag 发布。

## Documentation

| 文档 | 内容 |
| --- | --- |
| [docs/USAGE.md](docs/USAGE.md) | 构建安装：Android APK 与 HarmonyOS HAP、CI 拿包、签名、测试分层 |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 架构与设计取舍：引擎抽象层、状态流、双端对照 |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 排错：SDK 版本、ohpm 注册表、ArkTS 编译错误、CI 失败 |
| [docs/MAINTAINER_GUIDE.md](docs/MAINTAINER_GUIDE.md) | 维护者手册：仓库配置、开发闭环、发布流程、红线 |
| [harmony/README.md](harmony/README.md) | HarmonyOS 工程细节：技术栈对照、页面映射、测试体系 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献流程与提交规范 |
| [CHANGELOG.md](CHANGELOG.md) | 更新日志 |

路线图见 Roadmap Issue（链接在 Issue 列表置顶）。

## Building from source
### Requirements
We need the following software:
* Java 1.11. Usually comes with Android Studio
* android studio initialized with jdk and emulator (not covered here, is a req from android-client project)
* gradle (https://gradle.org/install/)

### Prepare development environment
1. Close all repositories:
> assuming you use a path like ~/projects locally
```shell
mkdir ~/projects
cd projects
# clone netbird repo
git clone --recurse-submodules git@github.com:netbirdio/android-client.git
```
2. Checkout the repositories to the branches you want to test. If you want the latest, check the status information on your IDE or on https://github.com and verify the branch list and commit history.
3. Export JDK and Android home vars, on macOS they are: (please contribute with Linux equivalent)
```shell
# replace <USERNAME> with your name
export ANDROID_HOME=/Users/<USERNAME>/Library/Android/sdk
export JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```
4. Install NDK and CMake
```shell
cd ~/projects/android-client
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --install "ndk;23.1.7779620"
```
### Generate debug bundle
Follow the steps to run locally until the step 5 then run the following steps:
1. Build Go agent library
```shell
cd ~/projects/android-client
./build-android-lib.sh
```
2. Run gradlew
```shell
cd ~/projects/android-client/android
./gradlew bundleDebug  -PversionCode=123 -PversionName=1.2.3
```
