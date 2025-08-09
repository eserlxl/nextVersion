#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: write_cmake_header_only_skel

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../nv-common.sh
source "${SCRIPT_DIR}/../nv-common.sh"

write_cmake_header_only_skel() {
  cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(nvproj_headers LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

file(GLOB_RECURSE NV_HEADERS CONFIGURE_DEPENDS "include/*.h" "include/*.hpp")

add_library(nvheaders INTERFACE)
target_include_directories(nvheaders INTERFACE include)
EOF
}


