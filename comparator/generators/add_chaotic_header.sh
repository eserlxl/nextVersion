#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_chaotic_header

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_chaotic_header() {
  mkdir -p include
  local h="include/chaos_$(rand_word).h"
  cat > "$h" <<'EOF'
#pragma once
#include <type_traits>
#include <utility>
namespace chaos {
template<class T, class=void> struct rank : std::integral_constant<int,0>{};
template<class T> struct rank<T, std::void_t<decltype(sizeof(T))>> : std::integral_constant<int,1>{};
template<class T> constexpr int rank_v = rank<T>::value;
template<class F, class... A>
constexpr auto call(F&& f, A&&... a) noexcept(noexcept(f(std::forward<A>(a)...))){
    if constexpr(noexcept(f(std::forward<A>(a)...))) return f(std::forward<A>(a)...);
    else return f(std::forward<A>(a)...);
}

template<class T>
concept SmallTrivial = std::is_trivial_v<T> && sizeof(T) <= 8;
}
EOF
}


