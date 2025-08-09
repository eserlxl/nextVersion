#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: add_template_stress

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_template_stress() {
  mkdir -p src include
  local h="include/meta_$(rand_word).h"
  local f="src/meta_$(rand_word).cpp"
  cat > "$h" <<'EOF'
#pragma once
#include <array>
#include <utility>
#include <cstddef>
template<std::size_t N>
struct Fib { static constexpr unsigned long long value = Fib<N-1>::value + Fib<N-2>::value; };
template<> struct Fib<1>{ static constexpr unsigned long long value = 1; };
template<> struct Fib<0>{ static constexpr unsigned long long value = 0; };

template<std::size_t N>
constexpr auto make_seq(){
  std::array<unsigned long long,N> a{};
  for(std::size_t i=0;i<N;i++) a[i] = Fib<(i%24)>::value;
  return a;
}
EOF
  cat > "$f" <<'EOF'
#include <numeric>
#include <vector>
#include <cstdint>
#include "meta_placeholder.h"
static int meta_probe(){
  constexpr auto seq = make_seq<192>();
  unsigned long long s=0;
  for(auto x:seq) s += (x*x) - (x>>1);
  return static_cast<int>(s & 0x7FFFFFFF);
}
EOF
  sed -i "s/meta_placeholder.h/$(basename "$h")/" "$f"
}


