#!/usr/bin/env bash
# Tools/run-domain-tests.sh
# Fast, sub-second pure-Swift domain and unit test runner using Xcode 27.1 Swift compiler on macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-27.1.0-Release.Candidate.app/Contents/Developer}"

OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/smartweather-tests.XXXXXX")"
trap 'rm -rf "$OUT_DIR"' EXIT

SOURCES=()

if [ -d "$PROJECT_ROOT/SmartWeather/Domain" ]; then
    while IFS= read -r -d '' file; do
        SOURCES+=("$file")
    done < <(find "$PROJECT_ROOT/SmartWeather/Domain" -name "*.swift" -print0)
fi

if [ -d "$PROJECT_ROOT/SmartWeatherTests" ]; then
    while IFS= read -r -d '' file; do
        SOURCES+=("$file")
    done < <(find "$PROJECT_ROOT/SmartWeatherTests" -name "*.swift" -print0)
fi

if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "No source or test files found"
    exit 1
fi

xcrun --sdk macosx swiftc \
    -swift-version 6 \
    -parse-as-library \
    -default-isolation MainActor \
    -o "$OUT_DIR/test-runner" \
    "${SOURCES[@]}"

"$OUT_DIR/test-runner"
