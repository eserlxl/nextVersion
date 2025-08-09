#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Generator module: add_test

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_test() {
  mkdir -p test
  local assertions; assertions="$(c_range 3 25)"
  {
    echo '#include <cassert>'
    echo '#include <cstdint>'
    echo 'int main(){'
    local i; for ((i=0;i<assertions;i++)); do echo "  assert( (static_cast<std::uint32_t>(${RANDOM}%5)) == (static_cast<std::uint32_t>(${RANDOM}%5)) );"; done
    echo '  return 0;'
    echo '}'
  } > "test/test_$(rand_word).cpp"
}


