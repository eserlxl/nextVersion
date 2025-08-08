// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "next_version/types.h"
#include "next_version/util.h"
#include "next_version/git_helpers.h"
#include "next_version/analyzers.h"

#include <algorithm>
#include <cmath>
#include <regex>
#include <set>
#include <sstream>
#include <string>

namespace nv {

RefResolution resolveRefsNative(const Options &opts) {
  RefResolution rr;
  rr.targetRef = opts.targetRef.empty() ? std::string("HEAD") : opts.targetRef;
  rr.hasCommits = gitHasCommits(opts.repoRoot);
  if (!rr.hasCommits) { rr.emptyRepo = true; return rr; }

  // Step 1: choose initial base ref
  if (!opts.baseRef.empty()) rr.baseRef = opts.baseRef;
  else if (!opts.sinceCommit.empty()) rr.baseRef = opts.sinceCommit;
  else if (!opts.sinceTag.empty()) rr.baseRef = opts.sinceTag;
  else if (!opts.sinceDate.empty()) {
    std::string ref = gitRevListBeforeDate(opts.sinceDate, opts.repoRoot);
    if (!ref.empty()) rr.baseRef = ref; else { std::string first = gitFirstCommit(opts.repoRoot); if (!first.empty()) rr.baseRef = first; else rr.emptyRepo = true; }
  } else {
    std::string lastTag = gitDescribeLastTag("*", opts.repoRoot);
    if (!lastTag.empty()) rr.baseRef = lastTag; else { std::string parent = gitParentHead(opts.repoRoot); if (!parent.empty()) rr.baseRef = parent; else { std::string first = gitFirstCommit(opts.repoRoot); if (!first.empty()) { rr.baseRef = first; rr.singleCommitRepo = true; } else rr.emptyRepo = true; } }
  }
  if (rr.emptyRepo) return rr;

  // Resolve SHAs for base and target
  auto resolveSha = [&](const std::string &ref) -> std::string {
    std::string out; runGitCapture({"rev-parse","-q","--verify", ref + "^{commit}"}, opts.repoRoot, out); return trim(out);
  };

  rr.requestedBaseSha = resolveSha(rr.baseRef);
  rr.targetRef = rr.targetRef.empty() ? std::string("HEAD") : rr.targetRef;
  const std::string targetSha = resolveSha(rr.targetRef);

  // Step 2: compute merge-base for disjoint branches unless disabled
  if (!opts.noMergeBase && !rr.requestedBaseSha.empty() && !targetSha.empty()) {
    std::string effective; runGitCapture({"merge-base", rr.requestedBaseSha, targetSha}, opts.repoRoot, effective);
    rr.effectiveBaseSha = trim(effective);
    if (!rr.effectiveBaseSha.empty() && rr.effectiveBaseSha != rr.requestedBaseSha) {
      rr.baseRef = rr.effectiveBaseSha; // use merge-base as effective base
    }
  }

  // Step 3: count commits in range
  if (!rr.baseRef.empty() && !targetSha.empty()) {
    std::string count; runGitCapture({"rev-list","--count", rr.baseRef + ".." + targetSha}, opts.repoRoot, count);
    rr.commitCount = std::max(0, std::stoi(count.empty()?"0":trim(count)));
  }
  return rr;
}

ConfigValues loadConfigValues(const std::string &projectRoot) {
  ConfigValues cfg;
  const std::string path = projectRoot.empty() ? std::string("dev-config/versioning.yml") : (projectRoot + "/dev-config/versioning.yml");
  const std::string text = readFileIfExists(path);
  if (text.empty()) return cfg;
  auto findNum = [&](const std::string &section, const std::string &key) -> std::optional<long long> {
    std::istringstream iss(text); std::string line; bool in=false; int base=-1;
    while (std::getline(iss, line)) {
      if (!in) { std::smatch m; std::regex r(std::string("^([ \\t]*)") + section + ":\\s*$"); if (std::regex_search(line, m, r)) { in=true; base = static_cast<int>(m[1].str().size()); } continue; }
      int indent=0; while (indent < static_cast<int>(line.size()) && (line[indent]==' ' || line[indent]=='\t')) ++indent; if (indent <= base && line.find_first_not_of(" \t\r\n") != std::string::npos) break;
      std::smatch m2; std::regex r2(std::string("^[ \\t]{") + std::to_string(base+1) + ",}" + key + ":\\s*([0-9]+(\\.[0-9]+)?)\\s*$");
      if (std::regex_search(line, m2, r2)) { std::string num = m2[1].str(); if (num.find('.') != std::string::npos) return static_cast<long long>(std::stod(num)); else return std::stoll(num); }
    }
    return std::nullopt;
  };
  if (auto v = findNum("thresholds","major_bonus")) cfg.majorBonusThreshold = static_cast<int>(*v);
  if (auto v = findNum("thresholds","minor_bonus")) cfg.minorBonusThreshold = static_cast<int>(*v);
  if (auto v = findNum("thresholds","patch_bonus")) cfg.patchBonusThreshold = static_cast<int>(*v);
  if (auto v = findNum("bonuses","breaking_cli")) cfg.bonusBreakingCli = static_cast<int>(*v);
  if (auto v = findNum("bonuses","api_breaking")) cfg.bonusApiBreaking = static_cast<int>(*v);
  if (auto v = findNum("bonuses","removed_option")) cfg.bonusRemovedOption = static_cast<int>(*v);
  if (auto v = findNum("bonuses","cli_changes")) cfg.bonusCliChanges = static_cast<int>(*v);
  if (auto v = findNum("bonuses","manual_cli")) cfg.bonusManualCli = static_cast<int>(*v);
  if (auto v = findNum("bonuses","new_source")) cfg.bonusNewSource = static_cast<int>(*v);
  if (auto v = findNum("bonuses","new_test")) cfg.bonusNewTest = static_cast<int>(*v);
  if (auto v = findNum("bonuses","new_doc")) cfg.bonusNewDoc = static_cast<int>(*v);
  if (auto v = findNum("bonuses","security")) cfg.bonusSecurity = static_cast<int>(*v);
  {
    std::smatch m; std::regex r("^bonus_multiplier_cap:\\s*([0-9]+(\\.[0-9]+)?)\\s*$", std::regex::icase); std::istringstream iss(text); std::string ln; while (std::getline(iss, ln)) { if (std::regex_search(ln, m, r)) { cfg.bonusMultiplierCap = std::stod(m[1].str()); break; } }
  }
  // loc_divisors: patch/minor/major
  if (auto v = findNum("loc_divisors","patch")) cfg.locDivisorPatch = static_cast<int>(*v);
  if (auto v = findNum("loc_divisors","minor")) cfg.locDivisorMinor = static_cast<int>(*v);
  if (auto v = findNum("loc_divisors","major")) cfg.locDivisorMajor = static_cast<int>(*v);
  // base_deltas: patch/minor/major
  if (auto v = findNum("base_deltas","patch")) cfg.baseDeltaPatch = static_cast<int>(*v);
  if (auto v = findNum("base_deltas","minor")) cfg.baseDeltaMinor = static_cast<int>(*v);
  if (auto v = findNum("base_deltas","major")) cfg.baseDeltaMajor = static_cast<int>(*v);
  return cfg;
}

static std::string getDiffText(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, bool ignoreWhitespace, const std::string &onlyPathsCsv, bool addedOnly=false) {
  std::vector<std::string> args = {"diff","-M","-C","--unified=0","--no-ext-diff"}; if (ignoreWhitespace) args.push_back("-w"); args.push_back(baseRef + ".." + targetRef);
  if (!onlyPathsCsv.empty()) { args.push_back("--"); std::istringstream iss(onlyPathsCsv); std::string tok; while (std::getline(iss, tok, ',')) { auto t = trim(tok); if (!t.empty()) args.push_back(t); } }
  std::string text; runGitCapture(args, repoRoot, text);
  if (addedOnly) { std::istringstream in(text); std::string line; std::string out; while (std::getline(in, line)) { if (line.rfind("+++",0)==0 || line.rfind("---",0)==0 || line.rfind("@@",0)==0) continue; if (!line.empty() && line[0]=='+') out.append(line.substr(1)).push_back('\n'); } return out; }
  return text;
}

static std::string getCommitMessages(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, bool noMerges=false) {
  std::vector<std::string> args = {"log","--format=%s %b"}; if (noMerges) args.insert(args.begin(), "--no-merges"); args.push_back(baseRef + ".." + targetRef); std::string logs; runGitCapture(args, repoRoot, logs); return logs;
}

static int countRegex(const std::string &text, const std::regex &re) { int cnt=0; for (auto it=std::sregex_iterator(text.begin(), text.end(), re), end=std::sregex_iterator(); it!=end; ++it) ++cnt; return cnt; }

KeywordResults analyzeKeywords(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace) {
  KeywordResults res; std::string diff = getDiffText(repoRoot, baseRef, targetRef, ignoreWhitespace, onlyPathsCsv, false); std::string logs = getCommitMessages(repoRoot, baseRef, targetRef, false);
  std::regex cliBreakCode(R"(CLI[\- ]?BREAKING)", std::regex::icase);
  std::regex apiBreakCode(R"(API[\- ]?BREAKING)", std::regex::icase);
  std::regex generalBreakCommit(R"(BREAKING\s+CHANGE|BREAKING[^A-Za-z0-9]+.*(CHANGE|MAJOR))", std::regex::icase);
  std::regex securityCode(R"(SECURITY)", std::regex::icase);
  std::regex removedOptCode(R"(REMOVED\s+OPTION(S)?)", std::regex::icase);
  std::regex secOrCve(R"(SECURITY|CVE-\d{4}-\d{4,7})", std::regex::icase);
  int cli_breaking = countRegex(diff, cliBreakCode) + countRegex(logs, cliBreakCode);
  int api_breaking = countRegex(diff, apiBreakCode) + countRegex(logs, apiBreakCode);
  int general_break = countRegex(logs, generalBreakCommit);
  int security_total = countRegex(diff, securityCode) + countRegex(logs, secOrCve);
  res.hasCliBreaking = (cli_breaking>0); res.hasApiBreaking = (api_breaking>0); res.hasGeneralBreaking = (general_break>0); res.totalSecurity = security_total; res.removedOptionsKeywords = countRegex(diff, removedOptCode); return res;
}

CliResults analyzeCliOptions(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace) {
  CliResults r; std::string diff = getDiffText(repoRoot, baseRef, targetRef, ignoreWhitespace, onlyPathsCsv, false); std::istringstream iss(diff); std::string line; std::set<std::string> removedLong, addedLong; std::regex longOpt(R"(--[A-Za-z0-9][A-Za-z0-9\-]*)"); std::regex protoRemoved(R"(^-[^+].*[A-Za-z_][A-Za-z0-9_\s\*]+\s+[A-Za-z_][A-Za-z0-9_]*\([^;]*\)\s*;\s*$)"); std::regex shortOpt(R"(^-[^+].*[^-]-[A-Za-z](\s|$))");
  while (std::getline(iss, line)) { if (line.rfind("+++",0)==0 || line.rfind("---",0)==0 || line.rfind("@@",0)==0) continue; if (!line.empty() && line[0]=='-') { for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) removedLong.insert((*it)[0]); if (std::regex_search(line, protoRemoved)) r.apiBreaking = true; if (std::regex_search(line, shortOpt)) r.removedShortCount++; } else if (!line.empty() && line[0]=='+') { for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) addedLong.insert((*it)[0]); } }
  r.removedLongCount = static_cast<int>(removedLong.size()); r.addedLongCount = static_cast<int>(addedLong.size()); r.manualRemovedLongCount = r.removedLongCount; r.manualAddedLongCount = r.addedLongCount; r.breakingCliChanges = (r.removedLongCount>0) || (r.removedShortCount>0); r.manualCliChanges = (r.manualAddedLongCount>0 || r.manualRemovedLongCount>0); r.cliChanges = r.breakingCliChanges || r.manualCliChanges || (r.addedLongCount>0); return r;
}

SecurityResults analyzeSecurity(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace, bool addedOnly) {
  SecurityResults s; std::string commits = getCommitMessages(repoRoot, baseRef, targetRef, false); std::string diff = getDiffText(repoRoot, baseRef, targetRef, ignoreWhitespace, onlyPathsCsv, addedOnly);
  std::regex secRe(R"(\b(security|vuln|exploit|breach|attack|threat|malware|virus|trojan|backdoor|rootkit|phishing|ddos|overflow|injection|xss|csrf|sqli|rce|ssrf|xxe|privilege|escalation|bypass|mitigation|hardening|sandbox|auth|encryption|decryption|tls|ssl|certificate|secret|token|leak|expos|traversal)\b)", std::regex::icase); std::regex cveRe(R"(\bCVE-[0-9]{4}-[0-9]{4,7}\b)", std::regex::icase); std::regex memRe(R"(\b(buffer[- _]?overflow|stack[- _]?overflow|heap[- _]?overflow|use[- _]?after[- _]?free|double[- _]?free|null[- _]?pointer|dangling[- _]?pointer|out[- _]?of[- _]?bounds|oob|memory[- _]?leak|format[- _]?string|integer[- _]?overflow|signedness|race[- _]?condition|data[- _]?race|deadlock)\b)", std::regex::icase); std::regex crashRe(R"(\b(segfault|segmentation\s+fault|crash|abort|assert|panic|fatal\s+error|core\s+dump|stack\s+trace)\b)", std::regex::icase);
  s.securityKeywordsCommits = static_cast<int>(std::distance(std::sregex_iterator(commits.begin(), commits.end(), secRe), std::sregex_iterator()));
  s.securityPatternsDiff = static_cast<int>(std::distance(std::sregex_iterator(diff.begin(), diff.end(), secRe), std::sregex_iterator()));
  s.cvePatterns = static_cast<int>(std::distance(std::sregex_iterator(diff.begin(), diff.end(), cveRe), std::sregex_iterator()));
  s.memorySafetyIssues = static_cast<int>(std::distance(std::sregex_iterator(diff.begin(), diff.end(), memRe), std::sregex_iterator()));
  s.crashFixes = static_cast<int>(std::distance(std::sregex_iterator(diff.begin(), diff.end(), crashRe), std::sregex_iterator()));
  return s;
}

int baseDeltaFor(const std::string &bumpType, int loc, const ConfigValues &cfg) {
  // Use config-driven base deltas and divisors (mirrors shell math: rounded additions)
  if (bumpType == "patch") {
    return std::max(1, cfg.baseDeltaPatch + (loc + cfg.locDivisorPatch/2) / cfg.locDivisorPatch);
  } else if (bumpType == "minor") {
    // Shell used round(LOC/100) for minor with base 5; keep compatible slope based on divisor
    int divisor = std::max(1, cfg.locDivisorMinor / 5); // default 500 -> 100
    return std::max(1, cfg.baseDeltaMinor + (loc + divisor/2) / divisor);
  } else if (bumpType == "major") {
    int divisor = std::max(1, cfg.locDivisorMajor / 10); // default 1000 -> 100
    return std::max(1, cfg.baseDeltaMajor + (loc + divisor/2) / divisor);
  }
  return 1;
}

int computeTotalBonusWithMultiplier(int baseBonus, int loc, const std::string &bumpType, const ConfigValues &cfg) {
  int divisor = (bumpType=="patch")?cfg.locDivisorPatch:((bumpType=="minor")?cfg.locDivisorMinor:cfg.locDivisorMajor);
  double mult = 1.0 + (divisor>0 ? static_cast<double>(loc)/static_cast<double>(divisor) : 0.0);
  double cap = cfg.bonusMultiplierCap;
  if (mult > cap) mult = cap;
  double total = static_cast<double>(baseBonus) * mult;
  int totalInt = static_cast<int>(std::lround(total));
  return totalInt;
}

std::string bumpVersion(const std::string &current, const std::string &bumpType, int loc, int bonus, const ConfigValues &cfg, int mainMod) {
  int maj=0,min=0,pat=0; { std::istringstream ss(current); char dot; if (!(ss>>maj)) { maj=0; } if (!(ss>>dot)) { min=0; pat=0; } else if (!(ss>>min)) { min=0; pat=0; } if (!(ss>>dot)) { pat=0; } else { ss>>pat; } }
  if (maj==0 && min==0 && pat==0) { if (bumpType=="major") return "1.0.0"; if (bumpType=="minor") return "0.1.0"; return "0.0.1"; }
  int base = baseDeltaFor(bumpType, loc, cfg);
  int totalBonus = computeTotalBonusWithMultiplier(bonus, loc, bumpType, cfg);
  int totalDelta = base + totalBonus;
  if (totalDelta < 1) totalDelta = 1;
  long long zNew = static_cast<long long>(pat) + totalDelta;
  long long dy = zNew / mainMod; long long newZ = zNew % mainMod;
  long long yNew = static_cast<long long>(min) + dy;
  long long dx = yNew / mainMod; long long newY = yNew % mainMod;
  long long newX = static_cast<long long>(maj) + dx;
  std::ostringstream out; out << newX << '.' << newY << '.' << newZ;
  return out.str();
}

}


