#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_threading_unit

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_threading_unit() {
  mkdir -p src
  local f="src/thread_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <thread>
#include <atomic>
#include <vector>
#include <cstdint>
static std::atomic<int> acc{0};
int thread_probe(){
  std::vector<std::thread> ts;
  for(int i=0;i<4;i++){
    ts.emplace_back([]{ for(int k=0;k<1000;k++) acc.fetch_add(1, std::memory_order_relaxed); });
  }
  for(auto& t:ts) t.join();
  return acc.load(std::memory_order_relaxed);
}
EOF
}


