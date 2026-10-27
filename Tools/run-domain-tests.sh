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

if [ -d "$PROJECT_ROOT/SmartWeather" ]; then
    while IFS= read -r -d '' file; do
        SOURCES+=("$file")
    done < <(find "$PROJECT_ROOT/SmartWeather" -name "*.swift" -not -path "*/App/*" -not -path "*/Presentation/Views/*" -print0)
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

TESTING_FRAMEWORKS="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/Library/Frameworks"
TESTING_MACROS="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"

xcrun --sdk macosx swiftc \
    -swift-version 6 \
    -parse-as-library \
    -default-isolation MainActor \
    -F "$TESTING_FRAMEWORKS" \
    -framework Testing \
    -Xlinker -rpath -Xlinker "$TESTING_FRAMEWORKS" \
    -load-plugin-library "$TESTING_MACROS" \
    -o "$OUT_DIR/test-runner" \
    "${SOURCES[@]}"

"$OUT_DIR/test-runner"
