"""Add localization keys to all six Valence .arb files at once.

Usage:
    python3 tool/l10n_add.py <<'JSON'
    { "keyName": {"en": "...", "ar": "...", "fr": "...", "es": "...", "pt": "...", "de": "..."} }
    JSON

Keeps existing keys/descriptions, appends new ones, writes valid UTF-8 JSON.
Idempotent: re-running with the same keys just overwrites their values.
"""
import json
import sys

ROOT = "lib/l10n"
LANGS = ["en", "ar", "fr", "es", "pt", "de"]

spec = json.load(sys.stdin)
for lang in LANGS:
    path = f"{ROOT}/app_{lang}.arb"
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    for key, vals in spec.items():
        # Keys starting with '@' are ARB metadata (e.g. placeholder defs) and
        # only belong in the English template; their value is written verbatim.
        if key.startswith("@"):
            if lang == "en":
                data[key] = vals
            continue
        if lang not in vals:
            raise SystemExit(f"missing '{lang}' translation for key '{key}'")
        data[key] = vals[lang]
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
print(f"ok: processed {len(spec)} keys across {len(LANGS)} langs")
