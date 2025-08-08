// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#pragma once

#include <string>

namespace nv {

struct GitOpsOptions {
  bool doCommit {false};
  bool doTag {false};
  bool doPush {false};
  bool pushTags {false};
  bool allowDirty {false};
  bool signCommit {false};
  bool annotatedTag {true};
  bool signedTag {false};
  bool noVerify {false};
  std::string remote {"origin"};
  std::string tagPrefix {"v"};
  std::string commitMessage; // optional; if empty, auto message is used
};

// Create a bump commit and optionally tag and push, using git CLI under the hood.
// Returns 0 on success, non-zero on failure. Errors are printed to stderr.
int performGitOperations(const GitOpsOptions &opts,
                        const std::string &repoRoot,
                        const std::string &newVersion,
                        const std::string &currentVersion);

}


