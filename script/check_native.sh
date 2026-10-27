#!/usr/bin/env bash
set -euo pipefail

CONDUCTOR_MODE="${1:-ios-simulator}"
case "$CONDUCTOR_MODE" in
  ios-simulator|core-tests) ;;
  --help) echo "usage: $0 [ios-simulator|core-tests] (build/check only; never launches an app)"; exit 0 ;;
  *) echo "usage: $0 [ios-simulator|core-tests]" >&2; exit 2 ;;
esac
CONDUCTOR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$CONDUCTOR_ROOT"
if [[ -f "$HOME/.codex/storage-policy.md" ]]; then
  CONDUCTOR_GUARD="$HOME/Library/Application Support/LocalStorageGuard/storage_guard.py"
  [[ -f "$CONDUCTOR_GUARD" ]] || { echo "The workspace Storage Guard is unavailable." >&2; exit 1; }
  CONDUCTOR_NEED=8
  [[ "$CONDUCTOR_MODE" == core-tests ]] && CONDUCTOR_NEED=4
  python3 "$CONDUCTOR_GUARD" preflight --need-gib "$CONDUCTOR_NEED"
fi
case "$CONDUCTOR_MODE" in
  core-tests) swift test ;;
  ios-simulator)
    xcodebuild -project Conductor.xcodeproj -scheme Conductor \
      -configuration Debug -sdk iphonesimulator \
      -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath "$CONDUCTOR_ROOT/DerivedData" \
      CODE_SIGNING_ALLOWED=NO build
    ;;
esac
