// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#pragma once

#include <map>
#include <string>

namespace nv {

using Kv = std::map<std::string, std::string>;

struct Options {
  std::string sinceTag;
  std::string sinceCommit;
  std::string sinceDate;
  std::string baseRef;
  std::string targetRef;
  std::string repoRoot;
  bool noMergeBase {false};
  std::string tagMatch {"*"};
  bool firstParent {false};
  std::string onlyPaths;
  bool ignoreWhitespace {false};
  bool verbose {false};
  bool machine {false};
  bool json {false};
  bool suggestOnly {false};
  bool strictStatus {false};
  // Git operation toggles (ported from shell orchestrator)
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
  std::string commitMessage;
};

struct FileChangeStats {
  int addedFiles {0};
  int modifiedFiles {0};
  int deletedFiles {0};
  int newSourceFiles {0};
  int newTestFiles {0};
  int newDocFiles {0};
  int insertions {0};
  int deletions {0};
};

struct RefResolution {
  std::string baseRef;
  std::string targetRef;
  bool emptyRepo {false};
  bool singleCommitRepo {false};
  bool hasCommits {true};
  // Optional details for parity with shell tools
  std::string requestedBaseSha;   // resolved SHA for the initially selected base
  std::string effectiveBaseSha;   // merge-base(base, target) when applicable
  int commitCount {0};            // commits between effective base and target
};

struct ConfigValues {
  int majorBonusThreshold {8};
  int minorBonusThreshold {4};
  int patchBonusThreshold {0};
  // Defaults aligned with dev-config/versioning.yml for parity with shell analyzer
  int bonusBreakingCli {4};
  int bonusApiBreaking {5};
  int bonusRemovedOption {3};
  int bonusCliChanges {2};
  int bonusManualCli {1};
  int bonusNewSource {1};
  int bonusNewTest {1};
  int bonusNewDoc {1};
  int bonusSecurity {5};
  double bonusMultiplierCap {5.0};
  // Config-driven base deltas (fallbacks mirror shell defaults)
  int baseDeltaPatch {1};
  int baseDeltaMinor {5};
  int baseDeltaMajor {10};
  // Config-driven LOC divisors (fallbacks: 250, 500, 1000)
  int locDivisorPatch {250};
  int locDivisorMinor {500};
  int locDivisorMajor {1000};
};

struct KeywordResults {
  bool hasCliBreaking {false};
  bool hasApiBreaking {false};
  bool hasGeneralBreaking {false};
  int totalSecurity {0};
  int removedOptionsKeywords {0};
};

struct CliResults {
  bool cliChanges {false};
  bool breakingCliChanges {false};
  bool apiBreaking {false};
  bool manualCliChanges {false};
  int removedShortCount {0};
  int removedLongCount {0};
  int addedLongCount {0};
  int manualAddedLongCount {0};
  int manualRemovedLongCount {0};
  int helpTextChanges {0};
  int enhancedCliPatterns {0};
};

struct SecurityResults {
  int securityKeywordsCommits {0};
  int securityPatternsDiff {0};
  int cvePatterns {0};
  int memorySafetyIssues {0};
  int crashFixes {0};
};

}


