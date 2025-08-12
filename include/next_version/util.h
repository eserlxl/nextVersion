// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#pragma once

#include <cctype>
#include <cstdio>
#include <map>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
#include <filesystem>

namespace nv {

[[noreturn]] inline void die(const std::string &msg) {
  throw std::runtime_error(msg);
}

inline bool isInteger(const std::string &s) {
  if (s.empty()) return false;
  std::size_t j = 0;
  if (s[0] == '-' || s[0] == '+') j = 1;
  for (; j < s.size(); ++j) if (!std::isdigit(static_cast<unsigned char>(s[j]))) return false;
  return true;
}

inline int intOrDefault(const std::string &s, int def) {
  return isInteger(s) ? std::stoi(s) : def;
}

inline std::string trim(const std::string &s) {
  std::size_t start = s.find_first_not_of(" \t\n\r");
  std::size_t end = s.find_last_not_of(" \t\n\r");
  if (start == std::string::npos) return "";
  return s.substr(start, end - start + 1);
}

inline bool containsParentTraversal(const std::filesystem::path &p) {
  for (const auto &part : p) {
    if (part == "..") return true;
  }
  return false;
}

inline std::string readFileIfExistsUnderRoot(const std::string &baseDir, const std::string &relativePath) {
  namespace fs = std::filesystem;
  try {
    const fs::path base = fs::weakly_canonical(fs::path(baseDir));
    const fs::path rel = fs::path(relativePath);

    // Only allow relative, non-empty paths with no parent traversals
    if (rel.empty() || rel.is_absolute()) return {};
    if (containsParentTraversal(rel)) return {};

    const fs::path joined = base / rel;
    const fs::path canon = fs::weakly_canonical(joined);

    // Ensure the resolved path is inside the base directory using element-wise prefix check
    auto isWithinBase = [&]() -> bool {
      auto itBase = base.begin();
      auto itCanon = canon.begin();
      for (; itBase != base.end(); ++itBase, ++itCanon) {
        if (itCanon == canon.end() || *itBase != *itCanon) return false;
      }
      return true; // all base components matched
    };
    if (!isWithinBase()) return {};

    FILE *f = std::fopen(canon.c_str(), "rb");
    if (!f) return {};
    std::string data;
    char buf[4096];
    std::size_t n;
    while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0) data.append(buf, n);
    std::fclose(f);
    return data;
  } catch (...) {
    return {};
  }
}

// Deprecated: prefer readFileIfExistsUnderRoot(baseDir, relativePath).
// This fallback only allows reading relative paths under the current working directory.
inline std::string readFileIfExists(const std::string &path) {
  return readFileIfExistsUnderRoot(".", path);
}

inline std::string jsonEscape(const std::string &s) {
  std::string out; out.reserve(s.size() + 8);
  for (char ch : s) {
    unsigned char c = static_cast<unsigned char>(ch);
    switch (c) {
      case '\\': out += "\\\\"; break;
      case '"': out += "\\\""; break;
      case '\n': out += "\\n"; break;
      case '\r': out += "\\r"; break;
      case '\t': out += "\\t"; break;
      default:
        if (c < 0x20) {
          char buf[7];
          std::snprintf(buf, sizeof(buf), "\\u%04x", c);
          out += buf;
        } else {
          out.push_back(static_cast<char>(c));
        }
    }
  }
  return out;
}

inline std::map<std::string, std::string> parseKv(const std::string &text) {
  std::map<std::string, std::string> kv;
  std::istringstream iss(text);
  std::string line;
  while (std::getline(iss, line)) {
    if (line.empty()) continue;
    auto eq = line.find('=');
    if (eq == std::string::npos) continue;
    std::string k = line.substr(0, eq);
    std::string v = line.substr(eq + 1);
    kv.emplace(std::move(k), std::move(v));
  }
  return kv;
}

}


