#!/usr/bin/env bash
# =========================================================================== #
# Description: Automate semantic versioning.
# =========================================================================== #
set -euo pipefail

cur_tag="$(git describe --tags --abbrev=0 2>/dev/null || printf "0.0.0")"
cur_ver="${cur_tag#v}"

major=0
minor=0
patch=0
rev_range="HEAD"

if [[ "$cur_tag" != "0.0.0" ]]; then
	IFS='.' read -r major minor patch <<< "$cur_ver"
	rev_range="${cur_tag}..HEAD"
fi

scope_regexp="(\([a-z0-9-]+\))?"

has_commit_matching() {
	local _prefix="$1"
	local _regexp="^${_prefix//@/$scope_regexp}:"
	local _flags=(
		--format="%H"
		--extended-regexp
		--grep="$_regexp"
	)

	local _match=""
	_match="$(git log "${_flags[@]}" "$rev_range")"
	[[ -n "$_match" ]]
}

if has_commit_matching "[a-z]+@!"; then
	major=$((major+1))
	minor=0
	patch=0
elif has_commit_matching "feat@"; then
	minor=$((minor+1))
	patch=0
elif has_commit_matching "fix@"; then
	patch=$((patch+1))
else
	exit 0
fi

new_ver="${major}.${minor}.${patch}"
new_tag="v${new_ver}"

git tag \
	--annotate "$new_tag" \
	--message "Release ${new_tag}"
git push origin "$new_tag"
