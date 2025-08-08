// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of next-version and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.
#include "next_version/output_formatter.h"
#include "next_version/util.h"
#include "next_version/analyzers.h"
#include <iostream>
#include <cctype>

namespace nv {

void formatOutput(const Options &opts, const std::string &suggestion, const std::string &currentVersion, 
                  const std::string &nextVersion, int totalBonus, const Kv &CLI, 
                  const std::string &baseRef, const std::string &targetRef, 
                  const ConfigValues &cfg, int loc) {
  auto flagTrue = [](const Kv &m, const char *k) {
    auto it = m.find(k); return it != m.end() && it->second == "true";
  };

  if (opts.suggestOnly) {
    std::cout << suggestion << "\n";
  } else if (opts.json) {
    // Precompute three deltas (native)
    const int pd = baseDeltaFor("patch", loc, cfg) + computeTotalBonusWithMultiplier(totalBonus, loc, "patch", cfg);
    const int md = baseDeltaFor("minor", loc, cfg) + computeTotalBonusWithMultiplier(totalBonus, loc, "minor", cfg);
    const int jd = baseDeltaFor("major", loc, cfg) + computeTotalBonusWithMultiplier(totalBonus, loc, "major", cfg);

    std::cout << "{\n";
    std::cout << "  \"suggestion\": \"" << jsonEscape(suggestion) << "\",\n";
    std::cout << "  \"current_version\": \"" << jsonEscape(currentVersion) << "\",\n";
    if (!nextVersion.empty()) {
      std::cout << "  \"next_version\": \"" << jsonEscape(nextVersion) << "\",\n";
    }
    std::cout << "  \"total_bonus\": " << totalBonus << ",\n";
    std::cout << "  \"manual_cli_changes\": " << (flagTrue(CLI, "MANUAL_CLI_CHANGES") ? "true" : "false") << ",\n";
    std::cout << "  \"manual_added_long_count\": " << intOrDefault(CLI.count("MANUAL_ADDED_LONG_COUNT") ? CLI.at("MANUAL_ADDED_LONG_COUNT") : "", 0) << ",\n";
    std::cout << "  \"manual_removed_long_count\": " << intOrDefault(CLI.count("MANUAL_REMOVED_LONG_COUNT") ? CLI.at("MANUAL_REMOVED_LONG_COUNT") : "", 0) << ",\n";
    std::cout << "  \"base_ref\": \"" << jsonEscape(baseRef) << "\",\n";
    std::cout << "  \"target_ref\": \"" << jsonEscape(targetRef) << "\",\n";
    std::cout << "  \"loc_delta\": {\n";
    std::cout << "    \"patch_delta\": " << pd << ",\n";
    std::cout << "    \"minor_delta\": " << md << ",\n";
    std::cout << "    \"major_delta\": " << jd << "\n";
    std::cout << "  }\n";
    std::cout << "}\n";
  } else if (opts.machine) {
    std::cout << "SUGGESTION=" << suggestion << "\n";
  } else {
    std::cout << "=== Semantic Version Analysis v2 ===\n";
    std::cout << "Analyzing changes: " << baseRef << " -> " << targetRef << "\n";
    std::cout << "\nCurrent version: " << currentVersion << "\n";
    std::cout << "Total bonus points: " << totalBonus << "\n";
    std::cout << "\nSuggested bump: ";
    for (char c : suggestion) std::cout << static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    std::cout << "\n";
    if (!nextVersion.empty()) std::cout << "Next version: " << nextVersion << "\n";
    std::cout << "\nSUGGESTION=" << suggestion << "\n";
  }
}

}
