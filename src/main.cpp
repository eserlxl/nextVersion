// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <algorithm>
#include <cctype>
#include <iostream>
#include <sstream>
#include <string>
#include "next_version/types.h"
#include "next_version/util.h"
#include "next_version/git_helpers.h"
#include "next_version/analyzers.h"
#include "next_version/defaults.h"
#include "next_version/cli.h"
#include "next_version/bonus_calculator.h"
#include "next_version/version_reader.h"
#include "next_version/output_formatter.h"
#include "next_version/suggestion_engine.h"
#include "next_version/git_ops.h"

int main(int argc, char **argv) {
  using namespace nv;
  const Options opts = parseArgs(argc, argv);

  // Resolve refs (native)
  RefResolution ref = resolveRefsNative(opts);
  std::string BASE_REF, TARGET_REF;
  if (ref.emptyRepo) { BASE_REF = "EMPTY"; TARGET_REF = "HEAD"; }
  else { BASE_REF = ref.baseRef; TARGET_REF = ref.targetRef; }

  // 3) Analyze file changes
  Kv fileKv;
  FileChangeStats stats;
  if (BASE_REF == "EMPTY") {
    fileKv = makeDefaultFileKv();
  } else {
    // Prefer native git path to avoid fragile bash errors
    stats = computeFileChangeStats(opts.repoRoot, BASE_REF, TARGET_REF, opts.onlyPaths, opts.ignoreWhitespace);
    std::ostringstream ss;
    ss << "ADDED_FILES=" << stats.addedFiles << "\n";
    ss << "MODIFIED_FILES=" << stats.modifiedFiles << "\n";
    ss << "DELETED_FILES=" << stats.deletedFiles << "\n";
    ss << "NEW_SOURCE_FILES=" << stats.newSourceFiles << "\n";
    ss << "NEW_TEST_FILES=" << stats.newTestFiles << "\n";
    ss << "NEW_DOC_FILES=" << stats.newDocFiles << "\n";
    ss << "DIFF_SIZE=" << (stats.insertions + stats.deletions) << "\n";
    fileKv = parseKv(ss.str());
  }

  // 4) Analyze CLI options (use native C++ implementation)
  Kv CLI;
  if (BASE_REF == "EMPTY") CLI = makeDefaultCliKv();
  else {
    CliResults cliResults = analyzeCliOptions(opts.repoRoot, BASE_REF, TARGET_REF, opts.onlyPaths, opts.ignoreWhitespace);
    CLI = convertCliResultsToKv(cliResults);
  }

  // 5) Security keywords (use native C++ implementation)
  Kv SEC;
  if (BASE_REF == "EMPTY") SEC = makeDefaultSecurityKv();
  else {
    SecurityResults secResults = analyzeSecurity(opts.repoRoot, BASE_REF, TARGET_REF, opts.onlyPaths, opts.ignoreWhitespace, false);
    SEC = convertSecurityResultsToKv(secResults);
  }

  // 6) General keyword analysis (use native C++ implementation)
  Kv KW;
  if (BASE_REF == "EMPTY") KW = makeDefaultKeywordKv();
  else {
    KeywordResults kwResults = analyzeKeywords(opts.repoRoot, BASE_REF, TARGET_REF, opts.onlyPaths, opts.ignoreWhitespace);
    KW = convertKeywordResultsToKv(kwResults);
  }

  // 7) Bonus calculation
  const ConfigValues CFGN = loadConfigValues(opts.repoRoot);
  const int TOTAL_BONUS = calculateTotalBonus(fileKv, CLI, SEC, KW, CFGN);

  // 8) Current version
  const std::string currentVersion = readCurrentVersion(opts.repoRoot);

  // 9) Determine suggestion
  const std::string suggestion = determineSuggestion(TOTAL_BONUS, CFGN);

  // 10) Next version (native)
  std::string nextVersion;
  if (suggestion != "none") {
    nextVersion = bumpVersion(currentVersion, suggestion,
                              intOrDefault(fileKv.count("DIFF_SIZE") ? fileKv.at("DIFF_SIZE") : "", 0),
                              TOTAL_BONUS, CFGN);
  }

  // 11) Optionally perform git operations (commit/tag/push)
  if (opts.doCommit || opts.doTag || opts.doPush || opts.pushTags) {
    GitOpsOptions g;
    g.doCommit = opts.doCommit; g.doTag = opts.doTag; g.doPush = opts.doPush; g.pushTags = opts.pushTags;
    g.allowDirty = opts.allowDirty; g.signCommit = opts.signCommit; g.annotatedTag = opts.annotatedTag; g.signedTag = opts.signedTag; g.noVerify = opts.noVerify;
    g.remote = opts.remote; g.tagPrefix = opts.tagPrefix; g.commitMessage = opts.commitMessage;
    const std::string effectiveRepoRoot = opts.repoRoot.empty() ? std::string(".") : opts.repoRoot;
    const std::string commitCurrent = currentVersion.empty() ? std::string("none") : currentVersion;
    int rc = performGitOperations(g, effectiveRepoRoot, nextVersion.empty()?currentVersion:nextVersion, commitCurrent);
    if (rc != 0) return rc;
  }

  // 12) Output formats
  const int loc = intOrDefault(fileKv.count("DIFF_SIZE") ? fileKv.at("DIFF_SIZE") : "", 0);
  formatOutput(opts, suggestion, currentVersion, nextVersion, TOTAL_BONUS, CLI, BASE_REF, TARGET_REF, CFGN, loc);

  // Exit code policy
  return determineExitCode(opts, suggestion);
}


