# Homebrew formula for Ares — autonomous AI agency operator (Rust harness).
# https://aresdeploy.com
#
# Install:
#   brew tap aresaiagent/ares
#   brew install ares
#
# Or one-liner:
#   curl -fsSL https://aresdeploy.com/install.sh | sh

class Ares < Formula
  desc "Autonomous AI agency operator — Rust agent harness"
  homepage "https://aresdeploy.com"
  version "0.1.0"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/Aresaiagent/homebrew-ares/releases/download/v0.1.0/ares-v0.1.0-darwin-arm64.tar.gz"
      sha256 "e75f324b463b8120db5abe38b2b9288e6f82254ebe29ea573c5e8c67cfbaeda7"
    end
  end

  def install
    bin.install "ares"
  end

  def caveats
    <<~EOS
      Ares (Rust harness) installed.

      First-time setup:
        ares                         # launches the REPL
                                     # opens browser for OAuth login on first run
        ares --version               # build info
        ares system-prompt           # print the assembled system prompt

      Auth — pick one (matches Claude Code's model):
        - Run `ares` and complete OAuth in the browser
        - Or set ANTHROPIC_API_KEY in your shell

      In-REPL slash commands (Ares-specific):
        /fleet-status                GHL credentials + dedup + learning phase
        /pipeline-report [loc_id]    pipelines + opps + dollar values
        /send-sequence <name> <id>   deploy a nurture sequence (phase-gated)
        /learning-phase show         show current phase + ladder

      Config lives at:
        ~/.ares/config               per-user state (default location, phase)
        ~/.claude/agents/            sub-agent definitions

      Subscription required for use:
        https://aresdeploy.com/pricing

      Docs:
        https://aresdeploy.com/desktop
    EOS
  end

  test do
    # `--version` works without auth.
    assert_match "Ares Code", shell_output("#{bin}/ares --version")
    # `bootstrap-plan` lists all phases including the 3 Ares additions.
    plan = shell_output("#{bin}/ares bootstrap-plan")
    assert_match "MainRuntime", plan
    assert_match "VaultDiscovery", plan
    assert_match "GhlStatusCheck", plan
    assert_match "LearningPhaseResolution", plan
  end
end
