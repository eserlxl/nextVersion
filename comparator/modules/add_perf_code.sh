#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_perf_code

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_perf_code() {
  mkdir -p src
  local N; N="$(c_lines 800)"
  cat > "src/perf_$(rand_word).cpp" <<EOF
#include <vector>
#include <numeric>
int perf_fn_${RANDOM}(){
  std::vector<int> v(${N},1);
  return std::accumulate(v.begin(),v.end(),0);
}
EOF
}


