// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <fstream>
#include <filesystem>
#include <vector>
#include <cstring>
#include "test_helpers.h"
#include "next_version/version_reader.h"
#include "next_version/cli.h"

using namespace nv;

static bool test_version_reader_reads_VERSION_file() {
    const char *dir = "/tmp/nv_ver_reader_test";
    std::filesystem::create_directories(dir);
    {
        std::ofstream f(std::string(dir) + "/VERSION");
        f << "2.3.4\n";
    }
    std::string v = readCurrentVersion(dir);
    TEST_ASSERT(v == "2.3.4", "readCurrentVersion should read version from VERSION file");
    TEST_PASS("readCurrentVersion basic");
    return true;
}

static bool test_cli_parse_core_flags() {
    const char *argvv[] = {"prog", "--since", "v1.0.0", "--target", "HEAD~1", "--machine", "--suggest-only", "--strict-status", "--ignore-whitespace"};
    int argc = (int)(sizeof(argvv)/sizeof(argvv[0]));
    // Need mutable argv for parseArgs signature
    std::vector<char*> av(argc);
    for (int i = 0; i < argc; ++i) av[i] = const_cast<char*>(argvv[i]);
    Options o = parseArgs(argc, av.data());
    TEST_ASSERT(o.sinceTag == "v1.0.0", "--since captured");
    TEST_ASSERT(o.targetRef == "HEAD~1", "--target captured");
    TEST_ASSERT(o.machine, "--machine true");
    TEST_ASSERT(o.suggestOnly, "--suggest-only true");
    TEST_ASSERT(o.strictStatus, "--strict-status true");
    TEST_ASSERT(o.ignoreWhitespace, "--ignore-whitespace true");
    TEST_PASS("parseArgs core flags");
    return true;
}

int main() {
    std::cout << "Running version reader and CLI parse tests..." << std::endl;
    bool ok = true;
    ok &= test_version_reader_reads_VERSION_file();
    ok &= test_cli_parse_core_flags();
    return ok ? 0 : 1;
}


