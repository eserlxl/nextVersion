#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Random repo fuzzer for next-version vs analyzer parity
# - Generates realistic, randomized Git repos
# - Compares CLI outputs
# - Summarizes pass/fail

set -Eeuo pipefail
IFS=$'\n\t'

# ----------- traps & diagnostics -----------
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND" >&2' ERR

# ----------- colors (respect NO_COLOR) -----------
: "${NO_COLOR:=false}"
if [[ "$NO_COLOR" == "true" || -n "${CI:-}" ]]; then
  RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
else
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
fi

info() { printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "$*"; }
pass() { printf "%s[PASS]%s %s\n" "$GREEN" "$NC" "$*"; ((++tests_passed)); }
fail() { printf "%s[FAIL]%s %s\n" "$RED"   "$NC" "$*"; ((++tests_failed)); }
warn() { printf "%s[WARN]%s %s\n" "$YELLOW" "$NC" "$*"; }

tests_passed=0
tests_failed=0
NV_RANDOM_SEEDED=0

# Whether a fixed seed was requested via CLI
USE_FIXED_SEED=0

# ----------- layout -----------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"

ANALYZER_SH="${PROJECT_ROOT}/dev-bin/semantic-version-analyzer.sh"
NEXT_VERSION_BIN="${PROJECT_ROOT}/build/bin/next-version"
# Prefer Release binary if present (matches build output), fallback to legacy path
if [[ -x "${PROJECT_ROOT}/build/bin/Release/next-version" ]]; then
  NEXT_VERSION_BIN="${PROJECT_ROOT}/build/bin/Release/next-version"
fi

# ----------- CLI -----------
COUNT=10
CLEANUP=true
PARENT_TMP=""
QUIET=false
SEED=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --count N               Number of repos to generate (default: 10)
  --no-cleanup            Do not delete generated repos on exit (prints their paths)
  --keep-repos-under DIR  Create repos under DIR instead of system tmp
  --quiet                 Reduce log noise
  --seed N                Fixed seed number for deterministic repository generation
  -h, --help              Show this help and exit
EOF
}

while (($#)); do
  case "$1" in
    --count) COUNT="${2:-}"; shift 2 ;;
    --no-cleanup) CLEANUP=false; shift ;;
    --keep-repos-under) PARENT_TMP="${2:-}"; shift 2 ;;
    --quiet) QUIET=true; shift ;;
    --seed) SEED="${2:-}"; USE_FIXED_SEED=1; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

$QUIET && info() { :; }

# ----------- preflight -----------
command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 127; }

if [[ ! -x "$ANALYZER_SH" ]]; then
  fail "Analyzer script not found or not executable: $ANALYZER_SH"
  exit 1
fi
if [[ ! -x "$NEXT_VERSION_BIN" ]]; then
  fail "next-version binary not found or not executable: $NEXT_VERSION_BIN"
  exit 1
fi

# ----------- randomness helpers -----------
seed_random() {
  # If a fixed seed was requested, seed once and keep sequence deterministic
  if (( USE_FIXED_SEED == 1 )); then
    if (( NV_RANDOM_SEEDED == 0 )); then
      RANDOM=$((SEED))
      NV_RANDOM_SEEDED=1
    fi
    return
  fi

  # Otherwise, seed $RANDOM per-repo from urandom for stronger entropy
  local seed
  seed="$(od -An -N2 -tu2 < /dev/urandom 2>/dev/null | tr -d ' ')"
  [[ -n "$seed" ]] && RANDOM=$((seed))
}
rand_int() { # rand_int MIN MAX
  local min=$1 max=$2
  echo $(( min + RANDOM % (max - min + 1) ))
}
rand_bool() { # rand_bool [PERCENT_TRUE]
  local p="${1:-50}"
  (( RANDOM % 100 < p )) && echo 1 || echo 0
}
rand_pick() { # rand_pick item1 item2 ...
  local -a items=("$@")
  local idx=$(( RANDOM % ${#items[@]} ))
  echo "${items[$idx]}"
}
rand_word() {
  local n; n="$(rand_int 6 12)"
  tr -dc 'a-z' < /dev/urandom | head -c "$n" 2>/dev/null || echo "word$RANDOM"
}

# ----------- filesystem helpers -----------
mk_tmp_dir() {
  if [[ -n "$PARENT_TMP" ]]; then
    mkdir -p "$PARENT_TMP"
    mktemp -d "$PARENT_TMP/nv-rand.XXXXXX"
  else
    mktemp -d "${TMPDIR:-/tmp}/nv-rand.XXXXXX"
  fi
}

# ----------- git helpers -----------
git_set_identity() {
  git -c init.defaultBranch=main init -q
  git config user.name  "NV Test $(rand_word)"
  git config user.email "nv-$(rand_word)@example.com"
}

git_safe_add() { git add -A >/dev/null; }
git_commit()   { local m=$1; git commit -q -m "$m" >/dev/null 2>&1 || true; }
git_tag_light()      { git tag "v$1" >/dev/null 2>&1 || true; }
git_tag_annotated()  { git tag -a "v$1" -m "release $1" >/dev/null 2>&1 || true; }
git_new_branch()     { git switch -c "$1" -q >/dev/null 2>&1 || git checkout -b "$1" -q >/dev/null 2>&1; }
git_switch()         { git switch "$1" -q >/dev/null 2>&1 || git checkout "$1" -q >/dev/null 2>&1; }
git_merge_ffonly()   { git merge --ff-only -q "$1" || true; }

# ----------- content helpers -----------
write_cmake_skel() {
  cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.12)
project(nvproj LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
add_executable(nvmain src/main.cpp)
target_include_directories(nvmain PRIVATE include)
EOF
}

write_cpp_main_min() {
  mkdir -p src include
  cat > src/main.cpp <<'EOF'
#include <iostream>
int main(){ std::cout<<"ok\n"; return 0; }
EOF
}

touch_version() {
  printf "%s\n" "${1:-1.0.0}" > VERSION
}

append_doc() {
  mkdir -p doc
  printf "# %s\n\n%s\n" "$(rand_word)" "$(rand_word) $(rand_word) $(rand_word)." >> doc/README.md
}

whitespace_nudge() {
  sed -E 's/[[:space:]]+/ /g' -i "$1" 2>/dev/null || true
}

add_feature_file() {
  mkdir -p src include
  local fname="feature_$(rand_word)"
  echo "#pragma once" > "include/${fname}.h"
  printf "int %s(){return %d;}\n" "${fname}" "$(rand_int 0 9)" > "src/${fname}.cpp"
}

add_perf_code() {
  mkdir -p src
  cat > "src/perf_$(rand_word).cpp" <<'EOF'
#include <vector>
#include <numeric>
int perf_fn(){ std::vector<int> v(1000,1); return std::accumulate(v.begin(),v.end(),0); }
EOF
}

add_test() {
  mkdir -p test
  cat > "test/test_$(rand_word).cpp" <<'EOF'
#include <cassert>
int main(){ assert(1); return 0; }
EOF
}

add_security_fix() {
  mkdir -p src
  cat > src/sec_tmp.cpp <<'EOF'
#include <cstring>
void copy_safe(char* d,const char* s,size_t n){ if(n){ std::strncpy(d,s,n-1); d[n-1]='\0'; } }
EOF
}

breaking_api_change() {
  mkdir -p include src
  echo "#pragma once" > include/api.h
  echo "int api_v2();" >> include/api.h
  echo "int api_v2(){ return 2; }" > src/api.cpp
}

rename_random_file() {
  local f
  f="$(git ls-files | shuf -n 1 2>/dev/null || true)"
  [[ -n "$f" ]] || return 0

  local dir base new
  dir="$(dirname -- "$f")"
  base="$(basename -- "$f")"

  # If the file is at repository root (dir is "."), rename in place without creating a directory
  if [[ "$dir" == "." ]]; then
    new="renamed_$(rand_word)_${base}"
  else
    new="${dir}/renamed_$(rand_word)_${base}"
  fi

  # Avoid collisions if the target already exists
  if [[ -e "$new" ]]; then
    if [[ "$dir" == "." ]]; then
      new="renamed_$(rand_word)_${RANDOM}_${base}"
    else
      new="${dir}/renamed_$(rand_word)_${RANDOM}_${base}"
    fi
  fi

  # Move the file; do not attempt to create directories for top-level files
  git mv "$f" "$new" >/dev/null 2>&1 || true
}

delete_random_file() {
  local f
  f="$(git ls-files | shuf -n 1 2>/dev/null || true)"
  [[ -n "$f" ]] || return 0
  git rm -q "$f" || true
}

maybe_tag() {
  if (( $(rand_bool 30) )); then
    local v_major v_minor v_patch
    v_major="$(rand_int 0 3)"
    v_minor="$(rand_int 0 9)"
    v_patch="$(rand_int 0 9)"
    local ver="${v_major}.${v_minor}.${v_patch}"
    if (( $(rand_bool 60) )); then git_tag_light "$ver"; else git_tag_annotated "$ver"; fi
  fi
}

# ----------- REALLY random repo generator -----------
generate_random_repo() {
  seed_random
  local dir; dir="$(mk_tmp_dir)"
  # Print progress to stderr to avoid polluting stdout captured by mapfile
  if [[ "$QUIET" == "false" ]]; then
    printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "Generating random repo: $dir" >&2
  fi
  (
    cd "$dir"

    git_set_identity

    # Minimal skeleton
    write_cmake_skel
    write_cpp_main_min
    touch_version "$(rand_int 0 2).$(rand_int 0 9).$(rand_int 0 9)"
    append_doc
    git_safe_add
    git_commit "chore(init): bootstrap project"

    maybe_tag

    # Random number of commits
    local n_commits; n_commits="$(rand_int 5 40)"

    # Maybe create a side branch
    if (( $(rand_bool 40) )); then
      git_new_branch "feat/$(rand_word)"
      add_feature_file
      git_safe_add
      git_commit "feat: add initial feature"
      (( $(rand_bool 50) )) && maybe_tag
      git_switch main
    fi

    local i
    for (( i=0; i<n_commits; i++ )); do
      local kind
      kind="$(rand_pick docs style feat refactor perf security test chore breaking rename delete)"
      case "$kind" in
        docs)     append_doc; git_safe_add; git_commit "docs: $(rand_word)";;
        style)    whitespace_nudge "src/main.cpp" || true; git_safe_add; git_commit "style: whitespace tweaks";;
        feat)     add_feature_file; git_safe_add; git_commit "feat: add $(rand_word)";;
        refactor) add_feature_file; git_safe_add; git_commit "refactor: restructure $(rand_word)";;
        perf)     add_perf_code; git_safe_add; git_commit "perf: optimize $(rand_word)";;
        security) add_security_fix; git_safe_add; git_commit "SECURITY: mitigate $(rand_word)";;
        test)     add_test; git_safe_add; git_commit "test: add unit for $(rand_word)";;
        chore)    touch_version "$(rand_int 0 3).$(rand_int 0 9).$(rand_int 0 9)"; git_safe_add; git_commit "chore: bump metadata";;
        breaking) breaking_api_change; git_safe_add; git_commit "BREAKING: update API to v2";;
        rename)   rename_random_file; git_commit "refactor: rename file(s)";;
        delete)   delete_random_file; git_commit "chore: delete obsolete file(s)";;
      esac

      # Occasionally tag after a commit
      (( $(rand_bool 20) )) && maybe_tag

      # Occasionally branch/merge
      if (( $(rand_bool 10) )); then
        local br="exp/$(rand_word)"
        git_new_branch "$br"
        add_feature_file; git_safe_add; git_commit "feat: experimental $(rand_word)"
        git_switch main
        git_merge_ffonly "$br" || git merge --no-edit -q "$br" || true
      fi
    done

    # Final optional tag
    (( $(rand_bool 50) )) && maybe_tag

    printf "%s\n" "$dir"
  )
}

# Generate many repos; prints their paths (one per line)
generate_random_repos() {
  local count="${1:-10}"
  local i=0
  while (( i < count )); do
    generate_random_repo
    ((++i))
  done
}

# ----------- comparison -----------
compare_outputs_for_repo() {
  local repo_dir="$1"
  local base_name; base_name="$(basename "$repo_dir")"
  local tmp_a tmp_b
  tmp_a="$(mktemp "/tmp/${base_name}-analyzer.XXXX")"
  tmp_b="$(mktemp "/tmp/${base_name}-binary.XXXX")"

  $QUIET || info "Analyzing repo: $repo_dir"

  local out_a out_b
  # Use JSON output to avoid formatting drift and ensure zero exit codes
  set +e
  out_a="$("$ANALYZER_SH" --repo-root "$repo_dir" --json 2>/dev/null)" || true
  out_b="$("$NEXT_VERSION_BIN" --repo-root "$repo_dir" --json 2>/dev/null)" || true
  set -e

  printf "%s\n" "$out_a" > "$tmp_a"
  printf "%s\n" "$out_b" > "$tmp_b"

  if cmp -s "$tmp_a" "$tmp_b"; then
    pass "${base_name}: outputs are identical"
    $QUIET || rm -f "$tmp_a" "$tmp_b"
  else
    fail "${base_name}: outputs differ"
    warn "Saved outputs: $tmp_a vs $tmp_b"
    $QUIET || diff -u "$tmp_a" "$tmp_b" || true
  fi
}

# ----------- main -----------
main() {
  local -a repos=()
  mapfile -t repos < <(generate_random_repos "$COUNT")

  if [[ "$CLEANUP" == "true" ]]; then
    # Cleanup on exit unless user asked not to.
    cleanup() {
      for r in "${repos[@]}"; do
        [[ -n "$r" && -d "$r" ]] && rm -rf -- "$r"
      done
    }
    trap cleanup EXIT
  else
    info "Keeping repos:"
    printf '  %s\n' "${repos[@]}"
  fi

  for repo in "${repos[@]}"; do
    compare_outputs_for_repo "$repo"
  done

  printf "\n%s=== Summary ===%s\n" "$BLUE" "$NC"
  printf "Passed: %s%d%s\n" "$GREEN" "$tests_passed" "$NC"
  printf "Failed: %s%d%s\n" "$RED"   "$tests_failed" "$NC"

  if (( tests_failed == 0 )); then
    info "All repository comparisons PASSED"
    exit 0
  else
    warn "Some repository comparisons FAILED"
    exit 1
  fi
}

main "$@"
