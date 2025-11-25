# Homebrew Formula for NexaDB
# Install with: brew install nexadb

class Nexadb < Formula
  include Language::Python::Virtualenv

  desc "Next-gen AI database with enterprise security, HNSW vector search, and 200x performance"
  homepage "https://github.com/krishcdbry/nexadb"
  url "https://github.com/krishcdbry/nexadb/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "4464836f227bc8868ea9508ff4e6f9513d9c8760455f0d6533bfe61aa70af031"
  license "MIT"
  head "https://github.com/krishcdbry/nexadb.git", branch: "main"

  # Python 3.8+ required
  depends_on "python@3"

  def install
    # Use system Python3 (works with any version)
    python3 = which("python3")

    # Install Python files
    libexec.install Dir["*.py"]
    libexec.install Dir["*.html"]

    # Install password reset utility
    if buildpath.join("reset_root_password.py").exist?
      libexec.install "reset_root_password.py"
    end

    # Create bin directory
    bin.mkpath

    # Create wrapper scripts
    (bin/"nexadb-server").write <<~EOS
      #!/bin/bash
      PYTHONPATH="#{libexec}" exec "#{python3}" "#{libexec}/nexadb_server.py" "$@"
    EOS
    (bin/"nexadb-server").chmod 0755

    (bin/"nexadb-admin").write <<~EOS
      #!/bin/bash
      PYTHONPATH="#{libexec}" exec "#{python3}" "#{libexec}/admin_server.py" "$@"
    EOS
    (bin/"nexadb-admin").chmod 0755

    # Main nexadb command
    (bin/"nexadb").write <<~EOS
#!/bin/bash

case "$1" in
  start|server)
    shift
    PYTHONPATH="#{libexec}" exec "#{python3}" "#{libexec}/nexadb_server.py" "$@"
    ;;
  admin|ui)
    shift
    PYTHONPATH="#{libexec}" exec "#{python3}" "#{libexec}/admin_server.py" "$@"
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
    PYTHONPATH="#{libexec}" "#{python3}" "#{libexec}/reset_root_password.py" --data-dir "$DATA_DIR" "$@"
    ;;
  --version|-v)
    echo "NexaDB v#{version}"
    ;;
  --help|-h|help|*)
    cat <<HELP
NexaDB - The database for quick apps

Usage:
  nexadb start              Start database server (port 6969)
  nexadb admin              Start admin UI (port 9999)
  nexadb reset-password     Reset root password to default
  nexadb --version          Show version
  nexadb --help             Show this help

Commands:
  nexadb-server             Start database server
  nexadb-admin              Start admin UI

Examples:
  nexadb start                         # Start server
  nexadb admin                         # Start admin UI
  nexadb reset-password                # Reset root password to default
  nexadb reset-password --password foo # Reset to custom password
  nexadb-server --port 8080            # Custom port
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
      ║            #{white}Production-Grade AI Database#{cyan}                            ║
      ║                     #{green}v1.3.1#{cyan}                                          ║
      ║                                                                       ║
      ╚═══════════════════════════════════════════════════════════════════════╝
      #{reset}

      #{green}#{bold}✓ Installation Complete!#{reset}

      #{yellow}#{bold}🚀 QUICK START#{reset}
         #{white}Start the database server:#{reset}
         #{cyan}$ nexadb start#{reset}

         #{white}Open the admin panel:#{reset}
         #{cyan}$ nexadb admin#{reset}

         #{white}Then visit:#{reset} #{green}http://localhost:9999/admin_panel/#{reset}

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
         #{white}Start server:#{reset}        #{cyan}nexadb start#{reset}
         #{white}Start admin UI:#{reset}      #{cyan}nexadb admin#{reset}
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
