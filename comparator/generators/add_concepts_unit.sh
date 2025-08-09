#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: add_concepts_unit

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_concepts_unit() {
  mkdir -p src include
  local h="include/concepts_$(rand_word).h"
  local f="src/concepts_$(rand_word).cpp"
  cat > "$h" <<'EOF'
#pragma once
#include <type_traits>
template<class T>
concept TinyTrivial = std::is_trivial_v<T> && (sizeof(T) <= 8);

template<TinyTrivial T>
constexpr T add3(T x){ return static_cast<T>(x + T{3}); }
EOF
  cat > "$f" <<EOF
#include "$(basename "$h")"
#include <cstdint>
int concepts_probe(){
  return static_cast<int>(add3<std::uint8_t>(5));
}
EOF
}


