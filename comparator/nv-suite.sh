#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# nv-suite: end-to-end fuzzer for next-version
# Generates repos using fake-repo, compares analyzer vs binary, and summarizes results

set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CMP="${SCRIPT_DIR}/nv-compare.sh"

COUNT=10
KEEP=false
QUIET=false
SEED=""
COMPLEXITY=5
PARENT_TMP=""

normalize_complexity() {
  local x="${1:-5}"
  case "$x" in
    low) x=2 ;;
    med|medium) x=5 ;;
    high) x=8 ;;
  esac
  if ! [[ "$x" =~ ^[0-9]+$ ]]; then x=5; fi
  if (( x < 1 )); then x=1; fi
  if (( x > 10 )); then x=10; fi
  echo "$x"
}

require_fake_repo() {
  if ! command -v fake-repo >/dev/null 2>&1; then
    echo "fake-repo not found in PATH. Please install it and try again." >&2
    exit 127
  fi
}

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
  require_fake_repo
  local repos=()

  # Determine parent folder under which to create repositories
  local parent
  if [[ -n "$PARENT_TMP" ]]; then
    mkdir -p "$PARENT_TMP"
    parent="$PARENT_TMP"
  else
    parent="$(mktemp -d "/tmp/nv-repos.XXXXXX")"
  fi

  local eff_complexity
  eff_complexity="$(normalize_complexity "$COMPLEXITY")"

  # Generate COUNT repositories using fake-repo
  local i
  for (( i=1; i<=COUNT; i++ )); do
    # Use deterministic seeds when provided; vary per iteration
    local this_seed=""
    if [[ -n "$SEED" && "$SEED" =~ ^[0-9]+$ ]]; then
      this_seed=$(( SEED + i - 1 ))
    fi

    # Create a unique destination path under parent
    local repo_dir
    repo_dir="${parent}/nv-repo.$(printf "%03d" "$i").$RANDOM"

    # Build command
    if [[ -n "$this_seed" ]]; then
      if $QUIET; then
        fake-repo -x "$eff_complexity" --seed "$this_seed" "$repo_dir" >/dev/null 2>&1 || true
      else
        fake-repo -x "$eff_complexity" --seed "$this_seed" "$repo_dir" || true
      fi
    else
      if $QUIET; then
        fake-repo -x "$eff_complexity" "$repo_dir" >/dev/null 2>&1 || true
      else
        fake-repo -x "$eff_complexity" "$repo_dir" || true
      fi
    fi

    if [[ -d "$repo_dir/.git" ]]; then
      repos+=("$repo_dir")
    else
      echo "Failed to generate repo at: $repo_dir" >&2
    fi
  done

  # Compare
  if $QUIET; then printf '%s\n' "${repos[@]}" | "$CMP" --quiet
  else printf '%s\n' "${repos[@]}" | "$CMP"
  fi

  # Post-compare cleanup if not keeping repos
  if ! $KEEP; then
    for r in "${repos[@]}"; do
      if [[ -n "$r" && -d "$r" ]]; then
        rm -rf -- "$r"
      fi
    done
  fi
}
main
