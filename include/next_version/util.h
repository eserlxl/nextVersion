// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of next-version and is licensed under
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

inline std::string readFileIfExists(const std::string &path) {
  FILE *f = std::fopen(path.c_str(), "rb");
  if (!f) return {};
  std::string data;
  char buf[4096];
  std::size_t n;
  while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0) data.append(buf, n);
  std::fclose(f);
  return data;
}

inline std::string jsonEscape(const std::string &s) {
  std::string out; out.reserve(s.size() + 8);
  for (unsigned char c : s) {
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


