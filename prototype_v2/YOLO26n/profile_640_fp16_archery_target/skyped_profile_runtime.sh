#!/usr/bin/env bash

if [[ -n "${SKYPED_PROFILE_RUNTIME_SOURCED:-}" ]]; then
  return 0
fi
SKYPED_PROFILE_RUNTIME_SOURCED=1

SKYPED_PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKYPED_PROFILE_NAME="$(basename "${SKYPED_PROFILE_DIR}")"
SKYPED_REPO_ROOT="$(cd "${SKYPED_PROFILE_DIR}/../.." && pwd)"

if [[ -z "${HOST_RUNTIME_ROOT:-}" && -n "${HOST_RUNTIME_DIR:-}" ]]; then
  HOST_RUNTIME_ROOT="${HOST_RUNTIME_DIR}"
fi
: "${HOST_RUNTIME_ROOT:=${HOME}/skyped_host_runtime}"
export HOST_RUNTIME_ROOT

: "${HOST_RUNTIME_PROFILE_BIN_DIR:=${HOST_RUNTIME_ROOT}/bin/${SKYPED_PROFILE_NAME}}"
export HOST_RUNTIME_PROFILE_BIN_DIR

: "${HOST_RUNTIME_ENV_FILE:=${HOST_RUNTIME_ROOT}/env/jetson.env}"
export HOST_RUNTIME_ENV_FILE

skyped_source_host_env() {
  if [[ "${SKYPED_NO_AUTO_ENV:-0}" == "1" || "${SKYPED_ENV_FILE_AUTOLOAD:-1}" == "0" ]]; then
    return 0
  fi
  if [[ -f "${HOST_RUNTIME_ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "${HOST_RUNTIME_ENV_FILE}"
    set +a
    export SKYPED_ACTIVE_ENV_FILE="${HOST_RUNTIME_ENV_FILE}"
  fi
  if [[ -z "${HOST_RUNTIME_ROOT:-}" && -n "${HOST_RUNTIME_DIR:-}" ]]; then
    HOST_RUNTIME_ROOT="${HOST_RUNTIME_DIR}"
    export HOST_RUNTIME_ROOT
  fi
}

skyped_detect_display() {
  if [[ -n "${DISPLAY:-}" ]]; then
    printf '%s\n' "${DISPLAY}"
    return 0
  fi
  if [[ -S /tmp/.X11-unix/X0 ]]; then
    printf ':0\n'
    return 0
  fi
  if [[ -S /tmp/.X11-unix/X1 ]]; then
    printf ':1\n'
    return 0
  fi
  printf ':0\n'
}

skyped_detect_rtsp_host_ip() {
  local ip_addr=""
  if command -v ip >/dev/null 2>&1; then
    ip_addr="$(ip route get 1.1.1.1 2>/dev/null | awk '/ src / { for (i = 1; i <= NF; ++i) if ($i == "src") { print $(i + 1); exit } }')"
  fi
  if [[ -z "${ip_addr}" ]] && command -v hostname >/dev/null 2>&1; then
    ip_addr="$(hostname -I 2>/dev/null | awk '{ for (i = 1; i <= NF; ++i) if ($i !~ /^127\./) { print $i; exit } }')"
  fi
  if [[ -z "${ip_addr}" ]]; then
    ip_addr="192.168.144.100"
  fi
  printf '%s\n' "${ip_addr}"
}

skyped_default_python_bin() {
  local repo_default="${1:-python3}"
  if [[ -n "${PYTHON_BIN:-}" ]]; then
    printf '%s\n' "${PYTHON_BIN}"
    return 0
  fi
  if [[ -n "${HOST_RUNTIME_PYTHON_BIN:-}" && -x "${HOST_RUNTIME_PYTHON_BIN}" ]]; then
    printf '%s\n' "${HOST_RUNTIME_PYTHON_BIN}"
    return 0
  fi
  if [[ -x "${repo_default}" ]]; then
    printf '%s\n' "${repo_default}"
    return 0
  fi
  printf 'python3\n'
}

skyped_profile_binary_path() {
  local binary_name="$1"
  local repo_default="$2"
  local host_binary="${HOST_RUNTIME_PROFILE_BIN_DIR}/${binary_name}"
  if [[ -x "${host_binary}" ]]; then
    printf '%s\n' "${host_binary}"
    return 0
  fi
  printf '%s\n' "${repo_default}"
}

skyped_source_host_env
