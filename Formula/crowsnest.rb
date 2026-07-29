class Crowsnest < Formula
  include Language::Python::Virtualenv

  desc "See which hosts a machine talks to, in plain language"
  homepage "https://github.com/t0mbo192/crowsnest"
  url "https://github.com/t0mbo192/crowsnest/archive/refs/tags/v1.1.4.tar.gz"
  sha256 "5bc5a4abf46cd5f371f158157fed58d2a924c646539204ba4fb861e4f98c7e86"
  license "MIT"
  head "https://github.com/t0mbo192/crowsnest.git", branch: "main"

  depends_on "python@3.12"

  # The point of packaging this: crowsnest reads packets with tshark, and this
  # is what stops "install Wireshark first" being a step the user has to take.
  depends_on "wireshark"

  # Optional upstream, but it is what turns a bare address into the name of the
  # organisation behind it. Installing it here means that works out of the box
  # rather than after a second command nobody knows to run.
  resource "maxminddb" do
    url "https://files.pythonhosted.org/packages/31/83/bcd7f2e7dfcf601258a4eab92155816218e8f8adf6608d5f7d39da7ba863/maxminddb-3.1.1.tar.gz"
    sha256 "b19a938c481518f19a2c534ffdcb3bc59582f0fbbdcf9f81ac9adf912a0af686"
  end

  def install
    virtualenv_install_with_resources
  end

  def caveats
    <<~EOS
      Reading saved captures works as you are. Watching live traffic needs
      access to the capture devices, so run it under sudo:

        sudo crowsnest live -i en0 --dashboard

      Wireshark's ChmodBPF helper removes that need; it ships with the cask
      (brew install --cask wireshark-app), not with this command-line build.

      To name the organisation behind an address, fetch the offline database
      once (~10 MB):

        crowsnest asn --fetch

      Blocking hosts is Linux-only: it writes nftables rules, and macOS filters
      with pf.
    EOS
  end

  test do
    assert_match "crowsnest #{version}", shell_output("#{bin}/crowsnest --version")

    # Every subcommand is reachable -- a packaging mistake that drops a module
    # shows up here rather than the first time someone runs it.
    %w[live read interfaces asn block unblock blocks update].each do |sub|
      system bin/"crowsnest", sub, "--help"
    end

    # Reading a capture is the one path that needs no privileges, so it is the
    # only end-to-end route a test can take: it proves the console script, the
    # virtualenv and the tshark this formula depends on all line up. An empty
    # file is a capture of nothing, which tshark reads quite happily.
    touch "empty.pcapng"
    output = shell_output("#{bin}/crowsnest read empty.pcapng")
    assert_match "0 packets", output
    assert_match "empty.pcapng", output

    # The resource above actually landed in the virtualenv.
    system libexec/"bin/python", "-c", "import maxminddb"
  end
end
