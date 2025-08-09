#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# nv-compare: compare analyzer vs next-version for repo(s)
set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=nv-common.sh
source "${SCRIPT_DIR}/nv-common.sh"

QUIET=false
declare -a ARGS=()
usage() {
  cat <<EOF
nv-compare: compare analyzer vs next-version for repo(s)
Usage: $(basename "$0") [options] [REPO...]
  If no REPO is provided, reads repo paths from stdin (one per line).
Options:
  --quiet    Suppress info logs
EOF
}
while (($#)); do
  case "$1" in
    --quiet) QUIET=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
$QUIET && info() { :; }
preflight_tools

tests_passed=0
tests_failed=0

compare_one() {
  local repo_dir="$1"
  local base_name; base_name="$(basename "$repo_dir")"
  local tmp_a tmp_b
  tmp_a="$(mktemp "/tmp/${base_name}-analyzer.XXXX")"
  tmp_b="$(mktemp "/tmp/${base_name}-binary.XXXX")"
  $QUIET || info "Analyzing repo: $repo_dir"
  local out_a out_b
  set +e
  out_a="$("$ANALYZER_SH" --repo-root "$repo_dir" --json 2>/dev/null)" || true
  out_b="$("$NEXT_VERSION_BIN" --repo-root "$repo_dir" --json 2>/dev/null)" || true
  set -e
  printf "%s\n" "$out_a" > "$tmp_a"
  printf "%s\n" "$out_b" > "$tmp_b"
  if cmp -s "$tmp_a" "$tmp_b"; then
    pass "${base_name}: outputs are identical"; ((++tests_passed)); $QUIET || rm -f "$tmp_a" "$tmp_b"
  else
    fail "${base_name}: outputs differ"; ((++tests_failed))
    warn "Saved outputs: $tmp_a vs $tmp_b"
    $QUIET || diff -u "$tmp_a" "$tmp_b" || true
  fi
}

main() {
  local repos=()
  if ((${#ARGS[@]})); then
    repos=("${ARGS[@]}")
  else
    mapfile -t repos
  fi
  for r in "${repos[@]}"; do
    [[ -d "$r/.git" ]] || { warn "Skip non-git: $r"; continue; }
    compare_one "$r"
  done
  printf "\n%s=== Summary ===%s\n" "$BLUE" "$NC"
  printf "Passed: %s%d%s\n" "$GREEN" "$tests_passed" "$NC"
  printf "Failed: %s%d%s\n" "$RED"   "$tests_failed" "$NC"
  (( tests_failed == 0 ))
}
main "$@"
