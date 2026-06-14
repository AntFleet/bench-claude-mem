#!/bin/bash
# usage: _open-pr.sh <branch> <commit-msg> <pr-title> <pr-body> <file1> <file2> ...
set -euo pipefail
branch="$1"; shift
commit_msg="$1"; shift
pr_title="$1"; shift
pr_body="$1"; shift

cd /tmp/bench-claude-mem
git checkout main >/dev/null 2>&1
git checkout -b "$branch" >/dev/null 2>&1

for f in "$@"; do
  dir=$(dirname "$f")
  [ "$dir" != "." ] && mkdir -p "$dir"
  gh api "repos/thedotmack/claude-mem/contents/$f" --jq '.content' 2>/dev/null | base64 -d > "$f"
  if [ ! -s "$f" ]; then
    echo "FAILED to fetch: $f" >&2
    exit 1
  fi
done

git add -A
git -c user.email=285575208+antfleet-ops@users.noreply.github.com \
    -c user.name=antfleet-ops \
    commit -q -m "$commit_msg"
git push -q -u origin "$branch"
gh pr create --repo AntFleet/bench-claude-mem --base main --head "$branch" \
  --title "$pr_title" --body "$pr_body"
