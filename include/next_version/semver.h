// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#pragma once

#include <string>

namespace nv {

// Returns true if v matches strict X.Y.Z
bool isSemverCore(const std::string &v);

// Returns true if v matches X.Y.Z or X.Y.Z-prerelease (build metadata optional)
bool isSemverWithPrerelease(const std::string &v);

// Compare two versions with SemVer precedence including prerelease (build ignored):
// returns -1 if a<b, 0 if equal, 1 if a>b
int semverCompare(const std::string &a, const std::string &b);

// Convenience helpers
bool isPrerelease(const std::string &v);

}


