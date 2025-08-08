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

RefResolution resolveRefsNative(const Options &opts);
ConfigValues loadConfigValues(const std::string &projectRoot);
KeywordResults analyzeKeywords(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace);
CliResults analyzeCliOptions(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace);
SecurityResults analyzeSecurity(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace, bool addedOnly=false);

int baseDeltaFor(const std::string &bumpType, int loc, const ConfigValues &cfg);
int computeTotalBonusWithMultiplier(int baseBonus, int loc, const std::string &bumpType, const ConfigValues &cfg);
std::string bumpVersion(const std::string &current, const std::string &bumpType, int loc, int bonus, const ConfigValues &cfg, int mainMod=1000);

}


