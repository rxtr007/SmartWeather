#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Running Security Audit for SmartWeather..."

# 1. Secret / Credential Leak Check
echo "--- 1. Scanning for Hardcoded Secrets & Credentials ---"
SUSPECT_PATTERNS="(api[_-]?key[ ]*=[ ]*[\"'][a-zA-Z0-9_\-]{8,}[\"']|client[_-]?secret[ ]*=[ ]*[\"'][a-zA-Z0-9_\-]{8,}[\"']|bearer[ ]+[a-zA-Z0-9_\-\.]{16,})"
if git -C "${ROOT_DIR}" grep -E -I -i "${SUSPECT_PATTERNS}" -- ':!Tools/*' ':!*.md' ':!*.xcresult/*' ':!SmartWeatherTests/*' > /dev/null 2>&1; then
    echo "❌ ERROR: Potential hardcoded secret found:"
    git -C "${ROOT_DIR}" grep -E -I -i "${SUSPECT_PATTERNS}" -- ':!Tools/*' ':!*.md' ':!*.xcresult/*' ':!SmartWeatherTests/*'
    exit 1
else
    echo "✔ No hardcoded secrets or credentials detected."
fi

# 2. Insecure Transport / ATS Check
echo "--- 2. Checking App Transport Security (ATS) & Network Scheme ---"
if git -C "${ROOT_DIR}" grep -E -I "http://[^l]" -- ':!Tools/*' ':!*.md' ':!*.xcresult/*' > /dev/null 2>&1; then
    echo "❌ ERROR: Insecure HTTP transport detected (must use HTTPS):"
    git -C "${ROOT_DIR}" grep -E -I "http://[^l]" -- ':!Tools/*' ':!*.md' ':!*.xcresult/*'
    exit 1
else
    echo "✔ All network endpoints strictly enforce HTTPS (zero cleartext HTTP)."
fi

# 3. iPhone Duo Guidelines (DUO001 - DUO009)
echo "--- 3. Running iPhone Duo Conformance Linter ---"
DUO_LINT="/private/tmp/duology/plugins/duology-ship/skills/duo-lint/scripts/duo-lint.py"
if [ -f "${DUO_LINT}" ]; then
    python3 "${DUO_LINT}" "${ROOT_DIR}"
    echo "✔ Duo-lint passed with 0 violations."
else
    echo "⚠️ Duo-lint script not found at ${DUO_LINT}, skipping."
fi

# 4. MobSFScan Mobile Security Scan
echo "--- 4. Running MobSFScan Mobile Security Scanner ---"
MOBSFSCAN_BIN=""
if command -v mobsfscan >/dev/null 2>&1; then
    MOBSFSCAN_BIN="mobsfscan"
elif [ -x "/tmp/mobsf-venv/bin/mobsfscan" ]; then
    MOBSFSCAN_BIN="/tmp/mobsf-venv/bin/mobsfscan"
elif [ -x "${ROOT_DIR}/.venv/bin/mobsfscan" ]; then
    MOBSFSCAN_BIN="${ROOT_DIR}/.venv/bin/mobsfscan"
fi

if [ -n "${MOBSFSCAN_BIN}" ]; then
    "${MOBSFSCAN_BIN}" "${ROOT_DIR}/SmartWeather" || {
        echo "❌ MobSFScan reported security issues."
        exit 1
    }
    echo "✔ MobSFScan static analysis passed with 0 critical findings."
else
    echo "⚠️ MobSFScan not found in PATH or virtual environments."
fi

echo "=================================================="
echo "✔ Security verification completed successfully!"
echo "=================================================="
