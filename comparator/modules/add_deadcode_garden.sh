#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_deadcode_garden

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_deadcode_garden() {
  mkdir -p src
  local f="src/dead_$(rand_word).cpp"
  local blocks; blocks="$(c_range 20 80)"
  {
    echo '#include <cstdint>'
    echo '#include <utility>'
    echo "int dead_${RANDOM}(){"
    echo "  volatile std::uint64_t z=0;"
    for ((i=0;i<blocks;i++)); do
      echo "  if (__builtin_expect(((${RANDOM}%1024)==-1),0)) { z+=${RANDOM}ull; } else { z^=${RANDOM}ull; }"
    done
    echo "  return static_cast<int>(z & 0x7FFFFFFF);"
    echo "}"
  } > "$f"
}


