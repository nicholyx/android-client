#!/usr/bin/env bash
# 校验提交标题遵循 Conventional Commits（type(scope)?: subject）。
#
# 用法：
#   check-commit-msg.sh --range <A..B>        校验区间内每个提交的标题
#   check-commit-msg.sh --pr-title "<标题>"   校验 PR 标题（squash 合并后即提交信息）
#   check-commit-msg.sh --upstream-marker <文件>
#                                             跳过上游镜像提交（见下）
#
# 参数可任意组合；全部通过退出 0，任一违规打印明细并退出 1。
# 兼容 macOS 自带 bash 3.2：不使用关联数组、mapfile 等特性。
#
# 关于 --upstream-marker：
#   本仓库是 netbirdio/android-client 的 fork，会周期性合并上游 main。
#   上游提交信息不由我们命名，不该被本仓库的规则判红。豁免依据是**祖先
#   关系**——标记文件里记录的提交及其祖先全部跳过，而不是按作者、分支名
#   之类可以随意伪造的信号。标记文件本身在仓库里，改动会出现在 PR diff 中，
#   维护者可审计；且它只能豁免「已经存在于上游历史里」的提交，
#   我们自己新写的提交即便写成非规范标题也照样会红。
set -euo pipefail

usage() { echo "用法: $0 [--range A..B] [--pr-title 标题] [--upstream-marker 文件]" >&2; exit 1; }

PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9._/-]+\))?!?: .+'

range=""
pr_title=""
marker=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --range) range="${2:-}"; shift 2 ;;
    --pr-title) pr_title="${2:-}"; shift 2 ;;
    --upstream-marker) marker="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

if [[ -z "$range" && -z "$pr_title" ]]; then
  usage
fi

# 解析上游标记：取第一行里长度为 40 的十六进制字段。
upstream_sha=""
if [[ -n "$marker" ]]; then
  if [[ ! -f "$marker" ]]; then
    echo "! 上游标记文件不存在：${marker}（不豁免任何提交）"
  else
    while IFS= read -r line || [[ -n "$line" ]]; do
      candidate="${line%% *}"
      if [[ "$candidate" =~ ^[0-9a-f]{40}$ ]]; then
        upstream_sha="$candidate"
        break
      fi
    done < "$marker"
    if [[ -z "$upstream_sha" ]]; then
      echo "! 上游标记文件里没有 40 位提交号：${marker}（不豁免任何提交）"
    elif ! git cat-file -e "${upstream_sha}^{commit}" 2>/dev/null; then
      echo "! 上游标记的提交不在本仓库历史中：${upstream_sha}（不豁免任何提交；合并上游后它才会出现）"
      upstream_sha=""
    fi
  fi
fi

violations=0
skipped=0
auto_merges=0

if [[ -n "$range" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      continue
    fi
    sha="${line%% *}"
    subject="${line#* }"
    if [[ -n "$upstream_sha" ]] && git merge-base --is-ancestor "$sha" "$upstream_sha" 2>/dev/null; then
      skipped=$((skipped + 1))
      continue
    fi
    # 自动生成的合并提交（GitHub 的 "Merge pull request #N …"、git 的
    # "Merge branch …"）不是我们命名的，不判——PR 用 merge commit 合并时
    # main 上会周期性出现这类提交。我们自己用 -m 命名的合并提交仍会被检查。
    if [[ "$subject" == "Merge pull request #"* || "$subject" == "Merge branch "* ]]; then
      auto_merges=$((auto_merges + 1))
      continue
    fi
    if ! [[ "$subject" =~ $PATTERN ]]; then
      echo "✗ 提交标题不符合 Conventional Commits：$subject"
      violations=$((violations + 1))
    fi
  done < <(git log --format='%H %s' "$range")
fi

if [[ -n "$pr_title" ]]; then
  if ! [[ "$pr_title" =~ $PATTERN ]]; then
    echo "✗ PR 标题不符合 Conventional Commits：$pr_title"
    violations=$((violations + 1))
  fi
fi

if [[ $skipped -gt 0 ]]; then
  echo "（已跳过 ${skipped} 个上游镜像提交：祖先关系命中 ${upstream_sha}）"
fi
if [[ $auto_merges -gt 0 ]]; then
  echo "（已跳过 ${auto_merges} 个自动生成的合并提交）"
fi

if [[ $violations -gt 0 ]]; then
  echo ""
  echo "共 ${violations} 处违规。合法格式：type(scope): 标题，type 取值"
  echo "feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert。"
  exit 1
fi

echo "提交规范校验通过。"