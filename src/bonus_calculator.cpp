// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "next_version/bonus_calculator.h"
#include "next_version/util.h"

namespace nv {

int calculateTotalBonus(const Kv &fileKv, const Kv &CLI, const Kv &SEC, const Kv &KW, const ConfigValues &cfg) {
  int TOTAL_BONUS = 0;
  auto flagTrue = [](const Kv &m, const char *k) {
    auto it = m.find(k); return it != m.end() && it->second == "true";
  };

  if (flagTrue(KW, "HAS_CLI_BREAKING") || flagTrue(CLI, "BREAKING_CLI_CHANGES")) {
    TOTAL_BONUS += cfg.bonusBreakingCli;
  }
  if (flagTrue(KW, "HAS_API_BREAKING") || flagTrue(CLI, "API_BREAKING")) {
    TOTAL_BONUS += cfg.bonusApiBreaking;
  }
  if (flagTrue(KW, "HAS_GENERAL_BREAKING")) {
    TOTAL_BONUS += cfg.bonusApiBreaking;
  }

  const int securityKeywords = intOrDefault(SEC.count("SECURITY_KEYWORDS") ? SEC.at("SECURITY_KEYWORDS") : "", 0);
  const int keywordSecurity = intOrDefault(KW.count("TOTAL_SECURITY") ? KW.at("TOTAL_SECURITY") : "", 0);
  const int totalSecurity = std::max(securityKeywords, keywordSecurity);
  if (totalSecurity > 0) {
    TOTAL_BONUS += totalSecurity * cfg.bonusSecurity;
  }

  if (flagTrue(CLI, "CLI_CHANGES")) {
    TOTAL_BONUS += cfg.bonusCliChanges;
  }
  if (flagTrue(CLI, "MANUAL_CLI_CHANGES")) {
    TOTAL_BONUS += cfg.bonusManualCli;
  }
  if (intOrDefault(fileKv.count("NEW_SOURCE_FILES") ? fileKv.at("NEW_SOURCE_FILES") : "", 0) > 0) {
    TOTAL_BONUS += cfg.bonusNewSource;
  }
  if (intOrDefault(fileKv.count("NEW_TEST_FILES") ? fileKv.at("NEW_TEST_FILES") : "", 0) > 0) {
    TOTAL_BONUS += cfg.bonusNewTest;
  }
  if (intOrDefault(fileKv.count("NEW_DOC_FILES") ? fileKv.at("NEW_DOC_FILES") : "", 0) > 0) {
    TOTAL_BONUS += cfg.bonusNewDoc;
  }

  const int cliRemoved = intOrDefault(CLI.count("REMOVED_SHORT_COUNT") ? CLI.at("REMOVED_SHORT_COUNT") : "", 0)
                       + intOrDefault(CLI.count("REMOVED_LONG_COUNT") ? CLI.at("REMOVED_LONG_COUNT") : "", 0)
                       + intOrDefault(CLI.count("MANUAL_REMOVED_LONG_COUNT") ? CLI.at("MANUAL_REMOVED_LONG_COUNT") : "", 0);
  const int kwRemoved  = intOrDefault(KW.count("REMOVED_OPTIONS_KEYWORDS") ? KW.at("REMOVED_OPTIONS_KEYWORDS") : "", 0);
  const int totalRemoved = cliRemoved + kwRemoved;
  if (totalRemoved > 0) {
    TOTAL_BONUS += cfg.bonusRemovedOption;
  }
  // manual CLI bonus is already accounted above via CLI flags

  return TOTAL_BONUS;
}

}
