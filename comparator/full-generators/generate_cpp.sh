#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generates a C++ project with a variety of features.

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

# Levels: low | medium | high | insane
# Generators are implemented in modules under `comparator/generators/*.sh`.
generate_cpp() {
  local level="${1:-medium}"

  write_cmake_skel
  write_cpp_main_min

  # Always-on baseline
  # Delegate header content to header generator (idempotent if CMake already written)
  generate_cpp_headers "$level"
  add_cpp_noise_unit
  add_template_stress
  add_deadcode_garden
  add_feature_files_bulk
  add_perf_code
  add_test
  add_security_fix
  breaking_api_change
  add_ranges_unit
  add_optional_variant_unit
  add_header_only_lib

  case "$level" in
    low)
      ;;
    medium)
      add_threading_unit
      add_filesystem_unit
      ;;
    high)
      add_threading_unit
      add_filesystem_unit
      # duplicate some generators for volume
      add_cpp_noise_unit
      add_template_stress
      add_perf_code
      add_test
      ;;
    insane)
      add_threading_unit
      add_filesystem_unit
      # spray many units
      for _ in {1..3}; do add_cpp_noise_unit; done
      for _ in {1..2}; do add_template_stress; done
      for _ in {1..2}; do add_deadcode_garden; done
      for _ in {1..3}; do add_perf_code; done
      for _ in {1..3}; do add_test; done
      ;;
    *)
      echo "[nv-generators] Unknown level '$level' (use low|medium|high|insane)" >&2
      return 2
      ;;
  esac
}


