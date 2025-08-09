#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_security_fix

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_security_fix() {
  mkdir -p src
  local lines; lines="$(c_lines 25)"
  {
    echo '#include <cstring>'
    echo '#include <cstddef>'
    echo 'void copy_safe(char* d,const char* s,std::size_t n){ if(n){ std::strncpy(d,s,n-1); d[n-1]=0; } }'
    local i=0; while (( i < lines )); do
      echo "void shim_$i(char* d,const char* s,std::size_t n){ copy_safe(d,s,n); }"; ((++i))
    done
  } > "src/sec_$(rand_word).cpp"
}


