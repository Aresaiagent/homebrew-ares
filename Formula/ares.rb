# Homebrew formula for Ares — the autonomous agency operator.
# https://aresdeploy.com
#
# Install (qualified, avoids homebrew-core's unrelated `ares` formula):
#   brew tap aresaiagent/ares
#   brew install aresaiagent/ares/ares
#
# Or via the one-liner (the customer-facing path):
#   curl -fsSL https://aresdeploy.com/install.sh | sh
#
# This formula installs the Rust harness + GHL/Meta MCP servers — the
# local-side runtime that pairs with the Ares cloud. End users normally
# don't tap or install this manually; install.sh handles it.
#
# Bump version + sha256 on every `git tag v*` of Aresaiagent/ares-runtime.

class Ares < Formula
  desc "Autonomous AI agency operator (Rust harness + GHL/Meta MCP servers)"
  homepage "https://aresdeploy.com"
  version "0.3.0"
  license :cannot_represent

  on_macos do
    on_arm do
      # Mirrored from Aresaiagent/ares-runtime v0.3.0 (private repo) to
      # this public homebrew-ares repo so brew can fetch without auth.
      url "https://github.com/Aresaiagent/homebrew-ares/releases/download/v0.3.0/ares-darwin-arm64.tar.gz"
      sha256 "8c92ffd3020c6f4d880389aa239ce161506409a63241b8ad20d4ca90ce7bd42d"
    end
    on_intel do
      odie "ares v0.3.0 darwin-x86_64 build is not yet published. Build from source: " \
           "https://github.com/Aresaiagent/ares-runtime"
    end
  end

  on_linux do
    odie "ares v0.3.0 Linux build is not yet published. Build from source: " \
         "https://github.com/Aresaiagent/ares-runtime"
  end

  def install
    # Tarball has files under bin/, so brew extracts into a working dir
    # that is itself the bin/ directory. Install them as files at the
    # current working directory's root.
    bin.install "ares", "ares-ghl-mcp", "ares-meta-mcp"
  end

  def post_install
    settings_dir = Pathname.new(Dir.home) / ".ares"
    settings_dir.mkpath
    settings_file = settings_dir / "settings.json"
    return if settings_file.exist?

    settings_file.write <<~JSON
      {
        "mcpServers": {
          "ares-ghl": {
            "command": "#{bin}/ares-ghl-mcp",
            "args": [],
            "env": {}
          },
          "ares-meta": {
            "command": "#{bin}/ares-meta-mcp",
            "args": [],
            "env": {}
          }
        }
      }
    JSON
  end

  def caveats
    <<~EOS
      Ares v0.3.0 installed.

      Three binaries:
        ares             interactive Rust agent REPL (BYOK Anthropic key)
        ares-ghl-mcp     stdio MCP server: 11 GoHighLevel tools
        ares-meta-mcp    stdio MCP server: 3 Meta Marketing tools

      MCP wiring:
        ~/.ares/settings.json was created with the new binary paths
        on first install. Any MCP client (Claude Code, Mac app, or
        your own) reading that file will pick up the GHL + Meta tool
        surfaces immediately.

      Customer flow (recommended — paired with the desktop daemon):
        1. Install via the one-liner: curl -fsSL https://aresdeploy.com/install.sh | sh
        2. Activate with the token from your activation email
        3. Use Ares at https://app.aresdeploy.com

      Power-user / operator flow (drive Ares locally):
        ares                         # launches the REPL
        /fleet-status                # in-REPL: GHL credentials + dedup + phase
        /pipeline-report             # in-REPL: pipelines + opps + dollar values
        /learning-phase show         # in-REPL: trust ladder

      Auth — pick one:
        - Run `ares` and complete OAuth in the browser
        - Or set ANTHROPIC_API_KEY in your shell

      GHL (PIT-key based, multi-account):
        ARES_GHL_PIT_KEY env var, or ~/.ares/config[default_pit]

      Meta:
        META_ACCESS_TOKEN env var, or ~/.ares/config[meta_access_token]
        META_AD_ACCOUNT_ID env var, or ~/.ares/config[meta_ad_account_id]

      Config:
        ~/.ares/config               per-user state
        ~/.ares/settings.json        MCP server registrations
        ~/.claude/agents/            sub-agent definitions

      Subscription required for actual use:
        https://aresdeploy.com/pricing
    EOS
  end

  test do
    # Core REPL: --version prints Ares Code banner.
    assert_match "Ares Code", shell_output("#{bin}/ares --version")

    # Bootstrap plan includes Ares-specific phases.
    plan = shell_output("#{bin}/ares bootstrap-plan")
    assert_match "MainRuntime", plan
    assert_match "VaultDiscovery", plan
    assert_match "GhlStatusCheck", plan
    assert_match "LearningPhaseResolution", plan

    # MCP servers respond to JSON-RPC tools/list over stdio.
    ghl_response = pipe_output("#{bin}/ares-ghl-mcp",
      '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' + "\n")
    assert_match "ghl_location", ghl_response
    meta_response = pipe_output("#{bin}/ares-meta-mcp",
      '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' + "\n")
    assert_match "meta_ad_insights", meta_response
  end
end
