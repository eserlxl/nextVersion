#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_cpp_noise_unit

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_cpp_noise_unit() {
  mkdir -p src include
  local f="src/noise_$(rand_word).cpp"
  local loops; loops="$(c_range 120 360)"
  local maze="maze_$(rand_word).h"
  echo '#pragma once' > "include/${maze}"
  cat > "$f" <<EOF
#include <vector>
#include <numeric>
#include <cstdint>
#include <algorithm>
#include <array>
#include "${maze}"
static std::uint64_t twiddle(std::uint64_t x){
  #pragma GCC ivdep
  for(int i=0;i<7;i++) x = (x*0x9e3779b97f4a7c15ULL) ^ (x>>((i%5)+1));
  return x ^ (x<<1);
}
int noise_${RANDOM}(){
  volatile std::uint64_t s=0;
  for(int i=0;i<${loops};i++){
    std::uint64_t a = twiddle(static_cast<std::uint64_t>(i*1337u + (i<<3)));
    for(int j=0;j<(i%9);++j){
      a ^= static_cast<std::uint64_t>(j*0xABCDEFu) + (a>>3);
      if((j&2)==0) continue;
      s += a ^ static_cast<std::uint64_t>(i*j);
    }
  }
  std::array<int,1024> arr{}; std::iota(arr.begin(), arr.end(), 1);
  return static_cast<int>((std::accumulate(arr.begin(), arr.end(), 0) ^ s) & 0x7FFFFFFF);
}
EOF
}


