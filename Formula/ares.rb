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
# v0.4.0 bundles the Desktop MCP daemon (Python/FastAPI on localhost:9999)
# alongside the Rust harness + GHL/Meta MCP servers. After install the
# Desktop MCP runs as a per-user LaunchAgent — survives logout, restarts
# on crash. The cloud agent at app.aresdeploy.com drives the customer's
# Mac through it.

class Ares < Formula
  desc "Autonomous AI agency operator (Rust REPL + GHL/Meta MCP + Desktop MCP daemon)"
  homepage "https://aresdeploy.com"
  version "0.4.0"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/Aresaiagent/homebrew-ares/releases/download/v0.4.0/ares-darwin-arm64.tar.gz"
      sha256 "e17de9df19bdbee1f8af121c4d33e251f00eb6c0b9ad8e64e339cb14f904a6b0"
    end
    on_intel do
      odie "ares v0.4.0 darwin-x86_64 build is not yet published. Build from source: " \
           "https://github.com/Aresaiagent/ares-runtime"
    end
  end

  on_linux do
    odie "ares v0.4.0 Linux build is not yet published. Build from source: " \
         "https://github.com/Aresaiagent/ares-runtime"
  end

  # Desktop MCP needs Python + Playwright Chromium; first-run start.sh installs
  # the pip packages lazily, so we don't add Python as a hard depends_on (most
  # macOS users have python3 already).

  def install
    # v0.4.0 tarball has two top-level dirs (bin/ and share/) so Homebrew
    # does NOT auto-strip a single-root prefix. Reference the bin/ paths
    # explicitly. (v0.3.0 tarball had only bin/ so the strip happened and
    # the install line was `bin.install "ares", ...` without bin/ prefix.)
    bin.install "bin/ares", "bin/ares-ghl-mcp", "bin/ares-meta-mcp"

    # Desktop MCP Python source + plist template into pkgshare
    (pkgshare/"desktop-mcp").install Dir["share/ares/desktop-mcp/*"]
  end

  def post_install
    require "securerandom"

    settings_dir = Pathname.new(Dir.home) / ".ares"
    settings_dir.mkpath
    settings_dir.chmod(0700)

    # ---- Stdio MCP registration (existing behavior) ----
    settings_file = settings_dir / "settings.json"
    unless settings_file.exist?
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

    # ---- Desktop MCP token (idempotent — keep existing if present) ----
    config_file = settings_dir / "config"
    existing = config_file.exist? ? config_file.read : ""
    unless existing.match?(/^ARES_MCP_TOKEN=/m)
      token = SecureRandom.hex(16)
      File.open(config_file, "a") { |f| f.puts "ARES_MCP_TOKEN=#{token}" }
      config_file.chmod(0600)
    end

    # ---- LaunchAgent: render template, write to ~/Library/LaunchAgents, load ----
    mcp_dir = pkgshare/"desktop-mcp"
    plist_label = "live.jtmarketing.ares-mcp"
    plist_path = Pathname.new(Dir.home) / "Library" / "LaunchAgents" / "#{plist_label}.plist"
    plist_path.parent.mkpath

    template = (mcp_dir/"#{plist_label}.plist.template").read
    rendered = template
               .gsub("__MCP_DIR__", mcp_dir.to_s)
               .gsub("__HOME__", Dir.home)
    plist_path.write(rendered)
    plist_path.chmod(0644)

    # Bootstrap idempotently. bootout-then-bootstrap survives upgrades.
    uid = Process.uid
    quiet_system "/bin/launchctl", "bootout", "gui/#{uid}/#{plist_label}"
    unless quiet_system "/bin/launchctl", "bootstrap", "gui/#{uid}", plist_path.to_s
      opoo "launchctl bootstrap failed. Load manually with:"
      opoo "  launchctl bootstrap gui/#{uid} #{plist_path}"
    end
  end

  def caveats
    <<~EOS
      Ares v0.4.0 installed.

      Three binaries on PATH:
        ares             interactive Rust agent REPL (BYOK Anthropic key)
        ares-ghl-mcp     stdio MCP server: 11 GoHighLevel tools
        ares-meta-mcp    stdio MCP server: 3 Meta Marketing tools

      Desktop MCP daemon (HTTP, localhost:9999):
        Runs as a per-user LaunchAgent — always listening, restarts on
        crash, survives logout. The cloud agent at app.aresdeploy.com
        uses it to drive your machine (browser + files + terminal + apps).

        Status: curl http://localhost:9999/health
        Logs:   ~/.ares/mcp.stderr.log

      First-run setup is done automatically by post_install:
        ✓ ARES_MCP_TOKEN generated in ~/.ares/config
        ✓ ~/Library/LaunchAgents/live.jtmarketing.ares-mcp.plist installed
        ✓ launchctl bootstrap loaded the agent
        First HTTP request triggers pip install + Playwright Chromium
        (~150 MB one-time download). Tail ~/.ares/mcp.stderr.log to watch.

      MCP wiring for any client (Claude Code, Mac app, your own):
        ~/.ares/settings.json registers the GHL + Meta stdio servers.

      Customer flow:
        1. Install via the one-liner: curl -fsSL https://aresdeploy.com/install.sh | sh
        2. Activate with the token from your activation email (binds the
           generated ARES_MCP_TOKEN to your account in the cloud relay)
        3. Use Ares at https://app.aresdeploy.com

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

    # Desktop MCP source files are in pkgshare.
    assert_path_exists pkgshare/"desktop-mcp/desktop.py"
    assert_path_exists pkgshare/"desktop-mcp/start.sh"
    assert_path_exists pkgshare/"desktop-mcp/live.jtmarketing.ares-mcp.plist.template"
  end
end
