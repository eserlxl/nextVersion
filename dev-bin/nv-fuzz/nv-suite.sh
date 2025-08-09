#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# nv-suite: end-to-end fuzzer for next-version
# Generates repos, compares analyzer vs binary, and summarizes results
set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
GEN="${SCRIPT_DIR}/nv-repo-gen.sh"
CMP="${SCRIPT_DIR}/nv-compare.sh"

COUNT=10
KEEP=false
QUIET=false
SEED=""
COMPLEXITY=5

usage() {
  cat <<EOF
nv-suite: end-to-end fuzzer (generate -> compare -> summary)
Usage: $(basename "$0") [options]
  --count N            Number of repos (default: 10)
  --keep               Do not delete generated repos
  --keep-under DIR     Create repos under DIR
  --quiet              Less logging
  --seed N             Fixed seed for deterministic generation
  --complexity L       1..10 or low|med|high (default: 5)
EOF
}

PARENT_TMP=""
while (($#)); do
  case "$1" in
    --count) COUNT="${2:-}"; shift 2 ;;
    --keep) KEEP=true; shift ;;
    --keep-under) PARENT_TMP="${2:-}"; shift 2 ;;
    --quiet) QUIET=true; shift ;;
    --seed) SEED="${2:-}"; shift 2 ;;
    --complexity) COMPLEXITY="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

main() {
  local gen_args=(--count "$COUNT" --complexity "$COMPLEXITY")
  [[ -n "$SEED" ]] && gen_args+=(--seed "$SEED")
  [[ -n "$PARENT_TMP" ]] && gen_args+=(--keep-repos-under "$PARENT_TMP")
  # Always prevent generator self-cleanup; handle cleanup here after compare
  gen_args+=(--no-cleanup)
  $QUIET && gen_args+=(--quiet)
  # Generate and capture repo list, filtering out non-path log lines.
  # Accept only absolute paths to avoid feeding logs to the comparator.
  mapfile -t repos < <("$GEN" "${gen_args[@]}" | grep -E '^/')
  # Compare
  if $QUIET; then printf '%s\n' "${repos[@]}" | "$CMP" --quiet
  else printf '%s\n' "${repos[@]}" | "$CMP"
  fi

  # Post-compare cleanup if not keeping repos
  if ! $KEEP; then
    for r in "${repos[@]}"; do
      [[ -n "$r" && -d "$r" ]] && rm -rf -- "$r"
    done
  fi
}
main
