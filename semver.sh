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

find_bump() {
	local prefix="$1"
	git log --grep="^${prefix}:" --max-count=1 --pretty="%B" "$REV_RANGE"
}

if find_bump "[a-z]+!"; then
	MAJOR=$((MAJOR+1))
	MINOR=0
	PATCH=0
elif find_bump "feat"; then
	MINOR=$((MINOR+1))
	PATCH=0
elif find_bump "fix"; then
	PATCH=$((PATCH+1))
else
	exit 0
fi

NEW_VER="${MAJOR}.${MINOR}.${PATCH}"
NEW_TAG="v${NEW_VER}"

git tag -a "$NEW_TAG" -m "Release ${NEW_TAG}"
git push origin "$NEW_TAG"
