#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: add_macro_maze

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_macro_maze() {
  mkdir -p include
  local h="include/maze_$(rand_word).h"
  cat > "$h" <<'EOF'
#pragma once
#define NV_CAT_(a,b) a##b
#define NV_CAT(a,b)  NV_CAT_(a,b)
#define NV_STR_(x)   #x
#define NV_STR(x)    NV_STR_(x)
#define NV_REPEAT_1(X) X
#define NV_REPEAT_2(X) NV_REPEAT_1(X) X
#define NV_REPEAT_4(X) NV_REPEAT_2(X) NV_REPEAT_2(X)
#define NV_REPEAT_8(X) NV_REPEAT_4(X) NV_REPEAT_4(X)
#define NV_UNLIKELY(x) __builtin_expect(!!(x),0)
#ifndef NV_NOISE_SCALE
#define NV_NOISE_SCALE(x) ((x)*1337 + ((x)>>5) - ((x)<<2) + 42)
#endif
#define NV_IF(c,a,b) ((c)?(a):(b))
EOF
}


