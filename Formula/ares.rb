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
# This formula installs the Rust harness binary — the local-side runtime
# that pairs with the Ares cloud. End users normally don't tap or install
# this manually; the install.sh shipped from aresdeploy.com handles it.

class Ares < Formula
  desc "Autonomous AI agency operator (Rust harness)"
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
      Ares installed.

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

      Config:
        ~/.ares/config               per-user state
        ~/.claude/agents/            sub-agent definitions

      Subscription required for actual use:
        https://aresdeploy.com/pricing
    EOS
  end

  test do
    assert_match "Ares Code", shell_output("#{bin}/ares --version")
    plan = shell_output("#{bin}/ares bootstrap-plan")
    assert_match "MainRuntime", plan
    assert_match "VaultDiscovery", plan
    assert_match "GhlStatusCheck", plan
    assert_match "LearningPhaseResolution", plan
  end
end
