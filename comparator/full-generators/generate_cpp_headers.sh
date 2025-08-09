#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generates a C++ project focused on header-heavy content.

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"
source "${SCRIPT_DIR}/generate_cmake.sh"

# Levels: low | medium | high | insane
# Generators are implemented in modules under `comparator/modules/*.sh`.
generate_cpp_headers() {
  local level="${1:-medium}"


  # Always-on baseline (pure header content)
  add_macro_maze
  add_chaotic_header
  add_random_namespace_header

  case "$level" in
    low)
      ;;
    medium)
      # keep header-only; avoid generating sources
      ;;
    high)
      # increase header variety
      for _ in {1..2}; do add_random_namespace_header; done
      add_macro_maze
      ;;
    insane)
      # spray many header units (no sources)
      for _ in {1..3}; do add_macro_maze; done
      for _ in {1..3}; do add_chaotic_header; done
      for _ in {1..4}; do add_random_namespace_header; done
      ;;
    *)
      echo "[nv-generators] Unknown level '$level' (use low|medium|high|insane)" >&2
      return 2
      ;;
  esac

  # Write CMakeLists at the end, after headers are created
  if [[ ! -f CMakeLists.txt ]]; then
    write_cmakelists_headers
  fi
  stage_cmakelists_in_repo
}


