#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export RAW_RECORD_ENABLE=1
export RUN_ARTIFACTS_ENABLE="${RUN_ARTIFACTS_ENABLE:-1}"

exec bash "${PROFILE_DIR}/streaming/run_mk15_yolo_gimbal_rtsp.sh" "$@"
