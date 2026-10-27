#!/usr/bin/env bash
# Tools/run-coverage.sh
# Generates LLVM source-based code coverage report using Xcode 27.1 RC toolchain.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-27.1.0-Release.Candidate.app/Contents/Developer}"

OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/smartweather-coverage.XXXXXX")"
trap 'rm -rf "$OUT_DIR"' EXIT

TESTING_FRAMEWORKS="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/Library/Frameworks"
TESTING_MACROS="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"

SOURCES=()
while IFS= read -r -d '' file; do
    SOURCES+=("$file")
done < <(find "$PROJECT_ROOT/SmartWeather/Domain" "$PROJECT_ROOT/SmartWeather/Data" "$PROJECT_ROOT/SmartWeather/Presentation/ViewModels" -name "*.swift" -print0)

while IFS= read -r -d '' file; do
    SOURCES+=("$file")
done < <(find "$PROJECT_ROOT/SmartWeatherTests" -name "*.swift" -print0)

export LLVM_PROFILE_FILE="$OUT_DIR/coverage.profraw"

xcrun --sdk macosx swiftc \
    -swift-version 6 \
    -parse-as-library \
    -default-isolation MainActor \
    -profile-generate \
    -profile-coverage-mapping \
    -F "$TESTING_FRAMEWORKS" \
    -framework Testing \
    -Xlinker -rpath -Xlinker "$TESTING_FRAMEWORKS" \
    -load-plugin-library "$TESTING_MACROS" \
    -o "$OUT_DIR/coverage-runner" \
    "${SOURCES[@]}"

# Execute tests to generate profile raw data
"$OUT_DIR/coverage-runner" > /dev/null

# Merge profile data
xcrun llvm-profdata merge -sparse "$OUT_DIR/coverage.profraw" -o "$OUT_DIR/coverage.profdata"

# Display coverage report
echo "====================================================================================================================="
echo "                                      SMARTWEATHER CODE COVERAGE REPORT (LLVM)                                       "
echo "====================================================================================================================="
xcrun llvm-cov report \
    "$OUT_DIR/coverage-runner" \
    -instr-profile="$OUT_DIR/coverage.profdata" \
    -ignore-filename-regex="SmartWeatherTests|SanityTests"
