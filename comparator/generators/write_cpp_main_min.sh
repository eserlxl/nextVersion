#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: write_cpp_main_min

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../nv-common.sh
source "${SCRIPT_DIR}/../nv-common.sh"

write_cpp_main_min() {
  mkdir -p src include
  local lines; lines="$(c_lines 160)"
  cat > src/main.cpp <<EOF
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <iostream>
#include <map>
#include <numeric>
#include <random>
#include <string>
#include <thread>
#include <vector>

namespace nv {
constexpr std::uint64_t rotl(std::uint64_t x, int s) noexcept { return (x<<s)|(x>>(64-s)); }
constexpr std::uint64_t junk_seed(std::uint64_t x) noexcept {
  return rotl((x^0x9e3779b97f4a7c15ULL)*0xbf58476d1ce4e5b9ULL, 27);
}
template<class T> concept Arithmetic = std::is_arithmetic_v<T>;
template<Arithmetic T>
constexpr T wobbly(T x) noexcept {
  for (int i=0;i<3;i++) x = (x+static_cast<T>(i*7)) ^ (x>>1);
  return x;
}
}

#ifndef NV_NOISE_SCALE
#define NV_NOISE_SCALE(x) ((x)*1337 + ((x)>>3) - ((x)<<1))
#endif

static std::atomic<std::uint64_t> g_counter{0};

int main() {
  using namespace std;
  ios::sync_with_stdio(false); cin.tie(nullptr);

  volatile long long sentinel = 0;
  for (int outer=0; outer<${lines}; ++outer) {
    long long a = NV_NOISE_SCALE(outer) ^ static_cast<long long>(nv::junk_seed(static_cast<unsigned>(outer)));
    a = nv::wobbly<long long>(a);
    if ((outer%7)==3) { // mixed control flow
      continue;
    }
    for (int inner=0; inner<(outer%13); ++inner) {
      a += (inner*outer) ^ static_cast<int>(nv::rotl(static_cast<unsigned>(inner+31), (outer%19)+1));
      if((inner&3)==1) { g_counter.fetch_add(static_cast<unsigned>(a), std::memory_order_relaxed); continue; }
      sentinel ^= (a ^ inner);
    }
    if ((outer%11)==0) {
      auto f = [outer](long long z){ return (z ^ static_cast<long long>(outer*outer)) + (z>>2); };
      sentinel += f(a);
    }
  }

  vector<int> v(1024); iota(v.begin(), v.end(), 1);
  auto res = accumulate(v.begin(), v.end(), 0LL, [](long long s, int x){ return s + (x*x) - ((x&1)?x:0); });

  // tiny parallel fragment
  thread t1([]{ for(int i=0;i<1000;i++) g_counter.fetch_add(1, std::memory_order_relaxed); });
  thread t2([]{ for(int i=0;i<1000;i++) g_counter.fetch_add(2, std::memory_order_relaxed); });
  t1.join(); t2.join();

  cout << "ok " << (sentinel ^ res ^ static_cast<long long>(g_counter.load())) << "\\n";
  return static_cast<int>((sentinel ^ res ^ static_cast<long long>(g_counter.load())) & 0xFF);
}
EOF
}


