#!/usr/bin/env bash
# Copyright © 2025 ...
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeuo pipefail
IFS=$'\n\t'

# ---------- colors (respect NO_COLOR/CI) ----------
: "${NO_COLOR:=false}"
if [[ "$NO_COLOR" == "true" || -n "${CI:-}" ]]; then
  RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
else
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
fi

info() { printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "$*"; }
pass() { printf "%s[PASS]%s %s\n" "$GREEN" "$NC" "$*"; }
fail() { printf "%s[FAIL]%s %s\n" "$RED"   "$NC" "$*"; }
warn() { printf "%s[WARN]%s %s\n" "$YELLOW" "$NC" "$*"; }

# ---------- paths ----------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"

ANALYZER_SH="${PROJECT_ROOT}/dev-bin/semantic-version-analyzer.sh"
NEXT_VERSION_BIN="${PROJECT_ROOT}/build/bin/next-version"
if [[ -x "${PROJECT_ROOT}/build/bin/Release/next-version" ]]; then
  NEXT_VERSION_BIN="${PROJECT_ROOT}/build/bin/Release/next-version"
fi

# ---------- args helpers ----------
normalize_complexity() {
  local x="${1:-5}"
  case "$x" in
    low) x=2 ;;
    med|medium) x=5 ;;
    high) x=8 ;;
  esac
  [[ "$x" =~ ^[0-9]+$ ]] || { warn "Invalid complexity '$x', using 5"; x=5; }
  (( x<1 )) && x=1
  (( x>10 )) && x=10
  echo "$x"
}

# ---------- randomness ----------
NV_RANDOM_SEEDED=0
USE_FIXED_SEED=0
SEED=""

seed_random() {
  if (( USE_FIXED_SEED == 1 )); then
    if (( NV_RANDOM_SEEDED == 0 )); then
      RANDOM=$((SEED)); NV_RANDOM_SEEDED=1
    fi
    return
  fi
  local seed; seed="$(od -An -N2 -tu2 < /dev/urandom 2>/dev/null | tr -d ' ')"
  [[ -n "$seed" ]] && RANDOM=$((seed))
}
rand_int() { local min=$1 max=$2; echo $(( min + RANDOM % (max - min + 1) )); }
rand_bool(){ local p="${1:-50}"; (( RANDOM % 100 < p )) && echo 1 || echo 0; }
rand_pick(){ local -a items=("$@"); echo "${items[$((RANDOM%${#items[@]}))]}"; }
rand_word(){ local n; n="$(rand_int 6 12)"; tr -dc 'a-z' < /dev/urandom | head -c "$n" 2>/dev/null || echo "word$RANDOM"; }

# ---------- complexity scalers ----------
COMPLEXITY=5
c_scale() { awk -v b="$1" -v c="$COMPLEXITY" 'BEGIN{ printf("%d", (b*(0.6+0.1*c))+0.5) }'; }
c_range() { local smin smax; smin="$(c_scale "$1")"; smax="$(c_scale "$2")"; (( smax < smin )) && smax=$((smin+1)); echo "$(rand_int "$smin" "$smax")"; }
c_prob()  {
  local base="${1:-50}"
  [[ "$base" =~ ^[0-9]+$ ]] || base=50
  local bump=$(( (COMPLEXITY-5)*6 ))
  local p=$(( base + bump ))
  (( p<1 )) && p=1
  (( p>95 )) && p=95
  echo "$p"
}
c_lines() { awk -v b="$1" -v c="$COMPLEXITY" 'BEGIN{ printf("%d", (b*(0.5+0.12*c))+0.5) }'; }

# ---------- fs ----------
PARENT_TMP=""
mk_tmp_dir() {
  if [[ -n "$PARENT_TMP" ]]; then mkdir -p "$PARENT_TMP"; mktemp -d "$PARENT_TMP/nv-rand.XXXXXX"
  else mktemp -d "${TMPDIR:-/tmp}/nv-rand.XXXXXX"; fi
}

# ---------- git ----------
git_set_identity() {
  git -c init.defaultBranch=main init -q
  git config user.name  "NV Test $(rand_word)"
  git config user.email "nv-$(rand_word)@example.com"
}
git_safe_add() { git add -A >/dev/null; }
git_commit()   { git commit -q -m "$1" >/dev/null 2>&1 || true; }
git_tag_light(){ git tag "v$1" >/dev/null 2>&1 || true; }
git_tag_annot(){ git tag -a "v$1" -m "release $1" >/dev/null 2>&1 || true; }
git_new_branch(){ git switch -c "$1" -q >/dev/null 2>&1 || git checkout -b "$1" -q >/dev/null 2>&1; }
git_switch()   { git switch "$1" -q >/dev/null 2>&1 || git checkout "$1" -q >/dev/null 2>&1; }
git_merge_ff() { git merge --ff-only -q "$1" || true; }

# ---------- sanity ----------
preflight_tools() {
  command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 127; }
  [[ -x "$ANALYZER_SH" ]] || { echo "Analyzer not found: $ANALYZER_SH" >&2; exit 1; }
  [[ -x "$NEXT_VERSION_BIN" ]] || { echo "Binary not found: $NEXT_VERSION_BIN" >&2; exit 1; }
}
