# 贡献指南

感谢关注 NetBird 移动客户端（Android + HarmonyOS NEXT）！本文描述本仓库的协作方式。

## 快速开始

1. Fork / 克隆本仓库（Android 侧依赖 `netbird` 子模块，克隆时加 `--recursive`）
2. Android：Android Studio 打开仓库根目录；HarmonyOS：DevEco Studio 5.x 打开 `harmony/` 子目录
3. 改动后跑本地检查：`bash scripts/lint.sh`（与 CI 同一套）

## 开发流程（Issue 驱动）

```
Issue（认领或新建） → 分支 → 实现 + 测试 → PR → CI 全绿 → squash 合并 → Issue 自动关闭
```

- **一个 Issue 对应一个分支、一个 PR**。分支命名：`feat/*`、`fix/*`、`docs/*`、`ci/*`、`chore/*`
- 动手前先核实 Issue 描述的前提仍然成立（代码在演进）；发现范围要变，先在 Issue 里留言
- 实现中发现新的相关缺陷，起一个独立 Issue 记录，不要顺手混进当前 PR

## 提交规范（Conventional Commits）

```
type(scope): 标题
```

- `type`：`feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`
- `scope`：建议 `harmony` / `android` / `ci` / `docs` 等，可省略
- 标题用一句话说清「做了什么」；正文写**为什么**，不只是改了什么
- PR 标题同样遵循本规范（squash 合并后它就是 main 上的提交信息，CI 会校验两者）
- 小批量提交：完成一个小功能就提交一次，方便评审与回溯

## 本地检查

```bash
bash scripts/lint.sh        # harmony 测试 + shellcheck + 提交规范抽查 + 乱码扫描
cd harmony && node tools/run-all-tests.mjs   # 仅 harmony 快速测试
```

HarmonyOS 端到端 UI 测试需在 DevEco Studio + 真机/模拟器上运行
（`harmony/entry/src/ohosTest/`），有条件时请跑一遍。

## PR 要求

- 正文包含：为什么 → 做了什么 → 关键取舍（含被否掉的方案）→ 测试策略
- 关联 Issue：正文写 `Closes #N`，合并后自动关闭
- CI 全绿才会被合并；与评审意见的讨论解决后再合并

## 行为准则与许可

- 参与即表示同意 [行为准则](CODE_OF_CONDUCT.md)
- 提交实质贡献需签署 [贡献者许可协议（CLA）](CONTRIBUTOR_LICENSE_AGREEMENT.md)
- 本项目沿用上游 NetBird 的 GPL-3.0 许可证（见 [LICENSE](LICENSE)）
