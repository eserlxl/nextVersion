// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#pragma once

#include "next_version/types.h"
#include <string>

namespace nv {

int calculateTotalBonus(const Kv &fileKv, const Kv &CLI, const Kv &SEC, const Kv &KW, const ConfigValues &cfg);

}
