#!/usr/bin/env bash
# =========================================================================== #
# Description: Generate and push version tag.
# =========================================================================== #
set -euo pipefail

if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  printf "Script must be run inside a GitHub Actions workflow.\n" >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  printf "Commit message is missing.\n" >&2
  exit 1
fi

commit_msg="$1"
commit_prefix="${commit_msg%%:*}"
commit_type="${commit_prefix//\(*\)/}"

bump=""
exit_msg="Commit type '${commit_type}' does not require a version bump."

case "$commit_type" in
*!)
  bump="major"
  ;;
feat)
  bump="minor"
  ;;
fix)
  bump="patch"
  ;;
*)
  printf "%s\n" "$exit_msg"
  exit 0
  ;;
esac

user_name="github-actions[bot]"
user_email="41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "$user_name"
git config --global user.email "$user_email"

cur_tag="$(git describe --tags --abbrev=0 2>/dev/null || printf "0.0.0")"
cur_ver="${cur_tag#v}"

major=0
minor=0
patch=0

if [[ "$cur_tag" != "0.0.0" ]]; then
  IFS='.' read -r major minor patch <<<"$cur_ver"
fi

case "$bump" in
major)
  major=$((major + 1))
  minor=0
  patch=0
  ;;
minor)
  minor=$((minor + 1))
  patch=0
  ;;
patch)
  patch=$((patch + 1))
  ;;
esac

new_ver="${major}.${minor}.${patch}"
new_tag="v${new_ver}"

git tag -a "$new_tag" -m "Release ${new_tag}"
git push origin "$new_tag"
