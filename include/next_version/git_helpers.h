// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#pragma once

#include "next_version/types.h"
#include <string>
#include <vector>

namespace nv {

std::string shellQuote(const std::string &s);
std::string buildCommand(const std::vector<std::string> &args);
int runProcessCapture(const std::string &command, std::string &stdoutData);

int runGitCapture(const std::vector<std::string> &args, const std::string &repoRoot, std::string &out);
bool gitHasCommits(const std::string &repoRoot);
std::string gitDescribeLastTag(const std::string &match, const std::string &repoRoot);
std::string gitRevListBeforeDate(const std::string &date, const std::string &repoRoot);
std::string gitFirstCommit(const std::string &repoRoot);
std::string gitParentHead(const std::string &repoRoot);

FileChangeStats computeFileChangeStats(const std::string &repoRoot,
                                      const std::string &baseRef,
                                      const std::string &targetRef,
                                      const std::string &onlyPathsCsv,
                                      bool ignoreWhitespace);

}


