#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ROOT="$(pwd)"

# Load .env if present (gitignored, holds DROPBOX_APP_KEY etc.)
if [[ -f "$ROOT/.env" ]]; then
  set -a
  source "$ROOT/.env"
  set +a
fi

OS="$(uname -s)"

# ---------- dart-define flags ----------

require_defines() {
  if [[ -z "${DROPBOX_APP_KEY:-}" ]]; then
    cat >&2 <<EOF
ERROR: DROPBOX_APP_KEY is not set.

Set it in your environment:
    export DROPBOX_APP_KEY=your_app_key_here

Or create a .env file at the repo root (gitignored):
    echo 'DROPBOX_APP_KEY=your_app_key_here' > .env
EOF
    exit 1
  fi
}

DART_DEFINES=(
  "--dart-define=DROPBOX_APP_KEY=${DROPBOX_APP_KEY:-}"
)

# ---------------------------------------------------------------
# Later, if you add more dart-defines, add them to the array:
#   DART_DEFINES+=("--dart-define=API_URL=${API_URL}")
# Every target below picks them up automatically.
# ---------------------------------------------------------------

flutter_build() {
  flutter build "$@" "${DART_DEFINES[@]}"
}

# ---------- builders ----------

build_web()     { flutter_build web --release --base-href=/Fixes/; }
build_apk()     { flutter_build apk --release --split-per-abi; }
build_aab()     { flutter_build appbundle --release; }
build_macos()   { flutter_build macos --release; }
build_ios()     { flutter_build ios --release; }
build_windows() { flutter_build windows --release; }
build_linux()   { flutter_build linux --release; }

build_all() {
  build_web
  build_apk
  case "$OS" in
    Darwin)
      build_macos
      build_ios
      ;;
    Linux)
      build_linux
      ;;
    MINGW*|MSYS*|CYGWIN*)
      build_windows
      ;;
  esac
}

# ---------- dispatch ----------

cmd="${1:-}"

# clean doesn't need dart-defines
if [[ "$cmd" == "clean" ]]; then
  flutter clean
  exit 0
fi

require_defines

case "$cmd" in
  web)     build_web ;;
  apk)     build_apk ;;
  aab)     build_aab ;;
  macos)   build_macos ;;
  ios)     build_ios ;;
  windows) build_windows ;;
  linux)   build_linux ;;
  all)     build_all ;;
  *)
    echo "Usage: $0 {web|apk|aab|macos|ios|windows|linux|all|clean}"
    exit 1
    ;;
esac