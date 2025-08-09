#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: add_ranges_unit

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_ranges_unit() {
  mkdir -p src
  local f="src/ranges_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <vector>
#include <ranges>
#include <numeric>
#include <cstdint>
int ranges_probe(){
  std::vector<int> v(500); std::iota(v.begin(), v.end(), 1);
  auto rng = v | std::views::filter([](int x){ return (x&1)==0; })
               | std::views::transform([](int x){ return x*x - (x>>1); });
  long long s = 0;
  for (int x : rng) s += x;
  return static_cast<int>(s & 0x7FFFFFFF);
}
EOF
}


