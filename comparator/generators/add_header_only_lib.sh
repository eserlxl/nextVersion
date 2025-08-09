#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: add_header_only_lib

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_header_only_lib() {
  mkdir -p include src
  local h="include/hol_${RANDOM}.hpp"
  local f="src/hol_${RANDOM}.cpp"
  cat > "$h" <<'EOF'
#pragma once
#include <cstdint>
namespace hol {
template<class T> constexpr T mix(T a, T b){ return (a^b) + (a>>1); }
inline int call(int x){ return mix(x, 17); }
}
EOF
  cat > "$f" <<EOF
#include "$(basename "$h")"
int hol_probe(){ return hol::call(5); }
EOF
}


