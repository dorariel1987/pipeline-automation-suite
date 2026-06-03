#!/usr/bin/env bash
# Shared structured logging helpers for all automation scripts.
# Source this file with: source "$(dirname "$0")/lib/logging.sh"
#
# Safe to source multiple times — the `__SUITE_LOGGING_LOADED__` guard makes
# subsequent loads a no-op so the `readonly` colour vars below don't blow up.

if [[ -n "${__SUITE_LOGGING_LOADED__:-}" ]]; then
    return 0 2>/dev/null || true
fi
__SUITE_LOGGING_LOADED__=1

set -o errexit
set -o nounset
set -o pipefail

# Colour codes (disabled when not a TTY or when NO_COLOR is set).
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    readonly C_RESET="\033[0m"
    readonly C_RED="\033[0;31m"
    readonly C_YELLOW="\033[0;33m"
    readonly C_GREEN="\033[0;32m"
    readonly C_BLUE="\033[0;34m"
    readonly C_GRAY="\033[0;90m"
else
    readonly C_RESET=""
    readonly C_RED=""
    readonly C_YELLOW=""
    readonly C_GREEN=""
    readonly C_BLUE=""
    readonly C_GRAY=""
fi

_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log::debug() {
    [[ "${LOG_LEVEL:-info}" == "debug" ]] || return 0
    printf "%b[%s] [DEBUG]%b %s\n" "${C_GRAY}" "$(_timestamp)" "${C_RESET}" "$*" >&2
}

log::info() {
    printf "%b[%s] [INFO ]%b %s\n" "${C_BLUE}" "$(_timestamp)" "${C_RESET}" "$*" >&2
}

log::ok() {
    printf "%b[%s] [ OK  ]%b %s\n" "${C_GREEN}" "$(_timestamp)" "${C_RESET}" "$*" >&2
}

log::warn() {
    printf "%b[%s] [WARN ]%b %s\n" "${C_YELLOW}" "$(_timestamp)" "${C_RESET}" "$*" >&2
}

log::error() {
    printf "%b[%s] [ERROR]%b %s\n" "${C_RED}" "$(_timestamp)" "${C_RESET}" "$*" >&2
}

log::fatal() {
    log::error "$*"
    exit 1
}

# Run a command and pretty-print it.
log::run() {
    log::debug "+ $*"
    "$@"
}

# Require a command to be on PATH or die.
require_cmd() {
    local cmd
    for cmd in "$@"; do
        command -v "${cmd}" >/dev/null 2>&1 || \
            log::fatal "required command not found on PATH: ${cmd}"
    done
}

# Require an env var to be non-empty.
require_env() {
    local var
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            log::fatal "required environment variable is empty: ${var}"
        fi
    done
}
