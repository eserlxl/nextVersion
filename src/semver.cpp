// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of next-version and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.
#include "next_version/semver.h"
#include <regex>
#include <sstream>
#include <vector>

namespace nv {

bool isSemverCore(const std::string &v) {
  static const std::regex re(R"((0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*))");
  return std::regex_match(v, re);
}

bool isPrerelease(const std::string &v) {
  return v.find('-') != std::string::npos;
}

static bool isNumeric(const std::string &s) {
  if (s.empty()) return false;
  if (s.size() > 1 && s[0] == '0') return false; // no leading zeros unless single 0
  for (char c : s) if (c < '0' || c > '9') return false;
  return true;
}

// Compare dot-separated prerelease identifiers per SemVer §11
static int comparePrerelease(const std::string &a, const std::string &b) {
  std::vector<std::string> A, B;
  {
    std::stringstream sa(a), sb(b); std::string t;
    while (std::getline(sa, t, '.')) A.push_back(t);
    while (std::getline(sb, t, '.')) B.push_back(t);
  }
  const std::size_t maxlen = A.size() > B.size() ? A.size() : B.size();
  for (std::size_t i = 0; i < maxlen; ++i) {
    const std::string ai = i < A.size() ? A[i] : std::string();
    const std::string bi = i < B.size() ? B[i] : std::string();
    if (ai.empty() && bi.empty()) return 0;
    if (ai.empty()) return -1; // fewer identifiers -> lower
    if (bi.empty()) return 1;
    const bool an = isNumeric(ai), bn = isNumeric(bi);
    if (an && bn) {
      const long long av = std::stoll(ai), bv = std::stoll(bi);
      if (av < bv) return -1; if (av > bv) return 1;
    } else if (an && !bn) {
      return -1; // numeric < non-numeric
    } else if (!an && bn) {
      return 1;
    } else {
      if (ai < bi) return -1; if (ai > bi) return 1;
    }
  }
  return 0;
}

bool isSemverWithPrerelease(const std::string &v) {
  static const std::regex re(R"((0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?)");
  return std::regex_match(v, re);
}

int semverCompare(const std::string &a, const std::string &b) {
  auto splitMain = [](const std::string &v) {
    const std::string clean = v.substr(0, v.find('+'));
    const std::size_t dash = clean.find('-');
    const std::string main = (dash==std::string::npos)?clean:clean.substr(0, dash);
    const std::string pre = (dash==std::string::npos)?std::string():clean.substr(dash+1);
    return std::pair<std::string,std::string>(main, pre);
  };
  auto [am, ap] = splitMain(a);
  auto [bm, bp] = splitMain(b);
  int Am=0, An=0, Ap=0, Bm=0, Bn=0, Bp=0; char dot;
  {
    std::stringstream sa(am); sa>>Am>>dot>>An>>dot>>Ap;
    std::stringstream sb(bm); sb>>Bm>>dot>>Bn>>dot>>Bp;
  }
  if (Am != Bm) return Am < Bm ? -1 : 1;
  if (An != Bn) return An < Bn ? -1 : 1;
  if (Ap != Bp) return Ap < Bp ? -1 : 1;
  if (ap.empty() && bp.empty()) return 0;
  if (ap.empty()) return 1; // release > pre-release
  if (bp.empty()) return -1;
  return comparePrerelease(ap, bp);
}

}


