// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <filesystem>
#include <unistd.h>
#include <cstdlib>
#include <fstream>
#include "test_helpers.h"
#include "next_version/git_helpers.h"
#include "next_version/analyzers.h"

using namespace nv;

// This test mirrors bash test_workflows' CLI change tests by creating a tiny repo
// and removing a short option between two commits, then validating breaking flag.

static bool init_repo(const std::string &dir) {
    std::filesystem::create_directories(dir + "/src");
    // init repo
    std::string cmd;
    cmd = "git -C " + dir + " init"; std::system(cmd.c_str());
    cmd = "git -C " + dir + " config user.name 'Test'"; std::system(cmd.c_str());
    cmd = "git -C " + dir + " config user.email 'test@example.com'"; std::system(cmd.c_str());
    // version file
    {
        std::ofstream f(dir + "/VERSION"); f << "0.0.0\n";
    }
    // initial file with -h and -v and -d
    {
        std::ofstream f(dir + "/src/main.cpp");
        f << "#include <getopt.h>\n";
        f << "int main(int argc, char** argv) {\n";
        f << "  int o;\n";
        f << "  while ((o = getopt(argc, argv, \"hvd\")) != -1) {\n";
        f << "    switch (o) {\n";
        f << "      case 'h': break;\n";
        f << "      case 'v': break;\n";
        f << "      case 'd': break;\n";
        f << "    }\n";
        f << "  }\n";
        f << "  return 0;\n";
        f << "}\n";
    }
    cmd = "git -C " + dir + " add ."; std::system(cmd.c_str());
    cmd = "git -C " + dir + " commit -m 'init' -q"; std::system(cmd.c_str());
    // tag base
    cmd = "git -C " + dir + " tag v0.0.0"; std::system(cmd.c_str());
    // remove -d option
    {
        std::ofstream f(dir + "/src/main.cpp");
        f << "#include <getopt.h>\n";
        f << "int main(int argc, char** argv) {\n";
        f << "  int o;\n";
        f << "  while ((o = getopt(argc, argv, \"hv\")) != -1) {\n";
        f << "    switch (o) {\n";
        f << "      case 'h': break;\n";
        f << "      case 'v': break;\n";
        f << "    }\n";
        f << "  }\n";
        f << "  return 0;\n";
        f << "}\n";
    }
    cmd = "git -C " + dir + " add ."; std::system(cmd.c_str());
    cmd = "git -C " + dir + " commit -m 'remove d' -q"; std::system(cmd.c_str());
    return true;
}

static bool test_cli_breaking_detection() {
    const std::string repo = std::string("/tmp/nv_cli_break_") + std::to_string(::getpid());
    init_repo(repo);
    CliResults r = analyzeCliOptions(repo, "v0.0.0", "HEAD", "", false);
    TEST_ASSERT(r.cliChanges, "CLI changes should be true");
    TEST_ASSERT(r.breakingCliChanges, "Removing option should be breaking");
    TEST_PASS("CLI analyzer breaking removal detection");
    return true;
}

int main() {
    std::cout << "Running CLI analyzer tests..." << std::endl;
    bool ok = true;
    ok &= test_cli_breaking_detection();
    return ok ? 0 : 1;
}


