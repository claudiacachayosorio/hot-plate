#!/usr/bin/env bash
# =========================================================================== #
# Description: Automate semantic versioning.
# =========================================================================== #
set -euo pipefail

CUR_TAG="$(git describe --tags --abbrev=0 2>/dev/null || printf "0.0.0")"
CUR_VER="${CUR_TAG#v}"

MAJOR=0
MINOR=0
PATCH=0

REV_RANGE="HEAD"

if [[ "$CUR_TAG" != "0.0.0" ]]; then
	IFS='.' read -r MAJOR MINOR PATCH <<< "$CUR_VER"
	REV_RANGE="${CUR_TAG}..HEAD"
fi

SCOPE_REGEXP="(\([a-z0-9-]+\))?"
GIT_LOG_FLAGS=(--format="%H" --extended-regexp)

has_commit_matching() {
	local prefix="$1"
	local regexp="^${prefix//@/$SCOPE_REGEXP}:"
	local git_log_flags=("${GIT_LOG_FLAGS[@]}" --grep="$regexp")

	local match=""
	match="$(git log "${git_log_flags[@]}" "$REV_RANGE")"
	[[ -n "$match" ]]
}

if has_commit_matching "[a-z]+@!"; then
	MAJOR=$((MAJOR+1))
	MINOR=0
	PATCH=0
elif has_commit_matching "feat@"; then
	MINOR=$((MINOR+1))
	PATCH=0
elif has_commit_matching "fix@"; then
	PATCH=$((PATCH+1))
else
	exit 0
fi

NEW_VER="${MAJOR}.${MINOR}.${PATCH}"
NEW_TAG="v${NEW_VER}"

git tag --annotate "$NEW_TAG" --message "Release ${NEW_TAG}"
git push origin "$NEW_TAG"
