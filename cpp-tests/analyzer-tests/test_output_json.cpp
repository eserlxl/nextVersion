// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <sstream>
#include <string>
#include "../test_helpers.h"
#include "next_version/output_formatter.h"
#include "next_version/types.h"
#include "next_version/analyzers.h"

using namespace nv;

static bool test_json_contains_required_fields() {
    Options o; o.json = true;
    Kv cli; cli["MANUAL_CLI_CHANGES"] = "false";
    cli["MANUAL_ADDED_LONG_COUNT"] = "0";
    cli["MANUAL_REMOVED_LONG_COUNT"] = "0";
    ConfigValues cfg;
    std::streambuf* old = std::cout.rdbuf();
    std::ostringstream cap;
    std::cout.rdbuf(cap.rdbuf());
    formatOutput(o, "patch", "1.2.3", "1.2.4", 3, cli, "v1.2.3", "HEAD", cfg, 10);
    std::cout.rdbuf(old);
    const std::string out = cap.str();
    TEST_ASSERT(out.find("\"suggestion\"") != std::string::npos, "has suggestion");
    TEST_ASSERT(out.find("\"current_version\"") != std::string::npos, "has current_version");
    TEST_ASSERT(out.find("\"total_bonus\"") != std::string::npos, "has total_bonus");
    TEST_ASSERT(out.find("\"loc_delta\"") != std::string::npos, "has loc_delta");
    TEST_PASS("formatOutput JSON fields");
    return true;
}

int main() {
    std::cout << "Running JSON output tests..." << std::endl;
    bool ok = true;
    ok &= test_json_contains_required_fields();
    return ok ? 0 : 1;
}


