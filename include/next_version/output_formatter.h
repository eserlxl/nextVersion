// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of next-version and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.
#pragma once

#include "next_version/types.h"
#include <string>

namespace nv {

void formatOutput(const Options &opts, const std::string &suggestion, const std::string &currentVersion, 
                  const std::string &nextVersion, int totalBonus, const Kv &CLI, 
                  const std::string &baseRef, const std::string &targetRef, 
                  const ConfigValues &cfg, int loc);

}
