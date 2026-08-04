#!/usr/bin/env bash
#
# Bring the formula up to date: crowsnest's latest release, and the latest
# maxminddb it bundles as a resource.
#
#   ci/bump-to-latest.sh
#
# Prints what it did. When run in Actions it also writes `changed` and `summary`
# to $GITHUB_OUTPUT so the workflow knows whether there is anything to commit and
# what to call it.
#
# The two are checked independently, because either can be behind on its own: a
# crowsnest release does not move maxminddb, and a maxminddb release does not
# move crowsnest.
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

changed=0
summary=""

note() {
    changed=1
    summary="${summary:+$summary, }$1"
}

# --------------------------------------------------------------- crowsnest
# The version the formula currently builds, read from the tarball it points at
# rather than kept as a separate field that could disagree with the URL.
current="$(sed -n 's|^  url ".*/v\([0-9][0-9.]*\)\.tar\.gz"|\1|p' "$FORMULA" | head -1)"
[ -n "$current" ] || { say "could not read the current version from $FORMULA"; exit 1; }

tag="$(gh api "repos/$REPO/releases/latest" --jq .tag_name)"
latest="${tag#v}"
[ -n "$latest" ] || { say "could not read the latest release of $REPO"; exit 1; }

say "crowsnest: formula has $current, latest release is $latest"

if [ "$current" != "$latest" ]; then
    url="https://github.com/$REPO/archive/refs/tags/$tag.tar.gz"
    sha="$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)"
    [ -n "$sha" ] || { say "could not hash $url"; exit 1; }
    say "  new tarball hashes to $sha"

    # Anchored on exactly two spaces of indentation, which is the formula's own
    # fields. The resource's url and sha256 sit inside a block and are indented
    # four, so they cannot be caught by this -- asserted below rather than left
    # to trust.
    sed -i.bak -E \
        -e "s|^  url \".*\"|  url \"$url\"|" \
        -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" \
        "$FORMULA"
    rm -f "$FORMULA.bak"

    grep -q "^  url \"$url\"" "$FORMULA" || { say "url was not updated"; exit 1; }
    grep -q "^  sha256 \"$sha\"" "$FORMULA" || { say "sha256 was not updated"; exit 1; }
    note "crowsnest $latest"
fi

# -------------------------------------------------------------- maxminddb
# Pinned by hand until now, which meant it quietly aged: a pinned older version
# keeps working, so nothing ever complained. It is what turns a bare address into
# the name of the organisation behind it, so it is worth keeping current.
#
# There is exactly one resource in this formula, so four spaces of indentation
# identifies it unambiguously. A second resource would need this keyed by block
# instead.
res_current="$(sed -n 's|^    url ".*/maxminddb-\([0-9][0-9.]*\)\.tar\.gz"|\1|p' "$FORMULA" | head -1)"
[ -n "$res_current" ] || { say "could not read the maxminddb version from $FORMULA"; exit 1; }

# python3 rather than jq: picking the sdist out of the file list is a filter, not
# a lookup, and this says so plainly.
pypi="$(curl -fsSL https://pypi.org/pypi/maxminddb/json)"
res_info="$(printf '%s' "$pypi" | python3 -c '
import json, sys
data = json.load(sys.stdin)
version = data["info"]["version"]
sdist = next(u for u in data["urls"] if u["packagetype"] == "sdist")
print(version, sdist["url"], sdist["digests"]["sha256"])
')"
# shellcheck disable=SC2086
set -- $res_info
res_latest="$1"; res_url="$2"; res_sha="$3"
[ -n "$res_latest" ] || { say "could not read the latest maxminddb from PyPI"; exit 1; }

say "maxminddb: formula has $res_current, PyPI has $res_latest"

if [ "$res_current" != "$res_latest" ]; then
    sed -i.bak -E \
        -e "s|^    url \".*\"|    url \"$res_url\"|" \
        -e "s|^    sha256 \".*\"|    sha256 \"$res_sha\"|" \
        "$FORMULA"
    rm -f "$FORMULA.bak"

    grep -q "^    url \"$res_url\"" "$FORMULA" || { say "resource url not updated"; exit 1; }
    grep -q "^    sha256 \"$res_sha\"" "$FORMULA" || { say "resource sha256 not updated"; exit 1; }
    note "maxminddb $res_latest"
fi

# ------------------------------------------------------------------ result
# Whatever was rewritten, the formula must still have exactly one of each field
# at each level. Catches a sed that matched more than it should have.
for pattern in '^  url ' '^  sha256 ' '^    url ' '^    sha256 '; do
    count="$(grep -c "$pattern" "$FORMULA" || true)"
    [ "$count" = "1" ] || {
        say "expected one line matching $pattern, found $count -- refusing to continue"
        exit 1
    }
done

if [ "$changed" = 0 ]; then
    emit "changed=false"
    say "nothing to do"
    exit 0
fi

emit "changed=true"
emit "summary=$summary"
say "updated $FORMULA: $summary"
