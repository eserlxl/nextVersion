#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: write_cmake_skel

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../nv-common.sh
source "${SCRIPT_DIR}/../nv-common.sh"

write_cmake_skel() {
  cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(nvproj LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(NV_WARNINGS_AS_ERRORS "Treat warnings as errors" OFF)
option(NV_LTO "Enable link-time optimization" OFF)

if(MSVC)
  add_compile_options(/W4 /permissive-)
else()
  add_compile_options(-Wall -Wextra -Wpedantic -Wconversion -Wshadow -Wduplicated-cond -Wduplicated-branches -Wnull-dereference -Wdouble-promotion)
  if(NV_WARNINGS_AS_ERRORS)
    add_compile_options(-Werror)
  endif()
  if(NV_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_ok OUTPUT ipo_msg)
    if(ipo_ok)
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
    endif()
  endif()
endif()

file(GLOB_RECURSE NV_SOURCES CONFIGURE_DEPENDS "src/*.cpp")
file(GLOB_RECURSE NV_TESTS   CONFIGURE_DEPENDS "test/*.cpp")
file(GLOB_RECURSE NV_HEADERS CONFIGURE_DEPENDS "include/*.h" "include/*.hpp")

add_library(nvlib STATIC ${NV_SOURCES} ${NV_HEADERS})
target_include_directories(nvlib PUBLIC include)
if(NOT MSVC)
  target_compile_definitions(nvlib PRIVATE NV_BUILD_UNIX=1)
endif()

add_executable(nvmain src/main.cpp)
target_link_libraries(nvmain PRIVATE nvlib)

enable_testing()
foreach(t ${NV_TESTS})
  get_filename_component(_n "${t}" NAME_WE)
  add_executable(${_n} "${t}")
  target_link_libraries(${_n} PRIVATE nvlib)
  add_test(NAME ${_n} COMMAND ${_n})
endforeach()
EOF
}


