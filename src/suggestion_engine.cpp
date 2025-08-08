// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "next_version/suggestion_engine.h"

namespace nv {

std::string determineSuggestion(int totalBonus, const ConfigValues &cfg) {
  std::string suggestion = "none";
  if (totalBonus >= cfg.majorBonusThreshold) suggestion = "major";
  else if (totalBonus >= cfg.minorBonusThreshold) suggestion = "minor";
  else if (totalBonus > cfg.patchBonusThreshold) suggestion = "patch";
  return suggestion;
}

int determineExitCode(const Options &opts, const std::string &suggestion) {
  if (opts.suggestOnly && !opts.strictStatus) return 0;
  if (opts.json) return 0;
  if (suggestion == "major") return 10;
  if (suggestion == "minor") return 11;
  if (suggestion == "patch") return 12;
  if (suggestion == "none") return 20;
  return 0;
}

}
