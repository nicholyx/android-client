---
name: maintain-loop
description: android-client（NetBird Android + HarmonyOS 双端客户端）仓库的维护闭环流程——规划、实现、测试、打包、人工验收、发布的完整循环，以及本项目踩坑沉淀的硬规则。当需要在项目中继续迭代（新功能、修缺陷、补文档）、出安装测试包、发布新版本、盘点未完成事项，或有人说「继续」「走维护流程」「按开源流程开发」「打个包」时使用。
---

# 维护闭环（android-client）

本仓库（`nicholyx/android-client`）按真实开源项目方式维护：小批量提交、
Issue 驱动、PR 门禁、版本发布。双端并存：Android（`app/`+`tool/`+`gomobile/`）
与 HarmonyOS NEXT（`harmony/`）。

**核心闭环**：`规划 → 实现 → 测试 → 打包 → 人工验收 → 发布 → 继续规划`。
其中「打包 → 人工验收 → 发布」是本仓库特有的发布门禁，顺序不可跳。

> 开发会话开始前：`git fetch origin && git pull`；所有 gh 命令必须带
> `-R nicholyx/android-client`（fork 会把不带 -R 的调用解析到上游
> netbirdio/android-client——这是本仓库第一大坑）。

## 一、盘点现状

```bash
gh issue list -R nicholyx/android-client --state open --json number,title
gh pr list -R nicholyx/android-client --state open
gh run list -R nicholyx/android-client --branch main --limit 3
git -C . status --short && git log --oneline -3
```

检查点：本地与远端一致、main 的 CI 总览绿、CHANGELOG `[Unreleased]` 是否积压。

## 二、规划

1. 建里程碑（版本主题），如「v0.2.0：HarmonyOS 客户端预览」
2. 一个任务一个 Issue，结构固定：**背景 / 期望（验收 checkbox）/ 入手位置 /
   难度**，打对应标签（harmony/android/ci/documentation…）
3. Issue 入 Projects 看板；Roadmap Issue 是路线图单一事实来源

## 三、实现

- **一个 Issue 对应一个分支、一个 PR**：`feat/*`、`fix/*`、`docs/*`、
  `ci/*`、`chore/*`
- 动手前核实 Issue 前提；偏离计划先留言改范围，发现新缺陷另立 Issue
- **小批量提交**：完成一个小功能就提交；提交信息 Conventional Commits，
  正文写为什么
- 分支必须从**最新 origin/main** 切出（先 fetch；基于过期 main 开发会产出
  回退性 diff，本项目真实踩过，靠 `git apply -3` 才抢救回来）

### 本项目硬规则（代码层）

- ArkTS 只有真实编译器能拦住错误——**每个 PR 合并前在本机跑一次
  `hvigorw assembleHap`**（环境见 docs/TROUBLESHOOTING），静态验证不够
- 自建类不得与 ArkUI 内置组件重名（NavRouter 教训）
- `@Observed` 必须紧贴类声明；往被装饰类上方插代码会把装饰器「偷走」
- AppStorage key 全部走 `Keys` 常量；用户可感知文案全部走 `$r` 资源
- NavDestination 标题按 `@Builder DestTitle + TitleHeight.MainOnly` 既有写法
- 引擎层改动必须同步补 logic-tests（`harmony/tools/logic-tests.mjs`），
  它是真实引擎接入时的验收规格

### shell 脚本（scripts/ 与 CI 内联）

- **变量名不得紧贴中文**：`"跳过 $f（CI）"` 会让 bash 把多字节字符并入变量名，
  报 `f?: unbound variable`；一律写 `${f}`。只在特定分支触发，极易潜伏
  （`lint.sh` 真实案例：只在 shellcheck 未安装时才炸）
- **`while IFS= read -r` 会丢没有尾换行的最后一行**：写
  `while IFS= read -r line || [[ -n "$line" ]]` 兜底

## 四、测试（发布门禁第一道）

```bash
bash scripts/lint.sh                              # 本地：与 CI 同一套
cd harmony && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

- CI 跑：harmony 静态验证 + 逻辑测试、shellcheck、zizmor（--strict）、
  提交规范 → 汇总为 `CI 总览` 一个 check
- 设备层（DevEco 端到端 UI 测试、真机手测）CI 跑不了，属于下面的人工验收

## 五、打包（自动构建，不发 Release）

- PR/push/手动触发的 `harmony-build` 工作流产出 unsigned HAP artifact
  （run 页面 `harmony-hap-debug`）
- 要给使用者出测试包：`gh workflow run harmony-build.yml -R nicholyx/android-client`
  （在 main 上跑），下载 artifact 并记录 sha256
- **自动构建的包绝不发布 Release**；也不必签名——测试包配 DevEco 自动签名
  或 AGC 调试证书安装

## 六、人工验收（发布门禁第二道，维护者执行）

打包后由维护者在真机安装测试，验收清单：

- [ ] 首次引导页（Cloud/Self-hosted）→ 进入主界面（引导页只出现一次）
- [ ] 连接开关状态机（connecting → connected → disconnecting → disconnected），
      快速反复切换不卡态
- [ ] 底部 5 Tab 全部可进、peer/资源列表排序与搜索、peer 详情逐行复制
- [ ] SSH 会话新建/删除（有确认框）、终端进入不串会话
- [ ] Profiles 增/切/登出/删（均有确认框）、主题切换、Advanced 开关 +
      PSK 显式保存
- [ ] 深浅色跟随系统、杀进程重启后状态合理

验收发现问题 → 按第二节流程修（Issue → PR → 合并 → 重新打包），
**全绿之前不打 tag**。

## 七、发布（人工验收通过后）

1. 切 `chore/release-vX.Y.Z`：CHANGELOG `[Unreleased]` 归档为
   `[X.Y.Z] - 日期`（插入锚点必须校验在正确版本段内），`[Unreleased]` 恢复空壳
2. 发布 PR 走完整 CI，squash 合并
3. 确认远端无同名 tag 后：`git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z`
4. release.yml 自动构建 HAP 附件 + CHANGELOG 版本段 + GitHub 原生发布说明；
   含 `-` 的 tag（预发布）不占 latest
5. 验证 `gh release view vX.Y.Z`；更新 Roadmap Issue 与看板
6. 发布幂等：push tag 前先 `git ls-remote --tags origin vX.Y.Z` 确认不存在

## 八、发布后

Roadmap 条目移入「已完成」（带 Issue/PR 链接）；开下一版本里程碑与 Issue。

## 九、同步上游（Android 侧镜像）

Android 侧保持与上游一致、只读；同步是「镜像」不是合并两家改动。

平时不必手动盯：`upstream-check` 工作流每周自动比对，有差异就开/更新
`upstream-sync` 标签的 Issue（无差异静默、取不到上游则报错）。手动补查：

```bash
git fetch upstream --prune
bash scripts/check-upstream.sh --upstream-ref upstream/main --out /tmp/up.md  # 末行 HAS_UPDATES=true|false
git log --oneline origin/main..upstream/main     # 有哪些新提交
git checkout -b chore/sync-upstream origin/main
git merge upstream/main -m "chore: 同步上游 main（<主题>）"
# 更新 .github/upstream-sync.txt 为 `git rev-parse upstream/main` 的值
git diff upstream/main HEAD --stat -- app/ tool/ gomobile/ netbird/   # 应为空
```

- **用 merge commit 合并（`gh pr merge --merge`），不要 squash**：merge 让 git
  记住已合过的上游提交，后续同步只处理增量；squash 会让每次同步从分叉点重新
  比对，冲突面越滚越大
- 上游提交信息不由我们命名，`.github/upstream-sync.txt` + `--upstream-marker`
  跳过该提交及其祖先。**判据必须是祖先关系**——作者/分支名/标签都能伪造
- 上游改动若涉及鸿蒙要对齐的行为（如本次的 DNS 解析器判据），按第三节照常
  立 Issue → 分支 → 移植 + 测试 → PR，不要塞进同步 PR 里

## 红线

- 自动构建产物（artifact）不发布 Release；Release 只在人工验收后打 tag 触发
- 凭证/内网地址不进代码、Issue、日志；`${{ }}` 不直接进 `run:`
- zizmor 豁免必须写可验证的安全依据；不弱化分支保护
- MockVpnEngine 的演示性质声明不得删除

## 快速命令

| 操作 | 命令 |
| --- | --- |
| 本地全量检查 | `bash scripts/lint.sh` |
| 本机编译 HAP | 见 docs/USAGE.md「命令行构建」 |
| 手动出测试包 | `gh workflow run harmony-build.yml -R nicholyx/android-client` |
| 合并 PR | `gh pr merge <N> -R nicholyx/android-client --squash --delete-branch` |
| 发布 | tag 推送触发 release.yml |
| 乱码扫描 | `bash scripts/lint.sh` 第 4 步 |
