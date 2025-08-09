#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: breaking_api_change

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

breaking_api_change() {
  mkdir -p include src
  echo "#pragma once" > include/api.h
  local overloads; overloads="$(c_range 1 5)"
  {
    echo "#ifdef NV_API_V1_DEPRECATED"
    echo "// v1 deprecated"
    echo "#endif"
    local i; for ((i=0;i<overloads;i++)); do echo "int api_v2_$i();"; done
  } >> include/api.h
  { local i; for ((i=0;i<overloads;i++)); do echo "int api_v2_$i(){ return $((i+2)); }"; done; } > src/api.cpp
}


