// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <unistd.h>
#include "test_helpers.h"
#include "next_version/git_helpers.h"

using namespace nv;

static bool init_repo_with_changes(std::string &dir, std::string &baseRef) {
    dir = std::string("/tmp/nv_git_stats_") + std::to_string(::getpid());
    std::filesystem::create_directories(dir + "/src");
    std::string cmd;
    cmd = "git -C " + dir + " init"; std::system(cmd.c_str());
    cmd = "git -C " + dir + " config user.name 'Test'"; std::system(cmd.c_str());
    cmd = "git -C " + dir + " config user.email 'test@example.com'"; std::system(cmd.c_str());
    {
        std::ofstream f(dir + "/VERSION"); f << "0.0.0\n";
    }
    {
        std::ofstream f(dir + "/README.md"); f << "docs\n";
    }
    {
        std::ofstream f(dir + "/src/a.cpp"); f << "int a(){return 1;}\n";
    }
    cmd = "git -C " + dir + " add ."; std::system(cmd.c_str());
    cmd = "git -C " + dir + " commit -m 'init' -q"; std::system(cmd.c_str());
    cmd = "git -C " + dir + " tag v0.0.0"; std::system(cmd.c_str());
    baseRef = "v0.0.0";
    // add a test file and change doc and source
    {
        std::ofstream f(dir + "/test/test_basic.cpp"); f << "int main(){return 0;}\n";
    }
    {
        std::ofstream f(dir + "/README.md", std::ios::app); f << "more docs\n";
    }
    {
        std::ofstream f(dir + "/src/a.cpp", std::ios::app); f << "int b(){return 2;}\n";
    }
    cmd = "git -C " + dir + " add ."; std::system(cmd.c_str());
    cmd = "git -C " + dir + " commit -m 'add files' -q"; std::system(cmd.c_str());
    return true;
}

static bool test_file_change_stats_counts() {
    std::string repo, base;
    init_repo_with_changes(repo, base);
    FileChangeStats s = computeFileChangeStats(repo, base, "HEAD", "", false);
    TEST_ASSERT(s.newSourceFiles >= 0 && s.newTestFiles >= 0 && s.newDocFiles >= 0, "non-negative counts");
    TEST_ASSERT((s.insertions + s.deletions) > 0, "non-zero diff size");
    TEST_PASS("computeFileChangeStats basic counts");
    return true;
}

int main() {
    std::cout << "Running git stats tests..." << std::endl;
    bool ok = true;
    ok &= test_file_change_stats_counts();
    return ok ? 0 : 1;
}


