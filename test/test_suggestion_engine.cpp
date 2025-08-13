// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include "test_helpers.h"
#include "next_version/suggestion_engine.h"
#include "next_version/types.h"

using namespace nv;

static bool test_determine_suggestion_thresholds() {
    ConfigValues cfg; // defaults: major 8, minor 4, patch 0
    TEST_ASSERT(determineSuggestion(0, cfg) == "none", "bonus 0 -> none");
    TEST_ASSERT(determineSuggestion(1, cfg) == "patch", "bonus 1 -> patch");
    TEST_ASSERT(determineSuggestion(4, cfg) == "minor", "bonus 4 -> minor");
    TEST_ASSERT(determineSuggestion(7, cfg) == "minor", "bonus 7 -> minor");
    TEST_ASSERT(determineSuggestion(8, cfg) == "major", "bonus 8 -> major");
    TEST_PASS("determineSuggestion thresholds");
    return true;
}

static bool test_exit_codes() {
    Options o; // defaults
    TEST_ASSERT(determineExitCode(o, "major") == 10, "major -> 10");
    TEST_ASSERT(determineExitCode(o, "minor") == 11, "minor -> 11");
    TEST_ASSERT(determineExitCode(o, "patch") == 12, "patch -> 12");
    TEST_ASSERT(determineExitCode(o, "none") == 20, "none -> 20");

    o.suggestOnly = true; o.strictStatus = false; o.json = false;
    TEST_ASSERT(determineExitCode(o, "major") == 0, "suggest-only no-strict -> 0");
    o.suggestOnly = false; o.json = true;
    TEST_ASSERT(determineExitCode(o, "minor") == 0, "json -> 0");
    TEST_PASS("determineExitCode policy");
    return true;
}

int main() {
    std::cout << "Running suggestion engine tests..." << std::endl;
    bool ok = true;
    ok &= test_determine_suggestion_thresholds();
    ok &= test_exit_codes();
    return ok ? 0 : 1;
}


