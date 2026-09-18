#!/usr/bin/env bash
# =========================================================================== #
# Description: Generate and push version tag.
# =========================================================================== #

set -euo pipefail

dry_run=false

# --- Arguments ---------------------------------------------------------------

if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  shift
fi

if [[ "$dry_run" != true && "${GITHUB_ACTIONS:-}" != true ]]; then
  { #stderr
    printf "Script is being run outside of a GitHub Actions workflow.\n"
    printf "Use --dry-run flag to run script locally.\n"
  } >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  printf "Commit message is missing.\n" >&2
  exit 1
fi

# --- Version bump ------------------------------------------------------------

commit_msg="$1"
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

# --- Current version ---------------------------------------------------------

cur_tag="$(git describe --tags --abbrev=0 2>/dev/null || printf "v0.0.0")"
cur_ver="${cur_tag#v}"

if [[ ! "$cur_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf "Current tag '%s' is invalid.\n" "$cur_tag" >&2
  exit 1
fi

IFS='.' read -r major minor patch <<<"$cur_ver"

# --- New version -------------------------------------------------------------

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

# --- Payload -----------------------------------------------------------------

if [[ "$dry_run" == true ]]; then
  cat <<-EOF
	Dry run — no tag will be created.

	Commit type:   ${commit_type}
	Version bump:  ${bump}
	Current tag:   ${cur_tag}
	Created tag:   ${new_tag}
	EOF

else
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git tag -a "$new_tag" -m "Release ${new_tag}"
  git push origin "$new_tag"
fi
