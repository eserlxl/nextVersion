// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <string>
#include "../test_helpers.h"
#include "next_version/analyzers.h"
#include "next_version/types.h"

using namespace nv;

static bool test_base_delta_defaults() {
    ConfigValues cfg; // defaults: base patch 1, minor 5, major 10; divisors 250/500/1000
    TEST_ASSERT(baseDeltaFor("patch", 0, cfg) >= 1, "patch base delta >= 1");
    TEST_ASSERT(baseDeltaFor("minor", 0, cfg) >= 1, "minor base delta >= 1");
    TEST_ASSERT(baseDeltaFor("major", 0, cfg) >= 1, "major base delta >= 1");
    TEST_PASS("baseDeltaFor basic checks");
    return true;
}

static bool test_multiplier_and_bump_version() {
    ConfigValues cfg;
    // Keep LOC small to avoid hitting cap for deterministic expectation
    int bonus = 4; // minor threshold
    int loc = 50;
    const std::string cur = "9.3.0";
    const std::string next = bumpVersion(cur, "patch", loc, bonus, cfg);
    TEST_ASSERT(!next.empty(), "bumpVersion should return a version");
    TEST_ASSERT(next.find('.') != std::string::npos, "version has dots");
    TEST_PASS("bumpVersion returns plausible version");
    return true;
}

int main() {
    std::cout << "Running version math tests..." << std::endl;
    bool ok = true;
    ok &= test_base_delta_defaults();
    ok &= test_multiplier_and_bump_version();
    return ok ? 0 : 1;
}


