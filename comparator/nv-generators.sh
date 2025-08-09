#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# nv-generators: content generators for random repositories

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=nv-common.sh
source "${SCRIPT_DIR}/nv-common.sh"

# ---- tiny utils (auxiliary, non-breaking) ----
_whence()  { command -v -- "$1" >/dev/null 2>&1; }
_jitter()  { sleep "0.$((RANDOM%7))" 2>/dev/null || true; }
# 1 in N chance helper (defaults to N=2)
_one_in()  { local n="${1:-2}"; (( n<1 )) && n=1; (( RANDOM % n == 0 )); }
_rpick()   { if (($#>0)); then rand_pick "$@"; else printf '%s' "a"; fi }

# ---- content helpers ----
# Introduce controlled whitespace noise, or normalize, randomly.
# Uses /tmp for temp files per project rules.
whitespace_nudge() {
  local f=${1:?file}
  if (( $(rand_bool 33) )); then
    sed -E -i 's/[[:space:]]+/ /g' "$f" || true
  else
    local tmp
    tmp="$(mktemp /tmp/nvws.XXXXXX 2>/dev/null || echo /tmp/nvws.$$)"
    awk '{
      if (NR % 3 == 0) { gsub(/ /, "  "); }
      if (NR % 5 == 0) { $0=$0"\t"; }
      print
    }' "$f" > "$tmp" 2>/dev/null && mv "$tmp" "$f" || true
  fi
}
touch_version()    { printf "%s\n" "${1:-1.0.0}" > VERSION; }

append_doc() {
  mkdir -p doc
  local paras; paras="$(c_range 2 5)"
  local bullets; bullets="$(c_range 2 7)"
  local code_lines; code_lines="$(c_lines 5)"
  {
    printf "# %s %s\n\n" "$(rand_word | tr '[:lower:]' '[:upper:]')" "$(rand_word)"
    printf "_Auto-generated %s doc._\n\n" "$(rand_word)"
    printf "## Overview\n\n"
    printf "%s %s %s %s.\n\n" "$(rand_word)" "$(rand_word)" "$(rand_word)" "$(rand_word)"
    printf "## Features\n\n"
    local i
    for ((i=0;i<bullets;i++)); do
      printf "- %s %s %s\n" "$(rand_word)" "$(rand_word)" "$(rand_word)"
    done
    printf "\n## Example\n\n\`\`\`cpp\n"
    for ((i=0;i<code_lines;i++)); do
      printf "int f%d(int x){ return (x*x) + %d; }\n" "$i" "$((RANDOM%97))"
    done
    printf "\`\`\`\n\n## Details\n\n"
    for ((i=0;i<paras;i++)); do
      local words; words="$(c_lines 30)"
      tr -dc 'a-z \n' < /dev/urandom | tr -s ' ' | head -c $((words*5)) | sed 's/$/\n/' 
      echo
    done
  } >> doc/README.md 2>/dev/null || echo "$(rand_word) $(rand_word)" >> doc/README.md
}

rename_random_file() {
  local f; f="$(git ls-files | shuf -n 1 2>/dev/null || true)"; [[ -n "$f" ]] || return 0
  local dir base new; dir="$(dirname -- "$f")"; base="$(basename -- "$f")"
  local stamp; stamp="$(date +%s)$RANDOM"
  if [[ "$dir" == "." ]]; then new="renamed_${stamp}_$(rand_word)_${base}"; else new="${dir}/renamed_${stamp}_$(rand_word)_${base}"; fi
  [[ -e "$new" ]] && new="${new}.${RANDOM}"
  git mv -k "$f" "$new" >/dev/null 2>&1 || true
}
delete_random_file(){ local f; f="$(git ls-files | shuf -n 1 2>/dev/null || true)"; [[ -n "$f" ]] || return 0; git rm -q "$f" || true; }

maybe_tag() {
  # 30% chance; richer semver: MAJOR.MINOR.PATCH[-pre.N]+build.meta
  if (( $(rand_bool "$(c_prob 30)") )); then
    local maj min pat pre build
    maj=$((RANDOM%4 + 0))
    min=$((RANDOM%20))
    pat=$((RANDOM%50))
    if (( $(rand_bool 50) )); then pre="-alpha.$((RANDOM%10))"; fi
    if (( $(rand_bool 33) )); then build="+meta.$((RANDOM%100)).$((RANDOM%1000))"; fi
    local ver="${maj}.${min}.${pat}${pre:-}${build:-}"
    (( $(rand_bool 60) )) && git_tag_light "$ver" || git_tag_annot "$ver"
  fi
}

# Source modular generator scripts if present; these override in-file versions.
if [[ -d "${SCRIPT_DIR}/modules" ]]; then
  for _genmod in "${SCRIPT_DIR}/modules/"*.sh; do
    [[ -e "${_genmod}" ]] || continue
    # shellcheck disable=SC1090
    source "${_genmod}"
  done
fi

# Also source complete file generator scripts (orchestrators) if present
if [[ -d "${SCRIPT_DIR}/full-generators" ]]; then
  for _genmod in "${SCRIPT_DIR}/full-generators/"*.sh; do
    [[ -e "${_genmod}" ]] || continue
    # shellcheck disable=SC1090
    source "${_genmod}"
  done
fi
