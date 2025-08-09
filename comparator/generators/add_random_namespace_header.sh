#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_random_namespace_header

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_random_namespace_header() {
  mkdir -p include
  local h="include/ns_$(rand_word).h"
  local n; n="$(c_range 4 12)"
  {
    echo '#pragma once'
    for ((i=0;i<n;i++)); do
      local ns; ns="$(rand_word)"
      echo "namespace $ns { inline int v$i(){ int s=0; for(int k=0;k<${RANDOM}%60;k++) s+=k*k - (k&1); return s; } }"
    done
  } > "$h"
}


