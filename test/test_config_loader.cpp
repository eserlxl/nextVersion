// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <fstream>
#include <filesystem>
#include "test_helpers.h"
#include "next_version/analyzers.h"
#include "next_version/types.h"

using namespace nv;

static bool test_load_config_defaults_when_missing() {
    // Use a temp dir without dev-config/versioning.yml
    const char *dir = "/tmp/nv_cfg_test_missing";
    std::filesystem::create_directories(dir);
    ConfigValues cfg = loadConfigValues(dir);
    TEST_ASSERT(cfg.majorBonusThreshold == 8, "default majorBonusThreshold is 8");
    TEST_ASSERT(cfg.minorBonusThreshold == 4, "default minorBonusThreshold is 4");
    TEST_PASS("loadConfigValues defaults when missing");
    return true;
}

static bool test_load_config_nested_sections() {
    const char *base = "/tmp/nv_cfg_test_nested";
    std::filesystem::create_directories(std::string(base) + "/dev-config");
    {
        std::ofstream f(std::string(base) + "/dev-config/versioning.yml");
        f << "thresholds:\n";
        f << "  major_bonus: 10\n";
        f << "  minor_bonus: 5\n";
        f << "bonuses:\n";
        f << "  breaking_changes:\n";
        f << "    cli_breaking: 7\n";
        f << "  features:\n";
        f << "    new_source_file: 2\n";
        f << "loc_divisors:\n";
        f << "  minor: 600\n";
    }
    ConfigValues cfg = loadConfigValues(base);
    TEST_ASSERT(cfg.majorBonusThreshold == 10, "read nested major_bonus");
    TEST_ASSERT(cfg.minorBonusThreshold == 5, "read nested minor_bonus");
    TEST_ASSERT(cfg.bonusBreakingCli == 7, "read nested cli_breaking");
    TEST_ASSERT(cfg.locDivisorMinor == 600, "read loc_divisors.minor");
    TEST_PASS("loadConfigValues nested sections");
    return true;
}

int main() {
    std::cout << "Running config loader tests..." << std::endl;
    bool ok = true;
    ok &= test_load_config_defaults_when_missing();
    ok &= test_load_config_nested_sections();
    return ok ? 0 : 1;
}


