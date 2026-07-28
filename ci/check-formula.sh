#!/usr/bin/env bash
#
# Build and run the formula the way a user would receive it.
#
# Lives in one place because two workflows need it: the one that checks pushes,
# and the one that updates the formula to a new release. The updater has to run
# these same checks *before* it pushes, or a bad formula lands on main and the
# first anyone hears of it is a failed brew install.

set -euo pipefail

TAP="t0mbo192/tap"
FORMULA="$TAP/crowsnest"

# Homebrew finds taps by path, so linking this checkout into place tests exactly
# what `brew tap t0mbo192/tap` would deliver -- not a copy that has drifted.
tap_dir="$(brew --repository)/Library/Taps/t0mbo192/homebrew-tap"
if [ ! -e "$tap_dir" ]; then
    mkdir -p "$(dirname "$tap_dir")"
    ln -s "$PWD" "$tap_dir"
fi

# Homebrew requires third-party taps to be trusted before it will use what is in
# them. Trusting the one formula keeps the grant as narrow as what is tested.
brew trust --formula "$FORMULA"

brew style "$TAP"
brew audit --strict --online "$FORMULA"
brew install --verbose --build-from-source "$FORMULA"
brew test --verbose "$FORMULA"

# The dependency is the reason this package exists: nobody should have to go and
# install Wireshark first.
command -v tshark >/dev/null || {
    printf 'tshark is not on PATH -- the wireshark dependency did not take\n' >&2
    exit 1
}
brew deps "$FORMULA" | grep -qx wireshark

brew uninstall "$FORMULA"
command -v crowsnest >/dev/null && {
    printf 'crowsnest survived an uninstall\n' >&2
    exit 1
}

printf '\nformula is good\n'
