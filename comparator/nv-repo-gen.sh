#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# nv-repo-gen: generate random C++ repositories for fuzz testing

set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=nv-common.sh
source "${SCRIPT_DIR}/nv-common.sh"
# shellcheck source=nv-generators.sh
source "${SCRIPT_DIR}/nv-generators.sh"

COUNT=10
CLEANUP=true
QUIET=false

usage() {
  cat <<EOF
nv-repo-gen: generate random C++ repos
Usage: $(basename "$0") [options]
  --count N               Number of repos (default: 10)
  --no-cleanup            Do not delete generated repos on exit
  --keep-repos-under DIR  Create repos under DIR (default: \$TMPDIR)
  --quiet                 Less logging
  --seed N                Fixed seed for deterministic generation
  --complexity L          1..10 or low|med|high (default: 5)
EOF
}

while (($#)); do
  case "$1" in
    --count) COUNT="${2:-}"; shift 2 ;;
    --no-cleanup) CLEANUP=false; shift ;;
    --keep-repos-under) PARENT_TMP="${2:-}"; shift 2 ;;
    --quiet) QUIET=true; shift ;;
    --seed) SEED="${2:-}"; USE_FIXED_SEED=1; shift 2 ;;
    --complexity) COMPLEXITY="$(normalize_complexity "${2:-}")"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown arg: $1"; usage; exit 2 ;;
  esac
done
$QUIET && info() { :; }

generate_random_repo() {
  seed_random
  local dir; dir="$(mk_tmp_dir)"
  $QUIET || info "Generating random repo: $dir"
  (
    cd "$dir"
    git_set_identity
    write_cmake_skel
    write_cpp_main_min
    touch_version "$(rand_int 0 2).$(rand_int 0 9).$(rand_int 0 9)"
    append_doc
    git_safe_add
    git_commit "chore(init): bootstrap project"
    maybe_tag

    # seed complexity early
    if (( $(rand_bool "$(c_prob 70)") )); then
      add_macro_maze; add_cpp_noise_unit; add_random_namespace_header
      git_safe_add; git_commit "feat: bootstrap complexity"
    fi

    local n_commits; n_commits="$(c_range 6 40)"
    local i
    # optional side branch
    if (( $(rand_bool "$(c_prob 40)") )); then
      git_new_branch "feat/$(rand_word)"
      add_feature_files_bulk; git_safe_add; git_commit "feat: add initial feature pack"
      (( $(rand_bool 50) )) && maybe_tag
      git_switch main
    fi

    for (( i=0; i<n_commits; i++ )); do
      local kind
      kind="$(rand_pick docs style feat refactor perf security test chore breaking rename delete macro chaos meta noise dead ns)"
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
        macro)    add_macro_maze; git_safe_add; git_commit "build: macro maze for fun";;
        chaos)    add_chaotic_header; git_safe_add; git_commit "feat: add chaotic header";;
        meta)     add_template_stress; git_safe_add; git_commit "perf(meta): constexpr seq + Fib";;
        noise)    add_cpp_noise_unit; git_safe_add; git_commit "feat(noise): fake arithmetic loops";;
        dead)     add_deadcode_garden; git_safe_add; git_commit "chore(dead): unreachable garden";;
        ns)       add_random_namespace_header; git_safe_add; git_commit "feat: namespace header soup";;
      esac

      (( $(rand_bool "$(c_prob 20)") )) && maybe_tag

      if (( $(rand_bool "$(c_prob 10)") )); then
        local br="exp/$(rand_word)"
        git_new_branch "$br"
        add_feature_files_bulk; git_safe_add; git_commit "feat: experimental $(rand_word)"
        if (( $(rand_bool "$(c_prob 40)") )); then
          local br2="wip/$(rand_word)"
          git_new_branch "$br2"
          add_feature_files_bulk; git_safe_add; git_commit "wip: spike $(rand_word)"
          git_switch "$br"
          git_merge_ff "$br2" || git merge --no-edit -q "$br2" || true
        fi
        git_switch main
        git_merge_ff "$br" || git merge --no-edit -q "$br" || true
      fi
    done

    (( $(rand_bool "$(c_prob 50)") )) && maybe_tag
    printf "%s\n" "$dir"
  )
}

generate_random_repos() {
  local count="${1:-10}" i=0
  while (( i < count )); do
    generate_random_repo
    ((++i))
  done
}

main() {
  # Print repo paths, one per line, to stdout.
  mapfile -t repos < <(generate_random_repos "$COUNT")

  if [[ "$CLEANUP" == "true" ]]; then
    cleanup() { for r in "${repos[@]}"; do [[ -n "$r" && -d "$r" ]] && rm -rf -- "$r"; done; }
    trap cleanup EXIT
  else
    $QUIET || { info "Keeping repos:"; printf '  %s\n' "${repos[@]}"; }
  fi

  printf '%s\n' "${repos[@]}"
}
main "$@"
