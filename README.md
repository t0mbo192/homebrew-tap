# homebrew-tap

Homebrew formulae for [crowsnest](https://github.com/t0mbo192/crowsnest).

```bash
brew install t0mbo192/tap/crowsnest
```

That is the whole installation. Homebrew pulls in Wireshark's `tshark`, which
crowsnest reads packets with, so there is no prerequisite to go and install
first.

`brew tap t0mbo192/tap` first if you would rather see what you are adding;
`brew install --HEAD t0mbo192/tap/crowsnest` builds from `main` instead of the
latest release.

## What is crowsnest

A terminal tool that reduces network traffic to the question you usually
actually have: what is my machine talking to, and what is talking to it? Each
host is reported once, when it first appears, split by direction and labelled
with what it actually is rather than left as a bare address.

Everything else — what it does, what it cannot do, and why — is in the
[crowsnest README](https://github.com/t0mbo192/crowsnest#readme).

## Notes for macOS

Reading saved captures needs nothing. Watching live traffic needs access to the
capture devices, so run it under `sudo`, or install Wireshark's ChmodBPF helper
(it ships with the cask, `brew install --cask wireshark-app`, not with the
command-line build this formula depends on).

`crowsnest block` is Linux-only — it writes nftables rules, and macOS filters
with pf. crowsnest says so rather than failing oddly.

## Releasing a new version

Update `url`, `sha256` and any resources in
[Formula/crowsnest.rb](Formula/crowsnest.rb), then push. The
[workflow](.github/workflows/tests.yml) builds and runs the formula on a real
macOS runner, so a broken one fails here rather than on someone's machine.

```bash
curl -fsSL https://github.com/t0mbo192/crowsnest/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```
