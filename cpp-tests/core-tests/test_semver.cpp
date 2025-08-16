// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <string>
#include "../test_helpers.h"
#include "next_version/semver.h"

using namespace nv;

static bool test_is_semver_core() {
    TEST_ASSERT(isSemverCore("0.0.1"), "0.0.1 should be valid semver core");
    TEST_ASSERT(isSemverCore("1.2.3"), "1.2.3 should be valid semver core");
    TEST_ASSERT(!isSemverCore("1.2"), "1.2 should be invalid semver core");
    TEST_ASSERT(!isSemverCore("01.2.3"), "leading zero is not allowed");
    TEST_PASS("isSemverCore checks");
    return true;
}

static bool test_is_semver_with_prerelease() {
    TEST_ASSERT(isSemverWithPrerelease("1.2.3-alpha"), "prerelease should be allowed");
    TEST_ASSERT(isSemverWithPrerelease("1.2.3-alpha+build.7"), "prerelease+build should be allowed");
    TEST_ASSERT(!isSemverWithPrerelease("1.2"), "1.2 is not valid semver with prerelease");
    TEST_PASS("isSemverWithPrerelease checks");
    return true;
}

static bool test_semver_compare() {
    TEST_ASSERT(semverCompare("1.0.0", "1.0.0") == 0, "1.0.0 == 1.0.0");
    TEST_ASSERT(semverCompare("1.0.0", "1.0.1") < 0, "1.0.0 < 1.0.1");
    TEST_ASSERT(semverCompare("1.2.0", "1.1.9") > 0, "1.2.0 > 1.1.9");
    TEST_ASSERT(semverCompare("1.0.0-alpha", "1.0.0") < 0, "pre-release < release");
    TEST_ASSERT(semverCompare("1.0.0-alpha.1", "1.0.0-alpha.2") < 0, "alpha.1 < alpha.2");
    TEST_ASSERT(semverCompare("1.0.0-alpha", "1.0.0-beta") < 0, "alpha < beta");
    TEST_PASS("semverCompare checks");
    return true;
}

int main() {
    std::cout << "Running semver unit tests..." << std::endl;
    bool ok = true;
    ok &= test_is_semver_core();
    ok &= test_is_semver_with_prerelease();
    ok &= test_semver_compare();
    if (ok) {
        std::cout << "All semver tests passed!" << std::endl;
        return 0;
    }
    std::cout << "Some semver tests failed!" << std::endl;
    return 1;
}


