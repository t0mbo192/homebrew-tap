# homebrew-tap

This repository lets Mac users install
[crowsnest](https://github.com/t0mbo192/crowsnest) with one command:

```bash
brew install t0mbo192/tap/crowsnest
```

## What a "tap" is

**Homebrew** is the package manager most Mac users install software with —
`brew install ripgrep`, and so on. By default it installs from its own official
list of programs.

A **tap** is an extra list Homebrew can install from. It is nothing more than a
git repository holding recipes. When you run the command above, Homebrew clones
this repository onto your Mac, finds the recipe in
[Formula/crowsnest.rb](Formula/crowsnest.rb), and follows it.

That is also why this is a separate repository from crowsnest itself, and why it
has this name:

- Homebrew turns `t0mbo192/tap` into `github.com/t0mbo192/homebrew-tap`. The
  `homebrew-` prefix is required, so the name is not really a choice.
- Homebrew downloads the whole tap. Keeping it to recipes means a small
  download, rather than every Mac user cloning crowsnest's full history to read
  one file.

A recipe is called a **formula**, which is where `--formula` comes from below.

## Installing

```bash
brew install t0mbo192/tap/crowsnest
```

Homebrew installs Wireshark at the same time, because crowsnest reads packets
using its `tshark` program.

Then download the database that lets crowsnest name the company behind an
address — "Microsoft Corporation" instead of `20.42.65.92`:

```bash
crowsnest asn --fetch
```

Homebrew will warn you that this tap is not trusted, because a formula is code
that runs on your machine. To say you trust this one:

```bash
brew trust --formula t0mbo192/tap/crowsnest
```

`brew trust t0mbo192/tap` trusts the whole tap instead, including anything added
to it later — broader, so only if you want that.

## Removing it

```bash
brew uninstall crowsnest
brew untap t0mbo192/tap
```

## Notes for macOS

Reading a saved capture needs nothing. Watching live traffic needs access to the
network devices, so run it with `sudo`:

```bash
sudo crowsnest live -i en0 --dashboard
```

`en0` is Wi-Fi on most Macs — there is no `eth0`. `crowsnest interfaces` lists
what you actually have.

To avoid needing `sudo`, install Wireshark's helper for it with
`brew install --cask wireshark-app`. That is the full Wireshark application; this
formula depends on the smaller command-line build, which does not include it.

`crowsnest block` does not work on macOS. It writes firewall rules using
nftables, which is Linux-only — macOS uses pf instead. crowsnest tells you so
rather than failing strangely. Everything else works.

## Keeping the formula current

Nothing to do by hand. [`update.yml`](.github/workflows/update.yml) checks
crowsnest's latest release every six hours and, when this formula is behind,
updates it, builds and runs it, and only then commits — so nothing untested
lands here.

It runs in this repository rather than being pushed from crowsnest's own release
workflow because a GitHub Actions job can only write to its own repository unless
it is given an access token, and a stored token is a worse thing to look after
than a scheduled check.

[`tests.yml`](.github/workflows/tests.yml) runs the same
[`ci/check-formula.sh`](ci/check-formula.sh) on every push: build from source,
run it, check Wireshark really is pulled in, and uninstall cleanly.
