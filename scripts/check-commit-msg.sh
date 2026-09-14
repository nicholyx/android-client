#!/usr/bin/env bash
# 校验提交标题遵循 Conventional Commits（type(scope)?: subject）。
#
# 用法：
#   check-commit-msg.sh --range <A..B>        校验区间内每个提交的标题
#   check-commit-msg.sh --pr-title "<标题>"   校验 PR 标题（squash 合并后即提交信息）
#
# 两个参数可同时传入；全部通过退出 0，任一违规打印明细并退出 1。
# 兼容 macOS 自带 bash 3.2：不使用关联数组、mapfile 等特性。
set -euo pipefail

usage() { echo "用法: $0 [--range A..B] [--pr-title 标题]" >&2; exit 1; }

PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9._/-]+\))?!?: .+'

range=""
pr_title=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --range) range="${2:-}"; shift 2 ;;
    --pr-title) pr_title="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

if [[ -z "$range" && -z "$pr_title" ]]; then
  usage
fi

violations=0

if [[ -n "$range" ]]; then
  while IFS= read -r subject; do
    if [[ -z "$subject" ]]; then
      continue
    fi
    if ! [[ "$subject" =~ $PATTERN ]]; then
      echo "✗ 提交标题不符合 Conventional Commits：$subject"
      violations=$((violations + 1))
    fi
  done < <(git log --format=%s "$range")
fi

if [[ -n "$pr_title" ]]; then
  if ! [[ "$pr_title" =~ $PATTERN ]]; then
    echo "✗ PR 标题不符合 Conventional Commits：$pr_title"
    violations=$((violations + 1))
  fi
fi

if [[ $violations -gt 0 ]]; then
  echo ""
  echo "共 ${violations} 处违规。合法格式：type(scope): 标题，type 取值"
  echo "feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert。"
  exit 1
fi

echo "提交规范校验通过。"
