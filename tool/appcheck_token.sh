#!/usr/bin/env bash
# Prints this device's Firebase App Check DEBUG TOKEN.
#
# WHY YOU NEED THIS. Debug builds use AndroidDebugProvider, whose token must be
# allowlisted in the Firebase console or every App Check-gated call fails with
#   [firebase_app_check/unknown] 403 App attestation failed
# — which kills the AI meal scan AND the coach's AI analysis. Every fresh
# install mints a NEW token, so this comes back after a reinstall.
#
# The token is printed to logcat exactly ONCE, on the first run after install,
# so by the time you go looking it is usually gone from the buffer. It is also
# kept in the app's SharedPreferences, which `run-as` can read on a debug build
# — that is the reliable path and the one this tries first.
#
# Usage:  bash tool/appcheck_token.sh          (phone connected, app installed)
set -uo pipefail

PKG="app.valence"
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
[ -x "$ADB" ] || ADB="$(command -v adb || true)"
[ -n "$ADB" ] || { echo "adb not found."; exit 1; }

if [ -z "$("$ADB" devices | sed -n '2p')" ]; then
  echo "No device. Plug the phone in, allow USB debugging, then re-run."
  exit 1
fi

echo "→ reading the app's App Check store…"
XML=$("$ADB" shell run-as "$PKG" cat \
  "/data/data/$PKG/shared_prefs/com.google.firebase.appcheck.debug.store.xml" 2>/dev/null)

TOKEN=$(printf '%s' "$XML" | sed -n 's/.*>\([0-9a-fA-F-]\{36\}\)<.*/\1/p' | head -1)

if [ -z "$TOKEN" ]; then
  echo "→ not in prefs; checking the log buffer…"
  TOKEN=$("$ADB" logcat -d 2>/dev/null \
    | grep -iEo '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
    | tail -1)
fi

if [ -z "$TOKEN" ]; then
  cat <<'EOF'
Could not find the token. Force it to be printed again:

  adb uninstall app.valence
  adb logcat -c
  flutter run                      # leave it running
  # in another terminal:
  adb logcat -d | grep -i "debug secret"

EOF
  exit 1
fi

cat <<EOF

  DEBUG TOKEN:  $TOKEN

Register it (this is the part that must be done by hand, in the console):
  1. https://console.firebase.google.com/project/valence-d72c4/appcheck/apps
  2. Android app  $PKG  →  ⋮  →  Manage debug tokens
  3. Add debug token → paste the value above → name it (e.g. "Yassine phone")
  4. Save, then FULLY restart the app.

EOF
