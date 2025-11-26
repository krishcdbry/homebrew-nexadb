# Homebrew Formula for NexaDB
# Install with: brew install nexadb

class Nexadb < Formula
  include Language::Python::Virtualenv

  desc "Next-gen AI database with vector search, TOON format, and unified architecture"
  homepage "https://github.com/krishcdbry/nexadb"
  url "https://github.com/krishcdbry/nexadb/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "b4bd200b5b017d53d4cab74f7eeac191b08f201e1d6b68dd50d3c19c9d1c02e5"
  license "MIT"
  head "https://github.com/krishcdbry/nexadb.git", branch: "main"

  # Python 3.8+ required
  depends_on "python@3"

  # Python dependencies
  resource "msgpack" do
    url "https://files.pythonhosted.org/packages/cb/d0/7555686ae7ff5731205df1012ede15dd9d927f6227ea151e901c7406af4f/msgpack-1.1.0.tar.gz"
    sha256 "dd432ccc2c72b914e4cb77afce64aab761c1137cc698be3984eee260bcb2896e"
  end

  def install
    # Create virtualenv
    venv = virtualenv_create(libexec, "python3")

    # Install msgpack into virtualenv
    venv.pip_install resources

    # Install Python files
    libexec.install Dir["*.py"]

    # Install admin panel directory
    if buildpath.join("admin_panel").exist?
      libexec.install "admin_panel"
    end

    # Install password reset utility
    if buildpath.join("reset_root_password.py").exist?
      libexec.install "reset_root_password.py"
    end

    # Create wrapper scripts using virtualenv Python
    (bin/"nexadb-server").write <<~EOS
      #!/bin/bash
      # Use consistent default data directory
      DATA_DIR="${DATA_DIR:-#{var}/nexadb}"
      mkdir -p "$DATA_DIR"
      exec "#{libexec}/bin/python" "#{libexec}/nexadb_server.py" --data-dir "$DATA_DIR" "$@"
    EOS
    (bin/"nexadb-server").chmod 0755

    (bin/"nexadb-admin").write <<~EOS
      #!/bin/bash
      # Use consistent default data directory
      DATA_DIR="${DATA_DIR:-#{var}/nexadb}"
      mkdir -p "$DATA_DIR"
      exec "#{libexec}/bin/python" "#{libexec}/admin_server.py" --data-dir "$DATA_DIR" "$@"
    EOS
    (bin/"nexadb-admin").chmod 0755

    # Main nexadb command
    (bin/"nexadb").write <<~EOS
#!/bin/bash

case "$1" in
  start|server)
    shift
    # Use consistent data directory
    DATA_DIR="${DATA_DIR:-#{var}/nexadb}"
    mkdir -p "$DATA_DIR"
    exec "#{libexec}/bin/python" "#{libexec}/nexadb_server.py" --data-dir "$DATA_DIR" "$@"
    ;;
  admin|ui)
    shift
    # Use consistent data directory
    DATA_DIR="${DATA_DIR:-#{var}/nexadb}"
    mkdir -p "$DATA_DIR"
    exec "#{libexec}/bin/python" "#{libexec}/admin_server.py" --data-dir "$DATA_DIR" "$@"
    ;;
  reset-password)
    shift
    # Find data directory
    DATA_DIR="./nexadb_data"
    if [ ! -d "$DATA_DIR" ]; then
      DATA_DIR="#{var}/nexadb"
    fi
    if [ ! -d "$DATA_DIR" ]; then
      DATA_DIR="/opt/homebrew/var/nexadb"
    fi
    if [ ! -d "$DATA_DIR" ]; then
      DATA_DIR="/usr/local/var/nexadb"
    fi

    # Run password reset
    "#{libexec}/bin/python" "#{libexec}/reset_root_password.py" --data-dir "$DATA_DIR" "$@"
    ;;
  --version|-v)
    echo "NexaDB v#{version}"
    ;;
  --help|-h|help|*)
    cat <<HELP
NexaDB - The database for quick apps

Usage:
  nexadb start              Start all services (Binary + REST + Admin)
  nexadb admin              Start admin UI only (port 9999)
  nexadb reset-password     Reset root password to default
  nexadb --version          Show version
  nexadb --help             Show this help

Services (when running 'nexadb start'):
  Binary Protocol           Port 6970 (10x faster!)
  JSON REST API             Port 6969 (REST fallback)
  Admin Web UI              Port 9999 (Web interface)

Commands:
  nexadb-server             Start database server
  nexadb-admin              Start admin UI

Examples:
  nexadb start                         # Start all services
  nexadb admin                         # Start admin UI only
  nexadb reset-password                # Reset root password to default
  nexadb reset-password --password foo # Reset to custom password
  nexadb-server --port 8080            # Custom port (REST only)
  nexadb-admin --host 0.0.0.0          # Bind to all interfaces

Password Reset:
  If you forget your root password, simply run:
    nexadb reset-password

  This will reset it to the default (nexadb123) without losing any data.

Learn more: https://github.com/krishcdbry/nexadb
HELP
    ;;
esac
    EOS
    (bin/"nexadb").chmod 0755

    # Download nexa CLI binary (interactive terminal)
    # Detect architecture and download the appropriate binary
    arch = Hardware::CPU.arch
    nexa_url = if arch == :arm64
      "https://github.com/krishcdbry/nexadb/releases/download/cli-v2.0.0/nexa-aarch64-apple-darwin"
    else
      "https://github.com/krishcdbry/nexadb/releases/download/cli-v2.0.0/nexa-x86_64-apple-darwin"
    end

    # Download nexa binary
    ohai "Downloading nexa CLI (interactive terminal)..."
    system "curl", "-fsSL", nexa_url, "-o", "#{bin}/nexa"
    (bin/"nexa").chmod 0755
    ohai "nexa CLI installed successfully"
  end

  def post_install
    # Auto-add Homebrew to PATH if not already present
    shell_rc = if ENV["SHELL"]&.include?("zsh")
      "#{ENV["HOME"]}/.zshrc"
    else
      "#{ENV["HOME"]}/.bash_profile"
    end

    homebrew_path = "export PATH=\"#{HOMEBREW_PREFIX}/bin:$PATH\""

    if File.exist?(shell_rc)
      content = File.read(shell_rc)
      unless content.include?("#{HOMEBREW_PREFIX}/bin")
        File.open(shell_rc, "a") do |f|
          f.puts "\n# Added by NexaDB"
          f.puts homebrew_path
        end
        ohai "Added Homebrew to PATH in #{shell_rc}"
        ohai "Run: source #{shell_rc}"
      end
    end
  end

  def caveats
    # ANSI color codes for terminal
    cyan = "\033[96m"
    green = "\033[92m"
    yellow = "\033[93m"
    magenta = "\033[95m"
    bold = "\033[1m"
    reset = "\033[0m"
    white = "\033[97m"

    <<~EOS
      #{cyan}#{bold}
      ╔═══════════════════════════════════════════════════════════════════════╗
      ║                                                                       ║
      ║     ███╗   ██╗███████╗██╗  ██╗ █████╗ ██████╗ ██████╗               ║
      ║     ████╗  ██║██╔════╝╚██╗██╔╝██╔══██╗██╔══██╗██╔══██╗              ║
      ║     ██╔██╗ ██║█████╗   ╚███╔╝ ███████║██║  ██║██████╔╝              ║
      ║     ██║╚██╗██║██╔══╝   ██╔██╗ ██╔══██║██║  ██║██╔══██╗              ║
      ║     ██║ ╚████║███████╗██╔╝ ██╗██║  ██║██████╔╝██████╔╝              ║
      ║     ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝               ║
      ║                                                                       ║
      ║            #{white}Database for AI Developers#{cyan}                             ║
      ║                     #{green}v2.1.0#{cyan}                                          ║
      ║                                                                       ║
      ╚═══════════════════════════════════════════════════════════════════════╝
      #{reset}

      #{green}#{bold}✓ Installation Complete!#{reset}

      #{yellow}#{bold}🚀 QUICK START#{reset}
         #{white}Start NexaDB (all services):#{reset}
         #{cyan}$ nexadb start#{reset}

         #{white}This starts:#{reset}
         #{green}✓#{reset} Binary Protocol (port 6970) - 10x faster!
         #{green}✓#{reset} JSON API (port 6969) - REST fallback
         #{green}✓#{reset} Admin UI (port 9999) - Web interface

      #{magenta}#{bold}🔐 DEFAULT CREDENTIALS#{reset}
         #{white}Username:#{reset} #{green}root#{reset}
         #{white}Password:#{reset} #{green}nexadb123#{reset}

         #{yellow}⚠️  IMPORTANT: Change password after first login!#{reset}

      #{cyan}#{bold}✨ KEY FEATURES#{reset}
         #{green}✓#{reset} HNSW Vector Search (200x faster)
         #{green}✓#{reset} Enterprise Security (AES-256-GCM, RBAC)
         #{green}✓#{reset} Advanced Indexing (B-Tree, Hash, Full-text)
         #{green}✓#{reset} TOON Format (40-50% LLM cost savings)
         #{green}✓#{reset} 20K reads/sec, <1ms lookups

      #{yellow}#{bold}📚 USEFUL COMMANDS#{reset}
         #{white}Start all services:#{reset}  #{cyan}nexadb start#{reset} #{white}(Binary + REST + Admin)#{reset}
         #{white}Interactive CLI:#{reset}     #{cyan}nexa -u root -p#{reset} #{white}(MySQL-like terminal)#{reset}
         #{white}Admin UI only:#{reset}       #{cyan}nexadb admin#{reset}
         #{white}Reset password:#{reset}      #{cyan}nexadb reset-password#{reset}
         #{white}Show help:#{reset}           #{cyan}nexadb --help#{reset}

      #{yellow}#{bold}💡 TROUBLESHOOTING#{reset}
         #{white}If 'nexadb' command not found:#{reset}
         #{cyan}$ source ~/.zshrc#{reset}  (or ~/.bash_profile)

         #{white}Or simply open a new terminal window.#{reset}

      #{yellow}#{bold}🔗 RESOURCES#{reset}
         #{white}Documentation:#{reset} #{cyan}https://github.com/krishcdbry/nexadb#{reset}
         #{white}Website:#{reset}       #{cyan}https://nexadb.io#{reset}

      #{white}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{reset}
      #{green}#{bold}   🎉 Ready to build! Run 'nexadb start' to begin   #{reset}
      #{white}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{reset}

    EOS
  end

  test do
    # Test that files exist
    assert_predicate libexec/"nexadb_server.py", :exist?
    assert_predicate libexec/"veloxdb_core.py", :exist?

    # Test that commands work
    assert_match "NexaDB", shell_output("#{bin}/nexadb --version")
    assert_match "Usage:", shell_output("#{bin}/nexadb --help")
  end
end
