#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="688EF1D6-2896-4DD9-A266-3BD5CCD8B242"
SIMCTL="DEVELOPER_DIR=/Applications/Xcode-27.1.0-Release.Candidate.app/Contents/Developer xcrun simctl"

mkdir -p Screenshots

echo "Recording 6-second video of outer display..."
eval ${SIMCTL} io "${DEVICE_ID}" recordVideo --codec=h264 --display=primary --force Screenshots/demo-outer.mp4 &
PID_OUTER=$!
sleep 6
kill -INT "${PID_OUTER}" 2>/dev/null || true
wait "${PID_OUTER}" 2>/dev/null || true

echo "Recording 6-second video of inner display..."
eval ${SIMCTL} io "${DEVICE_ID}" recordVideo --codec=h264 --display=primary-1 --force Screenshots/demo-inner.mp4 &
PID_INNER=$!
sleep 6
kill -INT "${PID_INNER}" 2>/dev/null || true
wait "${PID_INNER}" 2>/dev/null || true

echo "Recordings finalized successfully."
