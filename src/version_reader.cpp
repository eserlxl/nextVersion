// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "next_version/version_reader.h"
#include "next_version/util.h"
#include <algorithm>

namespace nv {

std::string readCurrentVersion(const std::string &repoRoot) {
  std::string currentVersion = "0.0.0";
  if (!repoRoot.empty()) {
    std::string data = readFileIfExistsUnderRoot(repoRoot, "VERSION");
    if (!data.empty()) {
      data = trim(data);
      if (data.find_first_not_of("0123456789.") == std::string::npos && std::count(data.begin(), data.end(), '.') == 2) {
        currentVersion = data;
      }
    }
  } else {
    std::string data = readFileIfExistsUnderRoot(".", "VERSION");
    if (!data.empty()) {
      data = trim(data);
      if (data.find_first_not_of("0123456789.") == std::string::npos && std::count(data.begin(), data.end(), '.') == 2) {
        currentVersion = data;
      }
    }
  }
  return currentVersion;
}

}
