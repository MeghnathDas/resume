#!/usr/bin/env bash
set -euo pipefail

# Non-interactive when run from VS Code tasks or with --yes / -y / AUTO_INSTALL=1
AUTO_INSTALL="${AUTO_INSTALL:-0}"
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_INSTALL=1 ;;
  esac
done
if [[ ! -t 0 ]]; then
  AUTO_INSTALL=1
fi

prompt_yes_no() {
  local prompt="$1"
  if [[ "$AUTO_INSTALL" == "1" ]]; then
    echo "$prompt -> yes (auto)"
    return 0
  fi
  read -r -p "$prompt (y/N): " ans
  [[ "$ans" =~ ^[Yy] ]]
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "ERROR: Need root privileges. Re-run as root or install sudo."
    return 1
  fi
}

run_tlmgr() {
  if [[ "$(id -u)" -eq 0 ]]; then
    tlmgr "$@"
    return $?
  fi

  if command -v sudo >/dev/null 2>&1; then
    if [[ -t 0 ]] || sudo -n true >/dev/null 2>&1; then
      sudo tlmgr "$@"
      return $?
    fi
  fi

  if [[ "${1:-}" == "install" ]]; then
    echo "  -> sudo is unavailable; trying tlmgr user mode"
    tlmgr --usermode init-usertree >/dev/null 2>&1 || true
    tlmgr --usermode "$@"
    return $?
  fi

  echo "  -> cannot run sudo tlmgr without an interactive terminal or cached sudo credentials"
  echo "  -> run this in a terminal:"
  echo "     sudo tlmgr $*"
  return 1
}

tlmgr_package_name() {
  case "$1" in
    sourcesanspro) echo "sourcesans" ;;
    tikzfill.image) echo "tikzfill" ;;
    *) echo "$1" ;;
  esac
}

install_xelatex_linux() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "ERROR: apt-get not found. Install TeX Live manually (texlive-xetex, texlive-latex-extra)."
    return 1
  fi
  echo "Installing TeX Live via apt (texlive-xetex, texlive-latex-extra)..."
  run_as_root apt-get update -qq
  run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended
}

install_xelatex_macos() {
  if command -v brew >/dev/null 2>&1; then
    if prompt_yes_no "Install BasicTeX via Homebrew (brew install --cask basictex)?"; then
      brew install --cask basictex
      echo "Add TeX to PATH, then re-run this task:"
      echo "  export PATH=\"/Library/TeX/texbin:\$PATH\""
      return 0
    fi
  fi
  echo "Install MacTeX or BasicTeX from https://www.tug.org/mactex/ or run: brew install --cask basictex"
  return 1
}

ensure_xelatex() {
  if command -v xelatex >/dev/null 2>&1; then
    echo "xelatex: $(command -v xelatex)"
    xelatex --version | head -n1
    return 0
  fi

  echo "xelatex not found on PATH."
  case "$(uname -s)" in
    Linux)
      if prompt_yes_no "Install xelatex with apt?"; then
        install_xelatex_linux
      else
        return 1
      fi
      ;;
    Darwin)
      install_xelatex_macos
      return $?
      ;;
    *)
      echo "ERROR: Unsupported OS. Install a TeX distribution with xelatex support."
      return 1
      ;;
  esac

  if command -v xelatex >/dev/null 2>&1; then
    echo "xelatex: $(command -v xelatex)"
    xelatex --version | head -n1
    return 0
  fi

  # apt installs to /usr/bin; Homebrew cask may need PATH refresh
  if [[ -x /Library/TeX/texbin/xelatex ]]; then
    export PATH="/Library/TeX/texbin:$PATH"
    echo "xelatex: $(command -v xelatex)"
    xelatex --version | head -n1
    return 0
  fi

  echo "ERROR: xelatex still not found after install attempt."
  return 1
}

is_debian_texlive() {
  [[ -f /usr/share/doc/texlive-base/README.tlmgr-on-Debian.md ]] \
    || dpkg -l texlive-base >/dev/null 2>&1
}

install_missing_package() {
  local pkg="$1"
  local tlmgr_pkg
  tlmgr_pkg="$(tlmgr_package_name "$pkg")"
  if is_debian_texlive && command -v apt-get >/dev/null 2>&1; then
    echo "  -> installing Awesome-CV TeX dependencies via apt (Debian TeX Live)"
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      texlive-xetex \
      texlive-latex-extra \
      texlive-fonts-extra \
      texlive-fonts-recommended
    return 0
  fi
  if command -v tlmgr >/dev/null 2>&1 && ! is_debian_texlive; then
    if prompt_yes_no "Install $tlmgr_pkg via tlmgr?"; then
      run_tlmgr install "$tlmgr_pkg" || true
    fi
    return 0
  fi
  echo "  -> Install texlive-latex-extra (Debian/Ubuntu) or use tlmgr on upstream TeX Live."
}

echo "=== Configure xelatex ==="
echo

ensure_xelatex || exit 1

echo
echo "Checking tlmgr..."
if command -v tlmgr >/dev/null 2>&1; then
  echo "tlmgr: $(command -v tlmgr)"
  if is_debian_texlive; then
    echo "Debian/Ubuntu TeX Live: use apt for packages, not tlmgr (see README.tlmgr-on-Debian.md)"
  elif prompt_yes_no "Run 'tlmgr update --self'?"; then
    run_tlmgr update --self || true
  fi
else
  echo "tlmgr: not installed (optional on Linux when using apt texlive packages)"
fi

packages=(
  array
  enumitem
  ragged2e
  geometry
  fancyhdr
  xcolor
  ifxetex
  xifthen
  ifmtarg
  etoolbox
  setspace
  fontspec
  unicode-math
  fontawesome
  sourcesanspro
  tcolorbox
  tikzfill.image
  parskip
  hyperref
)
missing=()
for p in "${packages[@]}"; do
  printf "Checking package %s... " "$p"
  if kpsewhich "${p}.sty" >/dev/null 2>&1; then
    echo "installed"
  else
    echo "missing"
    install_missing_package "$p"
    if kpsewhich "${p}.sty" >/dev/null 2>&1; then
      echo "  -> installed"
    else
      missing+=("$p")
    fi
  fi
done

echo
if ((${#missing[@]})); then
  tlmgr_missing=()
  for p in "${missing[@]}"; do
    tlmgr_missing+=("$(tlmgr_package_name "$p")")
  done
  echo "WARNING: Some packages may still be missing: ${missing[*]}"
  echo "On Ubuntu/Debian: apt install texlive-xetex texlive-latex-extra texlive-fonts-extra texlive-fonts-recommended"
  echo "On macOS/BasicTeX: sudo tlmgr install ${tlmgr_missing[*]}"
  exit 1
fi

echo "Done. xelatex and required packages are ready."
echo "Build with:"
echo "  mkdir -p dist && xelatex -interaction=nonstopmode -halt-on-error -file-line-error -output-directory=dist resume.tex && xelatex -interaction=nonstopmode -halt-on-error -file-line-error -output-directory=dist resume.tex"
echo
