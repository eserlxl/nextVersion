// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "next_version/types.h"
#include "next_version/util.h"
#include "next_version/git_helpers.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <sstream>
#include <string>
#include <sys/wait.h>
#include <vector>

namespace nv {

std::string shellQuote(const std::string &s) {
  std::string out; out.reserve(s.size() + 8);
  out.push_back('\'');
  for (char c : s) {
    if (c == '\'') out += "'\\''"; else out.push_back(c);
  }
  out.push_back('\'');
  return out;
}

std::string buildCommand(const std::vector<std::string> &args) {
  std::ostringstream oss;
  for (std::size_t i = 0; i < args.size(); ++i) {
    if (i) oss << ' ';
    oss << shellQuote(args[i]);
  }
  return oss.str();
}

int runProcessCapture(const std::string &command, std::string &stdoutData) {
  std::string cmd = command + " 2>/dev/null";
  FILE *pipe = popen(cmd.c_str(), "r");
  if (!pipe) return 127;
  char buffer[4096];
  while (true) {
    std::size_t n = std::fread(buffer, 1, sizeof(buffer), pipe);
    if (n > 0) stdoutData.append(buffer, n);
    if (n < sizeof(buffer)) {
      if (std::feof(pipe)) break;
      if (std::ferror(pipe)) break;
    }
  }
  int status = pclose(pipe);
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  return 1;
}

int runGitCapture(const std::vector<std::string> &args, const std::string &repoRoot, std::string &out) {
  std::vector<std::string> full;
  full.push_back("git");
  if (!repoRoot.empty()) { full.push_back("-C"); full.push_back(repoRoot); }
  full.insert(full.end(), args.begin(), args.end());
  return runProcessCapture(buildCommand(full), out);
}

bool gitHasCommits(const std::string &repoRoot) {
  std::string out;
  int ec = runGitCapture({"rev-parse","-q","--verify","HEAD^{commit}"}, repoRoot, out);
  return ec == 0;
}

static bool endsWith(const std::string &s, const std::string &suffix) {
  return s.size() >= suffix.size() && s.rfind(suffix) == s.size() - suffix.size();
}

static bool isIgnoredBinaryOrBuildPath(const std::string &path) {
  static const std::vector<std::string> dirs = {
    "/build/", "/dist/", "/out/", "/third-party/", "/third_party/", "/vendor/",
    "/.git/", "/node_modules/", "/target/", "/bin/", "/obj/"
  };
  for (const auto &d : dirs) if (path.find(d) != std::string::npos) return true;
  static const std::vector<std::string> exts = { ".lock", ".exe", ".dll", ".so", ".dylib", ".a", ".jar", ".war", ".ear",
    ".zip", ".tar", ".gz", ".bz2", ".xz", ".7z", ".rar", ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".pdf" };
  for (const auto &e : exts) if (endsWith(path, e)) return true;
  return false;
}

static int classifyPath(const std::string &path) {
  if (isIgnoredBinaryOrBuildPath(path)) return 0;
  // tests
  {
    static const std::vector<std::string> markers = {"/test/","/tests/","/unittests/","/it/","/e2e/"};
    for (const auto &m : markers) if (path.find(m) != std::string::npos) return 10;
    static const std::vector<std::string> testExts = {"_test.c","_test.cc","_test.cpp","_test.cxx",
      ".test.c", ".test.cc", ".test.cpp", ".test.cxx", ".spec.c", ".spec.cc", ".spec.cpp", ".spec.cxx",
      ".test.py", ".test.js", ".test.ts", ".spec.js", ".spec.ts"};
    for (const auto &e : testExts) if (endsWith(path, e)) return 10;
  }
  // source
  {
    static const std::vector<std::string> srcMarkers = {"/src/","/source/","/app/","/lib/","/include/"};
    for (const auto &m : srcMarkers) if (path.find(m) != std::string::npos) return 30;
    static const std::vector<std::string> srcExts = { ".c", ".cc", ".cpp", ".cxx", ".h", ".hh", ".hpp", ".inl",
      ".go", ".rs", ".java", ".cs", ".m", ".mm", ".swift", ".kt", ".ts", ".tsx", ".js", ".jsx", ".sh", ".py", ".rb", ".php", ".pl", ".lua", ".sql",
      ".cmake", ".yml", ".yaml" };
    for (const auto &e : srcExts) if (endsWith(path, e)) return 30;
    static const std::vector<std::string> srcFiles = {"CMakeLists.txt","Makefile","makefile","GNUmakefile"};
    for (const auto &f : srcFiles) if (endsWith(path, f)) return 30;
  }
  // docs
  {
    static const std::vector<std::string> docMarkers = {"/doc/","/docs/","/documentation/","/examples/"};
    for (const auto &m : docMarkers) if (path.find(m) != std::string::npos) return 20;
    static const std::vector<std::string> docExts = { ".md", ".markdown", ".mkd", ".rst", ".adoc", ".txt" };
    for (const auto &e : docExts) if (endsWith(path, e)) return 20;
  }
  return 0;
}

static std::vector<std::string> splitByNul(const std::string &data) {
  std::vector<std::string> out;
  std::size_t start = 0;
  while (start <= data.size()) {
    std::size_t end = data.find('\0', start);
    if (end == std::string::npos) { out.push_back(data.substr(start)); break; }
    out.push_back(data.substr(start, end - start));
    start = end + 1;
    if (start == data.size()) break;
  }
  return out;
}

FileChangeStats computeFileChangeStats(const std::string &repoRoot,
                                      const std::string &baseRef,
                                      const std::string &targetRef,
                                      const std::string &onlyPathsCsv,
                                      bool ignoreWhitespace) {
  FileChangeStats stats;
  // quick test
  {
    std::vector<std::string> args = {"git", "-c", "color.ui=false", "-c", "core.quotepath=false"};
    if (!repoRoot.empty()) { args.push_back("-C"); args.push_back(repoRoot); }
    args.push_back("diff"); args.push_back("-M"); args.push_back("-C");
    if (ignoreWhitespace) args.push_back("-w");
    args.push_back("--quiet");
    args.push_back(baseRef + ".." + targetRef);
    if (!onlyPathsCsv.empty()) {
      args.push_back("--");
      std::istringstream iss(onlyPathsCsv); std::string tok; while (std::getline(iss, tok, ',')) { auto t = trim(tok); if (!t.empty()) args.push_back(t); }
    }
    std::string out; int ec = runProcessCapture(buildCommand(args), out);
    if (ec == 0) return stats;
  }
  // name-status -z
  {
    std::vector<std::string> args = {"git", "-c", "color.ui=false", "-c", "core.quotepath=false"};
    if (!repoRoot.empty()) { args.push_back("-C"); args.push_back(repoRoot); }
    args.push_back("diff"); args.push_back("-M"); args.push_back("-C");
    if (ignoreWhitespace) args.push_back("-w");
    args.push_back("--name-status"); args.push_back("-z");
    args.push_back(baseRef + ".." + targetRef);
    if (!onlyPathsCsv.empty()) { args.push_back("--"); std::istringstream iss(onlyPathsCsv); std::string tok; while (std::getline(iss, tok, ',')) { auto t = trim(tok); if (!t.empty()) args.push_back(t); } }
    std::string data; runProcessCapture(buildCommand(args), data);
    auto fields = splitByNul(data);
    for (std::size_t i = 0; i < fields.size();) {
      if (fields[i].empty()) { ++i; continue; }
      std::string status = fields[i++]; if (status.empty()) break; char code = status[0];
      std::string p1, p2; if (code == 'R' || code == 'C') { if (i < fields.size()) p1 = fields[i++]; if (i < fields.size()) p2 = fields[i++]; } else { if (i < fields.size()) p1 = fields[i++]; }
      switch (code) { case 'A': { stats.addedFiles += 1; int cls = classifyPath(p1); if (cls==30) stats.newSourceFiles++; else if (cls==10) stats.newTestFiles++; else if (cls==20) stats.newDocFiles++; } break; case 'D': stats.deletedFiles++; break; default: stats.modifiedFiles++; }
    }
  }
  // numstat
  {
    std::vector<std::string> args = {"git", "-c", "color.ui=false", "-c", "core.quotepath=false"};
    if (!repoRoot.empty()) { args.push_back("-C"); args.push_back(repoRoot); }
    args.push_back("diff"); args.push_back("-M"); args.push_back("-C"); if (ignoreWhitespace) args.push_back("-w"); args.push_back("--numstat"); args.push_back(baseRef + ".." + targetRef);
    if (!onlyPathsCsv.empty()) { args.push_back("--"); std::istringstream iss(onlyPathsCsv); std::string tok; while (std::getline(iss, tok, ',')) { auto t = trim(tok); if (!t.empty()) args.push_back(t); } }
    std::string text; runProcessCapture(buildCommand(args), text);
    std::istringstream iss(text); std::string line; while (std::getline(iss, line)) { std::istringstream ls(line); std::string insStr, delStr; if (!std::getline(ls, insStr, '\t')) continue; if (!std::getline(ls, delStr, '\t')) continue; int insVal = isInteger(insStr)?std::stoi(insStr):0; int delVal = isInteger(delStr)?std::stoi(delStr):0; stats.insertions += insVal; stats.deletions += delVal; }
  }
  return stats;
}

std::string gitDescribeLastTag(const std::string &match, const std::string &repoRoot) {
  std::string out; int ec = runGitCapture({"describe","--tags","--abbrev=0","--match", match}, repoRoot, out); if (ec != 0) return {}; return trim(out);
}

std::string gitRevListBeforeDate(const std::string &date, const std::string &repoRoot) {
  std::string out; int ec = runGitCapture({"rev-list","-1", std::string("--before=") + date + " 23:59:59", "HEAD"}, repoRoot, out); if (ec != 0) return {}; return trim(out);
}

std::string gitFirstCommit(const std::string &repoRoot) {
  std::string out; int ec = runGitCapture({"rev-list","--max-parents=0","HEAD"}, repoRoot, out); if (ec != 0) return {}; return trim(out);
}

std::string gitParentHead(const std::string &repoRoot) {
  std::string out; int ec = runGitCapture({"rev-parse","-q","--verify","HEAD~1"}, repoRoot, out); if (ec != 0) return {}; return trim(out);
}

}


