# Homebrew formula for Ares — the autonomous agency operator.
# https://aresdeploy.com
#
# Install:
#   brew install Aresaiagent/ares/ares
#
# Or the branded one-liner (preferred):
#   curl -fsSL https://aresdeploy.com/install.sh | sh
#
# Release artifacts are hosted on aresdeploy.com/dist/ (not GitHub).
# sha256 is updated automatically by the release workflow in the
# Aresaiagent/ares-deploy repository on every `git tag v*` push.

class Ares < Formula
  desc "Autonomous AI agency operator — one operator, every specialist"
  homepage "https://aresdeploy.com"
  url "https://aresdeploy.com/dist/ares-v0.1.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license :cannot_represent
  version "0.1.0"

  def install
    bin.install "ares"
    prefix.install "VERSION" if File.exist?("VERSION")
  end

  def caveats
    <<~EOS
      Ares requires Docker to be installed and running on your machine.
      If you don't have Docker: https://www.docker.com/products/docker-desktop/

      Quick start:
        ares init --token=YOUR_TOKEN   # one-time setup (token from activation email)
        ares start                     # launch the local agent
        ares status                    # check it's running
        ares help                      # all commands

      Config lives at ~/.ares/
      Docs: https://aresdeploy.com/desktop
    EOS
  end

  test do
    # `ares help` should exit 0 and mention 'ares' somewhere in its output.
    assert_match "ares", shell_output("#{bin}/ares help 2>&1").downcase
  end
end
