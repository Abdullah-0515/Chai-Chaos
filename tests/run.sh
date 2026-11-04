#!/usr/bin/env bash
# Plays through Chai Chaos on a mock Roblox engine (no Studio needed).
# Needs: Rust (cargo), Python 3 and curl. Run from anywhere: tests/run.sh
set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$TEST_DIR")"
CACHE_DIR="$TEST_DIR/.cache"
mkdir -p "$CACHE_DIR"

# 1. The Roblox API dump, used to check every property, method, event and enum.
if [ ! -f "$CACHE_DIR/API-Dump.json" ]; then
  curl -sSfL -o "$CACHE_DIR/API-Dump.json" \
    https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
fi
if [ ! -f "$CACHE_DIR/api.luau" ] || [ "$CACHE_DIR/API-Dump.json" -nt "$CACHE_DIR/api.luau" ]; then
  python3 "$TEST_DIR/gen_api.py" "$CACHE_DIR/API-Dump.json" "$CACHE_DIR/api.luau"
fi

# 2. The list of source files, laid out like default.project.json.
{
  echo "return {"
  for dir in shared server client; do
    printf '%s = {' "$dir"
    for f in "$ROOT/src/$dir"/*.luau; do printf '"%s",' "$(basename "$f")"; done
    echo "},"
  done
  echo "}"
} > "$CACHE_DIR/filelist.luau"

# 3. A tiny Rust program that embeds the real Luau VM.
cargo build --release --quiet --manifest-path "$TEST_DIR/runner/Cargo.toml"

TEST_DIR="$TEST_DIR" CACHE_DIR="$CACHE_DIR" SRC_DIR="$ROOT/src" \
  "$TEST_DIR/runner/target/release/luau-runner" "$TEST_DIR/playthrough.luau"
