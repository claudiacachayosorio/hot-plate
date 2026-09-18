#!/usr/bin/env bash
# =========================================================================== #
# Description: Generate and push version tag.
# =========================================================================== #
set -euo pipefail

if [[ $# -eq 0 ]]; then
  printf "Commit message is missing.\n" >&2
  exit 1
fi

dry_run="true"
[[ "$1" == "--dry-run" ]] && {
  dry_run="false"
  shift
}

if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  printf "Script is being run outside of GitHub Actions workflow.\n"
  printf "Use --dry-run flag to run script locally.\n"
  exit 1
fi

commit_msg="$*"
commit_prefix="${commit_msg%%:*}"
commit_type="${commit_prefix/(*)/}"
bump=""

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
  printf "Commit type '%s' does not require a version bump.\n" "$commit_type"
  printf "Skipping release.\n"
  exit 0
  ;;
esac

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

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

if [[ "$dry_run" == false ]]; then
  git tag -a "$new_tag" -m "Release ${new_tag}"
  git push origin "$new_tag"

else
  cat <<-EOF
	Commit type:     ${commit_type}
	Version bump:    ${bump}
	Current tag:     ${cur_tag}
  Current version: ${cur_ver}
	New version:     ${new_ver}
  New tag:         ${new_tag}
	EOF
fi
