#!/usr/bin/env bash
#
# Point the formula at crowsnest's latest release, if it is not already.
#
#   ci/bump-to-latest.sh
#
# Prints what it did. When run in Actions it also writes `changed` and `version`
# to $GITHUB_OUTPUT so the workflow knows whether there is anything to commit.
#
# This runs here, in the tap, rather than being pushed from crowsnest's release
# workflow: a workflow can only write to its own repository unless it is given a
# personal access token, and a stored cross-repository token is a worse thing to
# maintain than a scheduled check.

set -euo pipefail

REPO="t0mbo192/crowsnest"
FORMULA="Formula/crowsnest.rb"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

say() { printf '%s\n' "$1"; }
emit() { [ -n "${GITHUB_OUTPUT:-}" ] && printf '%s\n' "$1" >> "$GITHUB_OUTPUT"; return 0; }

# The version the formula currently builds, read from the tarball it points at
# rather than kept as a separate field that could disagree with the URL.
current="$(sed -n 's|^  url ".*/v\([0-9][0-9.]*\)\.tar\.gz"|\1|p' "$FORMULA" | head -1)"
[ -n "$current" ] || { say "could not read the current version from $FORMULA"; exit 1; }

tag="$(gh api "repos/$REPO/releases/latest" --jq .tag_name)"
latest="${tag#v}"
[ -n "$latest" ] || { say "could not read the latest release of $REPO"; exit 1; }

say "formula points at $current, latest release is $latest"

if [ "$current" = "$latest" ]; then
    emit "changed=false"
    say "nothing to do"
    exit 0
fi

url="https://github.com/$REPO/archive/refs/tags/$tag.tar.gz"
sha="$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)"
[ -n "$sha" ] || { say "could not hash $url"; exit 1; }
say "new tarball hashes to $sha"

# Anchored on exactly two spaces of indentation, which is the formula's own
# fields. The maxminddb resource's url and sha256 sit inside a block and are
# indented four, so they cannot be caught by this -- asserted below rather than
# left to trust.
resource_sha_before="$(grep -c '^    sha256 ' "$FORMULA" || true)"
sed -i.bak -E \
    -e "s|^  url \".*\"|  url \"$url\"|" \
    -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" \
    "$FORMULA"
rm -f "$FORMULA.bak"

grep -q "url \"$url\"" "$FORMULA" || { say "url was not updated"; exit 1; }
grep -q "^  sha256 \"$sha\"" "$FORMULA" || { say "sha256 was not updated"; exit 1; }
[ "$(grep -c '^    sha256 ' "$FORMULA" || true)" = "$resource_sha_before" ] || {
    say "a resource's sha256 was touched -- refusing to continue"
    exit 1
}

emit "changed=true"
emit "version=$latest"
say "updated $FORMULA to $latest"
