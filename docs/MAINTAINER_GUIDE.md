# 维护者手册

仓库配置清单、日常闭环、发布流程与红线。

## 仓库配置清单（网页端/API 已落实项）

| 项 | 状态 | 说明 |
| --- | --- | --- |
| Issues / Discussions | ✅ 已开启 | config.yml 指向 Discussions，空白 Issue 禁用 |
| 分支保护（main） | ⚠️ 见下 | API 配置，见「分支保护」 |
| Projects 看板 | ⚠️ 见下 | Roadmap Issue 入看板 |
| Actions 权限 | ✅ enabled，all | |
| 标签体系 | ✅ | bug/enhancement/documentation/ci/automation/governance/harmony/android/release/good first issue/help wanted |
| Private vulnerability reporting | ⚠️ 网页端开启 | Settings → Code security → Private vulnerability reporting |
| GitHub Pages（可选） | ❌ 未配 | |

### 分支保护（已执行 / 变更时重跑）

```bash
gh api repos/{owner}/{repo}/branches/main/protection -X PUT --input - <<'JSON'
{ "required_status_checks": {"strict": true, "contexts": ["CI 总览"]},
  "required_pull_request_reviews": {"dismiss_stale_reviews": true, "required_approving_review_count": 0},
  "enforce_admins": false, "restrictions": null,
  "allow_force_pushes": false, "allow_deletions": false,
  "required_conversation_resolution": true }
JSON
```

- `contexts` 用检查显示名 `CI 总览`（ci-summary job 的 name），增删检查项不用改保护规则
- 单人维护：`required_approving_review_count: 0`——不要求别人审批，CI 仍是硬门禁
- Android 的 build-debug / instrumented-tests / unit-tests 是信息性检查，
  未纳入必需上下文（fork 上已验证可跑，是否转门禁由维护者决定）

## 日常闭环（Issue → PR → 合并）

1. **先有 Issue**：一个开发任务一个 Issue（背景/期望/入手位置/难度）
2. **一个 Issue 一个分支一个 PR**：`feat/*`、`fix/*`、`docs/*`、`ci/*`、`chore/*`
3. **动手前核实 Issue 前提**：代码在演进，前提不成立时先留言改范围
4. **小批量提交**：完成一个小功能就提交
5. **本地先跑 `bash scripts/lint.sh`**（与 CI 同一套）
6. **PR 正文**：为什么 → 做了什么 → 关键取舍（含被否方案）→ 测试策略；`Closes #N`
7. **CI 全绿才 squash 合并**：`gh pr merge <N> --squash --delete-branch`
8. **用户可感知改动进 CHANGELOG 的 `[Unreleased]`**

### 已踩坑（工程纪律沉淀）

- PR/Issue 正文**写临时文件再 `--body-file`**，绝不用嵌套 heredoc——正文会
  静默丢失（本项目真实发生：PR 建出来正文为空）
- 每次编辑中文内容后跑 U+FFFD 扫描（lint.sh 第 4 步）；长中文句不做匹配锚点
- gh 在 fork 仓库会把 Issue/PR 解析到上游——**所有 gh 命令必须带
  `-R nicholyx/android-client`**
- 从 origin/main 切分支前先 `git fetch`：基于过期 main 开发会在 PR 里混入
  回退性 diff（本项目真实发生，靠 `git apply -3` 抢救）
- 修改 YAML 工作流的结构性块（插入 with: 等）逐个手工做，不用批量脚本

## 发布流程（release.yml）

1. 人工验收通过（设备层测试全跑 + 实机安装验证）后才允许发布
2. 从最新 main 切 `chore/release-vX.Y.Z`，把 CHANGELOG `[Unreleased]` 归入
   `[X.Y.Z] - 日期`，`[Unreleased]` 恢复空壳；发布 PR 走完整 CI
3. squash 合并后确认远端无同名 tag：`git ls-remote --tags origin vX.Y.Z`
4. `git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z` → release.yml 自动：
   构建 HAP → 收集 CHANGELOG 版本段 → `gh release create --generate-notes`
5. 预发布（tag 含 `-`，如 `v0.2.0-rc1`）自动 `--prerelease`，不占 latest
6. 验证：`gh release view vX.Y.Z` 三段式内容齐全

## 供应链基线

- 所有**本仓库维护**的工作流 `uses:` pin 到 commit SHA（注释保留版本号），
  checkout 一律 `persist-credentials: false`
- zizmor `--strict` 只扫本仓库维护的 7 个工作流；豁免集中在
  `.github/zizmor.yml`，每条必须写明可验证的安全依据
- 上游继承的 build-*.yml 未 pin SHA——已知事项，随上游同步漂移，不纳入
  我们的基线（纳入会让上游变更变成我们的红灯）
- `${{ }}` 不直接写进 `run:`，用户输入经 `env:` 中转
- dependabot 只管 Actions 生态（gradle 与 netbird 子模块由上游流程管理）

## 红线（任何时候不得违反）

- 凭证 / 内网地址不进代码、不进 Issue、不进日志
- 自动构建产物（artifact）不发布 Release；Release 只在人工验收后打 tag 触发
- 不给任何工作流加 schedule 触发的「同步」类任务（stale/scorecard 的定时
  仅读仓库状态，不写内容）
- 不弱化分支保护；不无据豁免 zizmor 发现
- MockVpnEngine 的演示性质必须在 README/SECURITY 保持声明，不得伪装成真实引擎

## 需要维护者手动配置的事项

1. **AGC 签名材料**（.p12/.cer/.p7b + 口令）配成 Secrets 后，可在
   harmony-build/release 接入 hap-sign-tool 自动签名
2. 网页端开启 **Private vulnerability reporting**（SECURITY.md 的上报渠道依赖它）
3. Projects 看板创建并把 Roadmap Issue 入板（`gh project create/item-add`，
   需要 `project` scope——已具备）
