# Maintenance / GitHub 维护规范

本目录收录 GitHub 侧流程的操作视角（会话开始自动注入）。完整命令参考与
验收清单见 `.claude/skills/maintain-loop/SKILL.md`——两边是同一套内容，
改任何一边必须同步另一边。

来源：PR #2/#4/#18/#29 建立的流程 + 用户明确要求的发布门禁
（Issue #30 固化进 spec）。

## 核心闭环

```
Issue（先有 Issue） → 分支 → 实现 + 测试 → PR → CI 全绿 → squash 合并
  → Issue 自动关闭 → 打包（artifact） → 人工验收 → 打 tag 发布
```

## GitHub 流程硬规则

- **所有 gh 命令带 `-R nicholyx/android-client`**——fork 会把不带 -R 的
  调用解析到上游 netbirdio/android-client，曾经真实误操作过上游的
  Issue 列表（本仓库第一大坑）
- **分支从最新 origin/main 切出**（先 fetch）——基于过期 main 开发会产出
  回退性 diff（真实踩过，靠 `git apply -3` 抢救）
- **一个 Issue 一个分支一个 PR**：`feat/*`、`fix/*`、`docs/*`、`ci/*`、
  `chore/*`
- **提交规范 Conventional Commits**：`type(scope): 标题`，正文写为什么；
  CI 校验 PR 标题与区间内每个提交（squash 后标题即提交信息）
- **小批量提交**：完成一个小功能就提交
- **PR 正文四段**：为什么 → 做了什么 → 关键取舍（含被否方案）→ 测试策略；
  正文写 `Closes #N`。**正文写临时文件用 `--body-file`，绝不用嵌套
  heredoc**——正文会静默丢失（真实踩过：PR 建出来正文为空）
- **CI 全绿才合并**：`gh pr merge <N> -R nicholyx/android-client --squash
  --delete-branch`；分支保护只盯 `CI 总览` 一个 check，落后 main 时先
  rebase + `--force-with-lease`
- **用户可感知改动记入 `CHANGELOG.md` 的 `[Unreleased]`**（六分类固定，
  不自创）；插入锚点必须校验在正确版本段内

## 打包与发布门禁（红线，用户明确要求）

1. **自动构建的包绝不发布 Release**：harmony-build 工作流产物只进
   artifact（run 页面 `harmony-hap-debug`），出测试包用
   `gh workflow run harmony-build.yml -R nicholyx/android-client`
2. **发布只在人工验收后**：维护者真机安装测试（验收清单见 maintain-loop
   skill 第六节），**全绿之前不打 tag**；用户确认后才允许打 tag
3. **tag 触发发布**：`git ls-remote --tags origin vX.Y.Z` 确认无同名 tag →
   `git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z` → release.yml
   自动构建 HAP 附件 + CHANGELOG 版本段 + GitHub 原生发布说明
4. 预发布 tag（含 `-`）自动 `--prerelease`，不占 latest
5. 任何时候不主动 push tag / 创建 Release，只响应用户明确指令

## 同步上游（Android 侧镜像）

Android 侧保持与上游一致、**不做本地改写**，因此同步是「镜像」而不是合并两家改动。

- 步骤：`git fetch upstream` → 看清有哪些新提交 → 建 `chore/sync-upstream` 分支
  → `git merge upstream/main -m "chore: 同步上游 main（<主题>）"` → 更新
  `.github/upstream-sync.txt` 为新值 → PR → CI → 合并
- **用 merge commit 合并（`--merge`），不要 squash**：merge 让 git 记住已合过的
  上游提交，后续同步只处理增量；squash 会让每次同步从分叉点重新比对
- 完成后核对对齐：`git diff upstream/main HEAD --stat -- app/ tool/ gomobile/ netbird/`
  应为空
- **提交规范豁免**：上游提交信息不由我们命名。`--upstream-marker` 跳过
  `.github/upstream-sync.txt` 所记提交**及其祖先**。判据必须是祖先关系——
  作者/分支名/标签都可伪造，等于开后门；标记文件在仓库内受 PR 审查

## 路线图与追踪

- **Roadmap Issue #25 是路线图单一事实来源**：规划后条目进「计划中」，
  完成后移入「已完成」并带 Issue/PR 链接
- 里程碑挂版本主题；Issue 入 Projects 看板（`gh project item-add`，
  owner 用 `@me`，当前看板编号 3）
- 标签体系：bug/enhancement/documentation/ci/automation/governance/
  harmony/android/release/good first issue/help wanted

## shell 脚本硬规则（scripts/ 与 CI 内联脚本）

- **变量名不得紧贴中文**：`echo "跳过 $f（CI）"` 里 bash 会把多字节字符并入变量名，
  报 `f?: unbound variable`。一律写 `${f}`。这类写法只在特定分支触发，极易潜伏
  （lint.sh 真实案例：只在 shellcheck 未安装时才炸）
- **`while IFS= read -r` 会丢掉没有尾换行的最后一行**，写
  `while IFS= read -r line || [[ -n "$line" ]]` 兜底（`printf '%s'` 丢尾换行
  是同一类陷阱的另一面）
- 兼容 macOS 自带 bash 3.2：不用 `declare -A`、`mapfile`、`wait -n`、`tac`

## 其他红线

- 凭证 / 内网地址不进代码、Issue、日志；`${{ }}` 不直接进 `run:`
- zizmor 豁免集中在 `.github/zizmor.yml`，每条必须写可验证的安全依据；
  不弱化分支保护
- 中文内容编辑后跑 U+FFFD 扫描（`scripts/lint.sh` 第 4 步）——历史上
  至少三次抓到提交信息/文档混入
- MockVpnEngine 演示性质声明不得删除（README/SECURITY/类注释三处）
