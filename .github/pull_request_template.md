<!--
关联 Issue：正文写 `Closes #N`，合并后自动关闭。
提交规范：PR 标题遵循 Conventional Commits（squash 合并后它就是提交信息），
区间内每个提交同样遵循——CI 会校验两者。
-->

## 为什么

<!-- 引用 Issue；两三句话说清动机，不写空话 -->

## 做了什么

-

## 关键取舍

<!-- 含被否掉的方案：为什么这么选、为什么不那么选 -->

## 测试策略

<!-- 本地跑了什么（bash scripts/lint.sh / 设备端测试）；改动如何被测试覆盖 -->

- [ ] `bash scripts/lint.sh` 本地通过
- [ ] 有用户可感知的改动已记入 `CHANGELOG.md` 的 `[Unreleased]`
