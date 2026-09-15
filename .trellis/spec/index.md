# Spec 导航

本目录是 android-client 的编码规范，供 AI 会话在动手前自动注入。
所有规则都来自真实代码与真实踩坑（ArkTS 编译错误、移植审查、CI 首跑），
每条都给出处。

## 这个项目是什么、改什么

一句话：**NetBird VPN 客户端，双端仓库——但只维护鸿蒙端。**

- **改动范围只限 `harmony/`**（HarmonyOS NEXT，ArkTS/ArkUI）及其配套
  （`harmony/tools/` 测试、CI 工作流、docs）
- `app/`、`tool/`、`gomobile/`、`netbird/` 是 Android 侧**存量参考代码**：
  只读对照，不修改、不重构；行为对齐问题以 Android 实现为语义基准
- 引擎层现状：`VpnEngine` 接口 + MockVpnEngine 演示实现，真实引擎在
  Roadmap（GitHub Issue #25）规划中

## 按任务类型选择要读的 spec

| 你要动什么 | 先读 |
| --- | --- |
| `harmony/entry/src/main/ets/engine/**`、模型层（model/）、任何 ArkTS 逻辑代码 | [engine/index.md](engine/index.md) —— **必读**，含 ArkTS 硬规则 |
| 页面（pages/）、组件（components/）、资源（resources/） | [ui/index.md](ui/index.md) |
| 构建失败 / CI 红了 / 工具链问题 | 仓库 `docs/TROUBLESHOOTING.md`（按报错原文检索） |
| 设计判断（该不该做、怎么取舍） | [guides/index.md](guides/index.md) |

## Pre-Development Checklist（任何任务动手前）

1. 读上表对应的 spec 入口
2. `bash scripts/lint.sh` 必须先跑一遍确认基线是绿的
3. GitHub 侧上下文（Issue、里程碑、看板、发布门禁）见
   `.claude/skills/maintain-loop/SKILL.md`——Trellis 管知识与任务上下文，
   该 skill 管 Issue/PR/打包/发布闭环，两边不重复收藏

## Quality Check（任何任务收尾前）

- [ ] `bash scripts/lint.sh` 全绿（harmony 测试 + shellcheck + 提交规范 + 乱码扫描）
- [ ] **本机真实编译**：`hvigorw assembleHap`（见 engine/index.md——静态验证
      替代不了编译器，这是本项目最大的教训）
- [ ] 改了引擎/模型层 → `harmony/tools/logic-tests.mjs` 补对应断言
- [ ] 改了用户可感知行为 → `CHANGELOG.md` 的 `[Unreleased]` 记一条
- [ ] 中文内容全仓无 U+FFFD 乱码（lint.sh 第 4 步）
- [ ] CI 全绿才合并；合并方式与发布红线见 maintain-loop skill
