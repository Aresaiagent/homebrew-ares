# Ares Homebrew tap

Homebrew tap for [Ares](https://aresdeploy.com) — the autonomous AI agency
operator.

## Install

Preferred — branded one-liner that handles everything, including passing
your provision token:

```sh
curl -fsSL https://aresdeploy.com/install.sh | ARES_TOKEN=your_token_here sh
```

Or manually via Homebrew:

```sh
brew install Aresaiagent/ares/ares
ares init --token=your_token_here
ares start
```

## Updates

```sh
brew upgrade ares
```

Homebrew re-reads this tap on every `brew update`, compares the formula
version to the installed version, and upgrades only when a new release
is published.

## What the formula installs

- The `ares` CLI (a self-contained bash launcher) to `/usr/local/bin/ares`
  (Apple Silicon: `/opt/homebrew/bin/ares`).
- A `VERSION` file to the Cellar for version tracking.

Everything else Ares needs (Docker images, Python MCP relay, config) is
provisioned on first run of `ares start`.

## Release

Release artifacts are built and published automatically by the private
`Aresaiagent/ares-deploy` repository on every version tag. Tarballs are
hosted at `aresdeploy.com/dist/` — not on GitHub. The release workflow
updates the `url` and `sha256` in `Formula/ares.rb` in this tap so
Homebrew always sees the authoritative version.

## Support

Questions, bugs, integration requests:

- `bugs@aresdeploy.com`
- `ideas@aresdeploy.com`
- `integrations@aresdeploy.com`

## License

Proprietary. See [aresdeploy.com/legal/terms](https://aresdeploy.com/legal/terms).
