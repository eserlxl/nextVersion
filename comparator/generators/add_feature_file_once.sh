#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_feature_file_once

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_feature_file_once() {
  mkdir -p src include
  local fname="feature_$(rand_word)"
  local fns; fns="$(c_range 2 6)"
  {
    echo "#pragma once"
    local j; for ((j=0;j<fns;j++)); do
      printf "int %s_fn%d();\n" "${fname}" "$j"
    done
  } > "include/${fname}.h"
  {
    echo "#include <cstdlib>"
    echo "#include \"${fname}.h\""
    local j; for ((j=0;j<fns;j++)); do
      printf "int %s_fn%d(){ return %d + std::rand()%7; }\n" "${fname}" "$j" "$(rand_int 0 199)"
    done
  } > "src/${fname}.cpp"
}


