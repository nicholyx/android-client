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

## 路线图与追踪

- **Roadmap Issue #25 是路线图单一事实来源**：规划后条目进「计划中」，
  完成后移入「已完成」并带 Issue/PR 链接
- 里程碑挂版本主题；Issue 入 Projects 看板（`gh project item-add`，
  owner 用 `@me`，当前看板编号 3）
- 标签体系：bug/enhancement/documentation/ci/automation/governance/
  harmony/android/release/good first issue/help wanted

## 其他红线

- 凭证 / 内网地址不进代码、Issue、日志；`${{ }}` 不直接进 `run:`
- zizmor 豁免集中在 `.github/zizmor.yml`，每条必须写可验证的安全依据；
  不弱化分支保护
- 中文内容编辑后跑 U+FFFD 扫描（`scripts/lint.sh` 第 4 步）——历史上
  至少三次抓到提交信息/文档混入
- MockVpnEngine 演示性质声明不得删除（README/SECURITY/类注释三处）
