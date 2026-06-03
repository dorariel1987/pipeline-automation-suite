#!/usr/bin/env bash
# Lightweight smoke test driver used in CI when bats is unavailable.
# Verifies that every top-level script:
#   1. Parses cleanly with bash -n.
#   2. Exits non-zero with an actionable message when required env vars
#      are missing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail=0
for s in deploy.sh rollback.sh health-check.sh secrets-sync.sh; do
    path="${SCRIPT_DIR}/${s}"
    if ! bash -n "${path}"; then
        echo "FAIL syntax: ${s}"; fail=1; continue
    fi

    out="$(env -i PATH="${PATH}" bash "${path}" 2>&1)"
    ec=$?
    if [[ ${ec} -eq 0 ]]; then
        echo "FAIL ${s} unexpectedly exited 0 without required env"
        fail=1
    elif [[ "${out}" != *"required environment variable"* ]]; then
        echo "FAIL ${s} did not produce expected error (got: ${out:0:120})"
        fail=1
    else
        echo "OK   ${s}"
    fi
done

exit "${fail}"
