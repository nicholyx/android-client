#!/usr/bin/env bash
# 本地统一入口：一条命令跑完 CI 的全部静态检查与快速测试。
# CI（.github/workflows/ci.yml）与这里跑的是同一套，避免「本地能过 CI 不过」。
# 兼容 macOS 自带 bash 3.2。
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

echo "==> [1/4] HarmonyOS 静态验证与逻辑测试"
if ! (cd harmony && node tools/run-all-tests.mjs); then
  fail=1
fi

echo "==> [2/4] shellcheck + bash -n（scripts/*.sh）"
shopt -u nullglob
for f in scripts/*.sh; do
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$f" || fail=1
  else
    echo "shellcheck 未安装，跳过 ${f}（CI 中始终执行）"
  fi
  bash -n "$f" || fail=1
done

echo "==> [3/4] Conventional Commits 抽查（最近 4 条我们命名的提交）"
# 只检查我们命名的提交：上游镜像提交（祖先命中 .github/upstream-sync.txt）与
# GitHub/git 自动生成的合并提交都由脚本跳过——PR 用 merge commit 合并时
# （上游同步需要保留血缘，见 docs/MAINTAINER_GUIDE.md）main 上会周期性出现
# "Merge pull request #N from …"，判它违规没有意义。
cc_base="$(git rev-list --max-count=4 HEAD | tail -1)"
if git rev-parse --verify --quiet "${cc_base}^" >/dev/null 2>&1; then
  cc_range="${cc_base}^..HEAD"
else
  cc_range="HEAD"
fi
if bash scripts/check-commit-msg.sh --range "$cc_range" \
     --upstream-marker .github/upstream-sync.txt; then
  :
else
  echo "（最近提交里有标题不合规的——本地直接提交也要遵循规范）"
  fail=1
fi

echo "==> [4/4] 中文内容 U+FFFD 乱码扫描（tracked 文本文件）"
if command -v python3 >/dev/null 2>&1; then
  if ! python3 - <<'PY'
import pathlib, subprocess
files = subprocess.run(
    ["git", "ls-files", "*.md", "*.ets", "*.mts", "*.mjs", "*.ts",
     "*.json5", "*.sh", "*.yml", "*.yaml", "*.json"],
    capture_output=True, text=True, check=True).stdout.split()
bad = []
for f in files:
    p = pathlib.Path(f)
    if not p.is_file():
        continue
    try:
        if chr(0xFFFD) in p.read_text(encoding="utf-8", errors="ignore"):
            bad.append(f)
    except OSError:
        pass
print("\n".join(bad) if bad else "OK 无替换字符")
raise SystemExit(1 if bad else 0)
PY
  then
    fail=1
  fi
else
  echo "python3 未安装，跳过乱码扫描"
fi

if [[ $fail -ne 0 ]]; then
  echo ""
  echo "lint.sh：存在失败项 ✗"
  exit 1
fi
echo ""
echo "lint.sh：全部通过 ✓"
