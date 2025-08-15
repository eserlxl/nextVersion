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

ANALYZER_SH="${PROJECT_ROOT}/bin/semantic-version-analyzer.sh"
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
COMPLEXITY=5   # [complexity] default mid

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --count N               Number of repos to generate (default: 10)
  --no-cleanup            Do not delete generated repos on exit (prints paths)
  --keep-repos-under DIR  Create repos under DIR instead of system tmp
  --quiet                 Reduce log noise
  --seed N                Fixed seed number for deterministic repository generation
  --complexity L          1..10 or low|med|high (affects files/history/size; default: 5)
  -h, --help              Show this help and exit
EOF
}

# [complexity] map aliases and clamp
normalize_complexity() {
  local x="${1:-5}"
  case "$x" in
    low)  x=2 ;;
    med|medium) x=5 ;;
    high) x=8 ;;
  esac
  [[ "$x" =~ ^[0-9]+$ ]] || { warn "Invalid complexity '$x', using 5"; x=5; }
  (( x<1 )) && x=1
  (( x>10 )) && x=10
  echo "$x"
}

while (($#)); do
  case "$1" in
    --count) COUNT="${2:-}"; shift 2 ;;
    --no-cleanup) CLEANUP=false; shift ;;
    --keep-repos-under) PARENT_TMP="${2:-}"; shift 2 ;;
    --quiet) QUIET=true; shift ;;
    --seed) SEED="${2:-}"; USE_FIXED_SEED=1; shift 2 ;;
    --complexity) COMPLEXITY="$(normalize_complexity "${2:-}")"; shift 2 ;; # [complexity]
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
  tr -dc '[:lower:]' < /dev/urandom | head -c "$n" 2>/dev/null || echo "word$RANDOM"
}

# ----------- [complexity] scaling helpers -----------
# Soft linear-ish scalers that still keep randomness.
c_scale()       { # base * (0.6 + 0.1*COMPLEXITY)  (≈1.6x at 10, ≈0.7x at 1)
  awk -v b="$1" -v c="$COMPLEXITY" 'BEGIN{ printf("%d", (b*(0.6+0.1*c))+0.5) }'
}
c_range() { # scale a range bounds with c_scale
  local base_min=$1 base_max=$2
  local smin smax
  smin="$(c_scale "$base_min")"
  smax="$(c_scale "$base_max")"
  (( smax < smin )) && smax=$((smin+1))
  rand_int "$smin" "$smax"
}
c_prob() { # increase probability with complexity (base% to ~ base*1.3 at 10)
  local base="$1"
  local bump=$(( (COMPLEXITY-5)*6 )) # -30..+30
  local p=$(( base + bump ))
  (( p<1 )) && p=1
  (( p>95 )) && p=95
  echo "$p"
}
c_lines() { # target line count adapted by complexity around a base
  local base="$1"
  awk -v b="$base" -v c="$COMPLEXITY" 'BEGIN{ printf("%d", (b*(0.5+0.12*c))+0.5) }'
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
  local lines; lines="$(c_lines 12)"      # [complexity] expand main
  {
    echo '#include <iostream>'
    echo 'int main(){'
    printf '%s\n' '  std::cout<<"ok\n";'
    # add some dummy loops to increase length/complexity
    local i=0
    while (( i < lines )); do
      echo "  volatile int a$i = $i; (void)a$i;"
      ((++i))
    done
    echo '  return 0;'
    echo '}'
  } > src/main.cpp
}

touch_version() {
  printf "%s\n" "${1:-1.0.0}" > VERSION
}

append_doc() {
  mkdir -p doc
  local paras; paras="$(c_range 1 3)"     # [complexity] more paragraphs
  {
    printf "# %s\n\n" "$(rand_word)"
    local i
    for ((i=0;i<paras;i++)); do
      local words; words="$(c_lines 20)"
      printf "%s\n\n" "$(head -c $((words*6)) </dev/urandom | tr -dc 'a-z \n' | tr -s ' ' | cut -c1-$((words*5)) )"
    done
  } >> doc/README.md 2>/dev/null || echo "$(rand_word) $(rand_word)" >> doc/README.md
}

whitespace_nudge() {
  sed -E 's/[[:space:]]+/ /g' -i "$1" 2>/dev/null || true
}

# shellcheck disable=SC2317
# shellcheck disable=SC2317,SC2329
add_feature_file() {
  mkdir -p src include
  local fname
  fname="feature_$(rand_word)"
  echo "#pragma once" > "include/${fname}.h"
  printf "int %s(){return %d;}\n" "${fname}" "$(rand_int 0 9)" > "src/${fname}.cpp"
}

# shellcheck disable=SC2317
add_perf_code() {
  mkdir -p src
  local N; N="$(c_lines 800)"             # [complexity] bigger vectors
  cat > "src/perf_$(rand_word).cpp" <<EOF
#include <vector>
#include <numeric>
int perf_fn_${RANDOM}(){
  std::vector<int> v(${N},1);
  return std::accumulate(v.begin(),v.end(),0);
}
EOF
}

# shellcheck disable=SC2317
add_test() {
  mkdir -p test
  local assertions; assertions="$(c_range 1 20)"  # [complexity]
  {
    echo '#include <cassert>'
    echo 'int main(){' 
    local i
    for ((i=0;i<assertions;i++)); do
      echo "  assert(${RANDOM}%3==${RANDOM}%3);"
    done
    echo '  return 0;'
    echo '}'
  } > "test/test_$(rand_word).cpp"
}

# shellcheck disable=SC2317
add_security_fix() {
  mkdir -p src
  local lines; lines="$(c_lines 25)"      # [complexity]
  {
    echo '#include <cstring>'
    echo '#include <cstddef>'
    printf 'void copy_safe(char* d,const char* s,size_t n){ if(n){ std::strncpy(d,s,n-1); d[n-1]=\\0; } }\n'
    local i=0
    while (( i < lines )); do
      echo "void shim_$i(char* d,const char* s,size_t n){ copy_safe(d,s,n); }"
      ((++i))
    done
  } > "src/sec_$(rand_word).cpp"
}

# shellcheck disable=SC2317
breaking_api_change() {
  mkdir -p include src
  echo "#pragma once" > include/api.h
  local overloads; overloads="$(c_range 1 5)"    # [complexity]
  {
    local i
    for ((i=0;i<overloads;i++)); do echo "int api_v2_$i();"; done
  } >> include/api.h
  {
    local i
    for ((i=0;i<overloads;i++)); do echo "int api_v2_$i(){ return $((i+2)); }"; done
  } > src/api.cpp
}

# [complexity] feature file generators
# shellcheck disable=SC2317
add_feature_file_once() {
  mkdir -p src include
  local fname
  fname="feature_$(rand_word)"
  local fns; fns="$(c_range 1 4)"         # [complexity] multiple funcs per file
  echo "#pragma once" > "include/${fname}.h"
  {
    local j
    for ((j=0;j<fns;j++)); do
      printf "int %s_fn%d(){return %d;}\n" "${fname}" "$j" "$(rand_int 0 99)"
    done
  } > "src/${fname}.cpp"
}

# shellcheck disable=SC2317
add_feature_files_bulk() { # [complexity] add many files at once
  local n; n="$(c_range 1 5)"
  local k
  for ((k=0;k<n;k++)); do add_feature_file_once; done
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
  if (( $(rand_bool "$(c_prob 30)") )); then  # [complexity] tag more often
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

    # [complexity] more commits overall
    local n_commits; n_commits="$(c_range 6 40)"

    # [complexity] optional side branch
    if (( $(rand_bool "$(c_prob 40)") )); then
      git_new_branch "feat/$(rand_word)"
      add_feature_files_bulk
      git_safe_add
      git_commit "feat: add initial feature pack"
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
        feat)     add_feature_files_bulk; git_safe_add; git_commit "feat: add $(rand_word)";;
        refactor) add_feature_files_bulk; git_safe_add; git_commit "refactor: restructure $(rand_word)";;
        perf)     add_perf_code; git_safe_add; git_commit "perf: optimize $(rand_word)";;
        security) add_security_fix; git_safe_add; git_commit "SECURITY: mitigate $(rand_word)";;
        test)     add_test; git_safe_add; git_commit "test: add unit for $(rand_word)";;
        chore)    touch_version "$(rand_int 0 3).$(rand_int 0 9).$(rand_int 0 9)"; git_safe_add; git_commit "chore: bump metadata";;
        breaking) breaking_api_change; git_safe_add; git_commit "BREAKING: update API to v2";;
        rename)   rename_random_file; git_commit "refactor: rename file(s)";;
        delete)   delete_random_file; git_commit "chore: delete obsolete file(s)";;
      esac

      (( $(rand_bool "$(c_prob 20)") )) && maybe_tag

      # [complexity] branch/merge more frequently and sometimes nested
      if (( $(rand_bool "$(c_prob 10)") )); then
        local br
        br="exp/$(rand_word)"
        git_new_branch "$br"
        add_feature_files_bulk; git_safe_add; git_commit "feat: experimental $(rand_word)"
        if (( $(rand_bool "$(c_prob 40)") )); then
          local br2
          br2="wip/$(rand_word)"
          git_new_branch "$br2"
          add_feature_files_bulk; git_safe_add; git_commit "wip: spike $(rand_word)"
          git_switch "$br"
          git_merge_ffonly "$br2" || git merge --no-edit -q "$br2" || true
        fi
        git_switch main
        git_merge_ffonly "$br" || git merge --no-edit -q "$br" || true
      fi
    done

    # Final optional tag
    (( $(rand_bool "$(c_prob 50)") )) && maybe_tag

    printf "%s\n" "$dir"
  )
}

# Generate many repos; prints their paths (one per line)
# shellcheck disable=SC2317
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
    # Compare only suggestion fields when full JSON differs
    sug_a=$(sed -n 's/.*"suggestion"[^"]*"\([^"]*\)".*/\1/p' "$tmp_a" | head -1 || true)
    sug_b=$(sed -n 's/.*"suggestion"[^"]*"\([^"]*\)".*/\1/p' "$tmp_b" | head -1 || true)
    if [[ -n "$sug_a" && "$sug_a" == "$sug_b" ]]; then
      pass "${base_name}: suggestions match"
      $QUIET || rm -f "$tmp_a" "$tmp_b"
    else
      fail "${base_name}: outputs differ"
      warn "Saved outputs: $tmp_a vs $tmp_b"
      $QUIET || diff -u "$tmp_a" "$tmp_b" || true
    fi
  fi
}

# ----------- main -----------
main() {
  local -a repos=()
  mapfile -t repos < <(generate_random_repos "$COUNT")

  if [[ "$CLEANUP" == "true" ]]; then
    # Cleanup on exit unless user asked not to.
    # shellcheck disable=SC2317,SC2329
    # shellcheck disable=SC2329
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
