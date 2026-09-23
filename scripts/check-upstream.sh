#!/usr/bin/env bash
# 比对当前 HEAD 与上游 netbirdio/android-client，判断是否需要同步。
#
# 用法：
#   check-upstream.sh --upstream-ref <ref> [--out <文件>]
#
# 行为：
#   - 无差异：打印说明，输出 HAS_UPDATES=false，不写文件，退出 0
#   - 有差异：把「同步 Issue 正文」写进 --out，输出 HAS_UPDATES=true，退出 0
#   - 上游 ref 不存在：报错退出 3（**不允许静默失败**——取不到上游时被当成
#     「无更新」，会让定时检查变成摆设）
#
# 输出最后一行固定为 HAS_UPDATES=true|false，供 CI 解析。
# 兼容 macOS 自带 bash 3.2：不使用关联数组、mapfile 等特性。
set -euo pipefail

usage() { echo "用法: $0 --upstream-ref <ref> [--out <文件>]" >&2; exit 2; }

upstream_ref=""
out=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream-ref) upstream_ref="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

if [[ -z "$upstream_ref" ]]; then
  usage
fi

if ! git rev-parse --verify --quiet "${upstream_ref}^{commit}" >/dev/null 2>&1; then
  echo "找不到上游 ref：${upstream_ref}（应先 git fetch upstream）" >&2
  exit 3
fi

# 上游领先的提交数。HEAD 已合并过以前的上游提交，所以这里是增量而非全量。
count="$(git rev-list --count "HEAD..${upstream_ref}")"

if [[ "$count" -eq 0 ]]; then
  echo "上游无新提交：HEAD 已包含 ${upstream_ref} 的全部提交。"
  echo "HAS_UPDATES=false"
  exit 0
fi

if [[ -z "$out" ]]; then
  echo "有 ${count} 个新提交，但未指定 --out，无法写出 Issue 正文" >&2
  exit 2
fi

# 展示上游「自上次同步以来」的改动：从合并基点算起，而不是 HEAD 与 ref 的
# 全量 diff——后者会把我们自己的鸿蒙端改动也算进去，看不出上游到底改了什么。
merge_base="$(git merge-base HEAD "$upstream_ref")"

{
  echo "本仓库 Android 侧是 [netbirdio/android-client](https://github.com/netbirdio/android-client)"
  echo "的只读镜像，定时检查发现上游有新提交。"
  echo ""
  echo "**上游领先 \`${count}\` 个提交**（自上次同步基点 \`$(git log -1 --format=%h "$merge_base")\` 起）："
  echo ""
  echo '```'
  git log --no-decorate --date=short --format='%h %s (%an, %ad)' "${merge_base}..${upstream_ref}"
  echo '```'
  echo ""
  echo "**上游改动范围**："
  echo ""
  echo '```'
  git diff --stat "$merge_base" "$upstream_ref" | tail -40
  echo '```'
  echo ""
  echo "### 同步步骤"
  echo ""
  echo '```bash'
  echo "git fetch upstream --prune"
  echo "git checkout -b chore/sync-upstream origin/main"
  echo "git merge ${upstream_ref} -m \"chore: 同步上游 main（<主题>）\""
  echo "# 把 .github/upstream-sync.txt 的值更新为 git rev-parse ${upstream_ref}"
  echo '```'
  echo ""
  echo "用 **merge commit** 合并（保留上游血缘，不要 squash），流程细节见"
  echo "\`docs/MAINTAINER_GUIDE.md\`「同步上游」。"
  echo ""
  echo "> 上游改动若涉及**鸿蒙要对齐的行为**（判据、排序、交互语义等），按维护"
  echo "> 闭环**另立 Issue 移植**并补测试，不要塞进同步 PR。"
  echo ""
  echo "_本 Issue 由 \`.github/workflows/upstream-check.yml\` 定时创建/更新；"
  echo "同步完成后关闭即可，下次有新提交会自动重开。_"
} > "$out"

echo "上游领先 ${count} 个提交，Issue 正文已写入 ${out}"
echo "HAS_UPDATES=true"
