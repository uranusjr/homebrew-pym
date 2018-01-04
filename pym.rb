class Pym < Formula
  desc "PYthon Manager for macOS"
  homepage "https://github.com/uranusjr/pym-macos"

  head "https://github.com/uranusjr/pym-macos", :using => :git

  depends_on "pyenv"  # TODO: We only need python-build. Can we kill this?
  depends_on "python3"
  depends_on "readline"
  depends_on "xz"

  def install
    # Create a venv to collect dependencies.
    system HOMEBREW_PREFIX/"bin/python3", "-m", "venv", "./venv"

    # Dump Pipfile to requirements.txt with Pipfile API.
    system "./venv/bin/pip", "install", "pipfile"
    txt = `"./venv/bin/python" "tools/dump_requirements.py" "Pipfile"`
    f = File.new "requirements.txt", "w"
    f.write txt
    f.close
    system "./venv/bin/pip", "uninstall", "-y", "pipfile", "toml"

    # Install the dependencies.
    system "./venv/bin/pip", "install", "-r", "requirements.txt"

    # Collect dependencies into keg.
    system "mkdir", libexec
    Dir.glob("./venv/lib/*/site-packages/*") { |item|
      name = item.rpartition("/").last
      next if [
        ".", "..", "__pycache__",
        "easy_isntall.py", "pip", "pkg_resources", "setuptools",
      ].include? name
      next if name.end_with? ".dist-info"
      libexec.install item
    }

    # Copy pym into keg.
    libexec.install "pym"

    # Generate launcher.
    f = File.new("pym", "w")
    f.write <<~EOS
\#!#{HOMEBREW_PREFIX}/bin/python3

import sys
sys.path.insert(0, '#{libexec}')

if __name__ == '__main__':
    import pym.__main__
    pym.__main__.cli()

EOS
    f.close()

    # Install the launcher.
    system "mkdir", bin
    bin.install "pym"
  end
end
