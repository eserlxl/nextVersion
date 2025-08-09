#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_filesystem_unit

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_filesystem_unit() {
  mkdir -p src
  local f="src/fs_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <filesystem>
#include <string>
#include <cstdint>
int fs_probe(){
  namespace fs = std::filesystem;
  auto p = fs::path("doc") / "README.md";
  // Query only; do not create/modify FS.
  auto ok = fs::exists(p);
  return ok ? 1 : 0;
}
EOF
}


