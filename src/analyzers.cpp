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

  // Step 1: choose initial base ref (mirror bash ref-resolver.sh)
  if (!opts.baseRef.empty()) rr.baseRef = opts.baseRef;
  else if (!opts.sinceCommit.empty()) rr.baseRef = opts.sinceCommit;
  else if (!opts.sinceTag.empty()) rr.baseRef = opts.sinceTag;
  else if (!opts.sinceDate.empty()) {
    std::string ref = gitRevListBeforeDate(opts.sinceDate, opts.repoRoot);
    if (!ref.empty()) rr.baseRef = ref; else { std::string first = gitFirstCommit(opts.repoRoot); if (!first.empty()) rr.baseRef = first; else rr.emptyRepo = true; }
  } else {
    // Default to last tag (match pattern), fallback to HEAD~1, then first commit
    std::string lastTag = gitDescribeLastTag(opts.tagMatch.empty()?"*":opts.tagMatch, opts.repoRoot);
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

  // Step 2: compute merge-base for disjoint branches unless disabled (bash parity)
  if (!opts.noMergeBase && !rr.requestedBaseSha.empty() && !targetSha.empty()) {
    std::string effective; runGitCapture({"merge-base", rr.requestedBaseSha, targetSha}, opts.repoRoot, effective);
    rr.effectiveBaseSha = trim(effective);
    if (!rr.effectiveBaseSha.empty() && rr.effectiveBaseSha != rr.requestedBaseSha) {
      rr.baseRef = rr.effectiveBaseSha; // use merge-base as effective base
    }
  }

  // Step 3: count commits in range (support --first-parent like bash)
  if (!rr.baseRef.empty() && !targetSha.empty()) {
    std::vector<std::string> args = {"rev-list","--count"};
    if (opts.firstParent) args.push_back("--first-parent");
    args.push_back(rr.baseRef + ".." + targetSha);
    std::string count; runGitCapture(args, opts.repoRoot, count);
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
    
    // For nested sections, we need to handle them specially
    if (section.find('.') != std::string::npos) {
      // Handle nested sections like "bonuses.breaking_changes"
      std::vector<std::string> parts;
      std::istringstream sectionStream(section);
      std::string part;
      while (std::getline(sectionStream, part, '.')) {
        parts.push_back(part);
      }
      
      if (parts.size() >= 2) {
        // Look for the nested structure
        std::istringstream iss2(text);
        std::string line2;
        bool inParent = false;
        bool inChild = false;
        int parentIndent = -1;
        int childIndent = -1;
        
        while (std::getline(iss2, line2)) {
          int indent = 0;
          while (indent < static_cast<int>(line2.size()) && (line2[indent] == ' ' || line2[indent] == '\t')) ++indent;
          
          if (!inParent) {
            // Look for parent section
            std::smatch m;
            std::regex r(std::string("^[ \\t]*") + parts[0] + ":\\s*$");
            if (std::regex_search(line2, m, r)) {
              inParent = true;
              parentIndent = indent;
            }
          } else if (!inChild) {
            // Look for child section
            if (indent > parentIndent) {
              std::smatch m;
              std::regex r(std::string("^[ \\t]*") + parts[1] + ":\\s*$");
              if (std::regex_search(line2, m, r)) {
                inChild = true;
                childIndent = indent;
              }
            } else if (indent <= parentIndent) {
              // We've left the parent section
              break;
            }
          } else {
            // Look for the key in the child section
            if (indent > childIndent) {
              std::smatch m;
              std::regex r(std::string("^[ \\t]*") + key + ":\\s*([0-9]+(\\.[0-9]+)?)\\s*$");
              if (std::regex_search(line2, m, r)) {
                std::string num = m[1].str();
                if (num.find('.') != std::string::npos) return static_cast<long long>(std::stod(num));
                else return std::stoll(num);
              }
            } else if (indent <= childIndent) {
              // We've left the child section
              break;
            }
          }
        }
      }
      return std::nullopt;
    }
    
    // Handle simple sections
    while (std::getline(iss, line)) {
      if (!in) { 
        std::smatch m; 
        std::regex r(std::string("^([ \\t]*)") + section + ":\\s*$"); 
        if (std::regex_search(line, m, r)) { 
          in = true; 
          base = static_cast<int>(m[1].str().size()); 
        } 
        continue; 
      }
      int indent = 0; 
      while (indent < static_cast<int>(line.size()) && (line[indent] == ' ' || line[indent] == '\t')) ++indent; 
      if (indent <= base && line.find_first_not_of(" \t\r\n") != std::string::npos) break;
      std::smatch m2; 
      std::regex r2(std::string("^[ \\t]{") + std::to_string(base+1) + ",}" + key + ":\\s*([0-9]+(\\.[0-9]+)?)\\s*$");
      if (std::regex_search(line, m2, r2)) { 
        std::string num = m2[1].str(); 
        if (num.find('.') != std::string::npos) return static_cast<long long>(std::stod(num)); 
        else return std::stoll(num); 
      }
    }
    return std::nullopt;
  };
  
  // Parse thresholds
  if (auto v = findNum("thresholds","major_bonus")) cfg.majorBonusThreshold = static_cast<int>(*v);
  if (auto v = findNum("thresholds","minor_bonus")) cfg.minorBonusThreshold = static_cast<int>(*v);
  if (auto v = findNum("thresholds","patch_bonus")) cfg.patchBonusThreshold = static_cast<int>(*v);
  
  // Parse bonuses - handle both old flat structure and new nested structure
  // Try new nested structure first, fall back to old flat structure
  if (auto v1 = findNum("bonuses.breaking_changes","cli_breaking")) cfg.bonusBreakingCli = static_cast<int>(*v1);
  else if (auto v2 = findNum("bonuses","breaking_cli")) cfg.bonusBreakingCli = static_cast<int>(*v2);
  
  if (auto v3 = findNum("bonuses.breaking_changes","api_breaking")) cfg.bonusApiBreaking = static_cast<int>(*v3);
  else if (auto v4 = findNum("bonuses","api_breaking")) cfg.bonusApiBreaking = static_cast<int>(*v4);
  
  if (auto v5 = findNum("bonuses.breaking_changes","removed_features")) cfg.bonusRemovedOption = static_cast<int>(*v5);
  else if (auto v6 = findNum("bonuses","removed_option")) cfg.bonusRemovedOption = static_cast<int>(*v6);
  
  if (auto v7 = findNum("bonuses.features","new_cli_command")) cfg.bonusCliChanges = static_cast<int>(*v7);
  else if (auto v8 = findNum("bonuses","cli_changes")) cfg.bonusCliChanges = static_cast<int>(*v8);
  
  if (auto v9 = findNum("bonuses.features","new_config_option")) cfg.bonusManualCli = static_cast<int>(*v9);
  else if (auto v10 = findNum("bonuses","manual_cli")) cfg.bonusManualCli = static_cast<int>(*v10);
  
  if (auto v11 = findNum("bonuses.features","new_source_file")) cfg.bonusNewSource = static_cast<int>(*v11);
  else if (auto v12 = findNum("bonuses.code_quality","new_source_file")) cfg.bonusNewSource = static_cast<int>(*v12);
  else if (auto v13 = findNum("bonuses","new_source")) cfg.bonusNewSource = static_cast<int>(*v13);
  
  if (auto v14 = findNum("bonuses.code_quality","new_test_suite")) cfg.bonusNewTest = static_cast<int>(*v14);
  else if (auto v15 = findNum("bonuses","new_test")) cfg.bonusNewTest = static_cast<int>(*v15);
  
  if (auto v16 = findNum("bonuses.user_experience","user_docs")) cfg.bonusNewDoc = static_cast<int>(*v16);
  else if (auto v17 = findNum("bonuses","new_doc")) cfg.bonusNewDoc = static_cast<int>(*v17);
  
  // Security bonus - try multiple possible locations in the new structure
  if (auto v18 = findNum("bonuses.security_stability","security_vuln")) cfg.bonusSecurity = static_cast<int>(*v18);
  else if (auto v19 = findNum("bonuses","security")) cfg.bonusSecurity = static_cast<int>(*v19);
  
  // Parse bonus multiplier cap
  {
    std::smatch m; std::regex r("^bonus_multiplier_cap:\\s*([0-9]+(\\.[0-9]+)?)\\s*$", std::regex::icase); std::istringstream iss(text); std::string ln; while (std::getline(iss, ln)) { if (std::regex_search(ln, m, r)) { cfg.bonusMultiplierCap = std::stod(m[1].str()); break; } }
  }
  
  // Parse loc_divisors
  if (auto v = findNum("loc_divisors","patch")) cfg.locDivisorPatch = static_cast<int>(*v);
  if (auto v = findNum("loc_divisors","minor")) cfg.locDivisorMinor = static_cast<int>(*v);
  if (auto v = findNum("loc_divisors","major")) cfg.locDivisorMajor = static_cast<int>(*v);
  
  // Parse base_deltas
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
  // Code and commit patterns for breaking changes (align with shell analyzer)
  std::regex cliBreakCode(R"(CLI[\- ]?BREAKING)", std::regex::icase);
  std::regex apiBreakCode(R"(API[\- ]?BREAKING)", std::regex::icase);
  // In commit messages also accept "BREAKING: ... CLI" and "BREAKING: ... API"
  std::regex cliBreakCommit(R"(BREAKING[^A-Za-z0-9]+.*CLI)", std::regex::icase);
  std::regex apiBreakCommit(R"(BREAKING[^A-Za-z0-9]+.*API)", std::regex::icase);
  std::regex generalBreakCommit(R"(BREAKING\s+CHANGE|BREAKING[^A-Za-z0-9]+.*(CHANGE|MAJOR))", std::regex::icase);
  // Match bash version's comment pattern: (^|[[:space:]])[+-]?[[:space:]]*(//|/\\*|#|--)[[:space:]]*SECURITY
  std::regex securityCode(R"((^|\s)[+-]?\s*(//|/\*|#|--)\s*SECURITY)", std::regex::icase);
  std::regex removedOptCode(R"(REMOVED\s+OPTION(S)?)", std::regex::icase);
  // Match bash version's commit pattern: (SECURITY|VULNERABILIT(Y|IES)|CVE[- ]?[0-9]{4}-[0-9]+)
  std::regex secOrCve(R"(SECURITY|VULNERABILIT(Y|IES)|CVE[- ]?[0-9]{4}-[0-9]+)", std::regex::icase);
  int cli_breaking = countRegex(diff, cliBreakCode) + countRegex(logs, cliBreakCode) + countRegex(logs, cliBreakCommit);
  int api_breaking = countRegex(diff, apiBreakCode) + countRegex(logs, apiBreakCode) + countRegex(logs, apiBreakCommit);
  int general_break = countRegex(logs, generalBreakCommit);
  int security_total = countRegex(diff, securityCode) + countRegex(logs, secOrCve);
  res.hasCliBreaking = (cli_breaking>0); res.hasApiBreaking = (api_breaking>0); res.hasGeneralBreaking = (general_break>0); res.totalSecurity = security_total; res.removedOptionsKeywords = countRegex(diff, removedOptCode); return res;
}

CliResults analyzeCliOptions(const std::string &repoRoot, const std::string &baseRef, const std::string &targetRef, const std::string &onlyPathsCsv, bool ignoreWhitespace) {
  CliResults r;
  // Full diff for general signals
  // Parity with bash analyzer: when no path filters are provided, restrict to common C/C++ files by default.
  // Use recursive glob pathspecs via Git's :(glob) to match **/*.ext like the shell version.
  const std::string defaultCppGlobPathspec =
      ":(glob)**/*.c,:(glob)**/*.cc,:(glob)**/*.cpp,:(glob)**/*.cxx,:(glob)**/*.h,:(glob)**/*.hh,:(glob)**/*.hpp";
  const std::string effectivePaths = onlyPathsCsv.empty() ? defaultCppGlobPathspec : onlyPathsCsv;
  std::string diff = getDiffText(repoRoot, baseRef, targetRef, ignoreWhitespace, effectivePaths, false);
  // Restrict help text and CLI pattern heuristics to C/C++ sources/headers to align with bash CPP_DIFF
  // Use the same effective pathspec as above to ensure parity with PATHSPEC handling in shell analyzer
  const std::string cppPathspec = effectivePaths;
  std::string cppDiff = getDiffText(repoRoot, baseRef, targetRef, ignoreWhitespace, cppPathspec, false);
  std::istringstream iss(diff);
  std::istringstream cppIss(cppDiff);
  std::string line;
  std::set<std::string> removedLongFromStruct, addedLongFromStruct;
  std::set<std::string> removedLongManual, addedLongManual;
  std::regex longOpt(R"(--[A-Za-z0-9][A-Za-z0-9\-]*)");
  std::regex protoRemoved(R"(^-[^+].*[A-Za-z_][A-Za-z0-9_\s\*]+\s+[A-Za-z_][A-Za-z0-9_]*\([^;]*\)\s*;\s*$)");
  std::regex shortOpt(R"(^-[^+].*[^-]-[A-Za-z](\s|$))");
  // Detect case labels like bash analyzer: collect removed and added case labels and compare
  std::set<std::string> removedCases, addedCases;
  std::regex caseLabelRe(R"(case\s+([^:\s]+)\s*:)");
  // Enhanced CLI patterns (heuristic signals)
  std::regex getoptCall(R"((getopt_long|getopt)\s*\()");
  std::regex argcArgvAdded(R"(^\+.*\b(argc|argv)\b)");
  // Make help/usage pattern case-insensitive to align with bash analyzer (-i)
  std::regex helpUsageAdded(R"(^\+.*\b(usage|help|option|argument)\b)", std::regex::icase);
  // Additional enhanced CLI patterns to mirror bash analyzer heuristics
  std::regex shortOptionAdded(R"(^\+[^/#!].*-[A-Za-z](\s|$))");
  std::regex longOptionAdded(R"(^\+[^/#!].*--[A-Za-z0-9\-]+)");
  std::regex argcCheckAdded(R"(^\+.*\bargc\s*[<>=!])");
  std::regex argvAccessAdded(R"(^\+.*\bargv\[)");
  // Exclude generic main() additions from enhanced CLI patterns to reduce noise
  // by not defining a mainSignatureAdded regex here (kept as a no-op placeholder)
  const bool countMainSignature = false;
  int enhancedCount = 0;
  int helpTextChangesCount = 0;
  
  auto isCommentLine = [](const std::string &ln) -> bool {
    // minus or plus, optional spaces, then // or /*
    size_t i = 0; if (ln.empty()) return false; char s = ln[0]; if (s!='-' && s!='+') return false; i = 1; while (i < ln.size() && std::isspace(static_cast<unsigned char>(ln[i]))) ++i; if (i+1 < ln.size() && ln[i]=='/' && (ln[i+1]=='/' || ln[i+1]=='*')) return true; return false;
  };
  auto hasQuotedLongOpt = [](const std::string &ln) -> bool {
    // crude: if line contains a quote and also --, treat as quoted long opt (skip)
    return (ln.find('"') != std::string::npos) && (ln.find("--") != std::string::npos);
  };

  while (std::getline(iss, line)) {
    if (line.rfind("+++",0)==0 || line.rfind("---",0)==0 || line.rfind("@@",0)==0) continue;
    if (!line.empty() && line[0]=='-') {
      // Struct-based long options and short option removals
      for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) {
        removedLongFromStruct.insert((*it)[0]);
      }
      if (std::regex_search(line, protoRemoved)) r.apiBreaking = true;
      if (std::regex_search(line, shortOpt)) r.removedShortCount++;
      // Do not count enhanced CLI patterns on removed lines to align with bash
      // Manual long option detection on diff lines excluding obvious comments/quoted strings
      if (!isCommentLine(line) && !hasQuotedLongOpt(line)) {
        for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) {
          removedLongManual.insert((*it)[0]);
        }
      }
      std::smatch m; if (std::regex_search(line, m, caseLabelRe)) { removedCases.insert(m[1].str()); }
    } else if (!line.empty() && line[0]=='+') {
      for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) {
        addedLongFromStruct.insert((*it)[0]);
      }
       if (!isCommentLine(line) && !hasQuotedLongOpt(line)) {
        for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) {
          addedLongManual.insert((*it)[0]);
        }
      }
      std::smatch m; if (std::regex_search(line, m, caseLabelRe)) { addedCases.insert(m[1].str()); }
       // Disabled help/usage and heuristic enhanced pattern boosts for parity with shell results
    }
  }

  // Second pass on C/C++-only diff for help text and enhanced CLI patterns (parity with bash CPP_DIFF)
  while (std::getline(cppIss, line)) {
    if (line.rfind("+++",0)==0 || line.rfind("---",0)==0 || line.rfind("@@",0)==0) continue;
    if (!line.empty() && line[0]=='+') {
      // Disabled help/usage and heuristic enhanced pattern boosts for parity with shell results
      // Manual long option detection only on C/C++ lines to reduce false positives
      if (!isCommentLine(line) && !hasQuotedLongOpt(line)) {
        for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) {
          addedLongManual.insert((*it)[0]);
        }
      }
    } else if (!line.empty() && line[0]=='-') {
      // Removed side for manual long options and short option removals
      if (std::regex_search(line, shortOpt)) r.removedShortCount++;
      if (!isCommentLine(line) && !hasQuotedLongOpt(line)) {
        for (auto it = std::sregex_iterator(line.begin(), line.end(), longOpt), end=std::sregex_iterator(); it!=end; ++it) {
          removedLongManual.insert((*it)[0]);
        }
      }
    }
  }
  // Compute missing cases: present in removed but not re-added
  bool breakingByCases = false;
  for (const auto &c : removedCases) { if (addedCases.find(c) == addedCases.end()) { breakingByCases = true; break; } }
  r.removedLongCount = static_cast<int>(removedLongFromStruct.size());
  r.addedLongCount = static_cast<int>(addedLongFromStruct.size());
  r.manualRemovedLongCount = static_cast<int>(removedLongManual.size());
  r.manualAddedLongCount = static_cast<int>(addedLongManual.size());
  // Align with bash: breaking CLI based on removed switch-case labels only (more accurate)
  r.breakingCliChanges = breakingByCases;
  // If switch-case label analysis indicates removed options but struct/manual
  // extraction did not detect specific removed options, synthesize a minimal
  // removed-long signal to align with shell analyzer's removed-option bonus.
  if (breakingByCases && r.removedLongCount == 0 && r.manualRemovedLongCount == 0 && r.removedShortCount == 0) {
    r.removedLongCount = 1;
  }
  // Restrict manual CLI changes to explicit manual long option edits only.
  r.manualCliChanges = (r.manualAddedLongCount>0 || r.manualRemovedLongCount>0);
  r.helpTextChanges = 0;
  r.enhancedCliPatterns = 0;
  // Align CLI change flag with bash: treat any option set change or short removals as CLI changes
  r.cliChanges = r.breakingCliChanges
              || r.manualCliChanges
              || (r.addedLongCount>0)
              || (r.removedLongCount>0)
              || (r.removedShortCount>0);
  return r;
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
  // Mirror bash version-calculator rounding: the multiplier is rounded to
  // two decimals BEFORE multiplying by the base bonus, then the product is
  // rounded to the nearest integer. This avoids off-by-one drift vs. shell.
  int divisor = (bumpType=="patch") ? cfg.locDivisorPatch
               : (bumpType=="minor") ? cfg.locDivisorMinor
                                      : cfg.locDivisorMajor;

  // Raw multiplier 1 + LOC / divisor (non-negative, divisor guarded by config)
  double rawMultiplier = 1.0 + (divisor > 0 ? static_cast<double>(loc) / static_cast<double>(divisor) : 0.0);

  // Apply cap first (same as shell), then quantize to 2 decimals as shell does
  double capped = rawMultiplier;
  double cap = cfg.bonusMultiplierCap;
  if (capped > cap) capped = cap;

  // Quantize to 2 decimals via scale-100 integer rounding to replicate awk %.2f
  int scale100 = static_cast<int>(std::lround(capped * 100.0));
  double quantizedMultiplier = static_cast<double>(scale100) / 100.0;

  // Finally compute total bonus as round(baseBonus * quantizedMultiplier)
  double total = static_cast<double>(baseBonus) * quantizedMultiplier;
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

// Convert C++ analysis results to key-value format matching bash script outputs
Kv convertCliResultsToKv(const CliResults &results) {
  Kv kv;
  kv["CLI_CHANGES"] = results.cliChanges ? "true" : "false";
  kv["BREAKING_CLI_CHANGES"] = results.breakingCliChanges ? "true" : "false";
  kv["API_BREAKING"] = results.apiBreaking ? "true" : "false";
  kv["MANUAL_CLI_CHANGES"] = results.manualCliChanges ? "true" : "false";
  kv["MANUAL_ADDED_LONG_COUNT"] = std::to_string(results.manualAddedLongCount);
  kv["MANUAL_REMOVED_LONG_COUNT"] = std::to_string(results.manualRemovedLongCount);
  kv["REMOVED_SHORT_COUNT"] = std::to_string(results.removedShortCount);
  kv["ADDED_SHORT_COUNT"] = "0"; // Not implemented in C++ version yet
  kv["REMOVED_LONG_COUNT"] = std::to_string(results.removedLongCount);
  kv["ADDED_LONG_COUNT"] = std::to_string(results.addedLongCount);
  kv["GETOPT_CHANGES"] = "0"; // Not implemented in C++ version yet
  kv["ARG_PARSING_CHANGES"] = "0"; // Not implemented in C++ version yet
  kv["HELP_TEXT_CHANGES"] = std::to_string(results.helpTextChanges);
  kv["MAIN_SIGNATURE_CHANGES"] = "0"; // Not implemented in C++ version yet
  kv["ENHANCED_CLI_PATTERNS"] = std::to_string(results.enhancedCliPatterns);
  return kv;
}

Kv convertSecurityResultsToKv(const SecurityResults &results) {
  Kv kv;
  kv["SECURITY_KEYWORDS"] = std::to_string(results.securityKeywordsCommits);
  kv["SECURITY_PATTERNS"] = std::to_string(results.securityPatternsDiff);
  kv["CVE_PATTERNS"] = std::to_string(results.cvePatterns);
  kv["MEMORY_SAFETY_ISSUES"] = std::to_string(results.memorySafetyIssues);
  kv["CRASH_FIXES"] = std::to_string(results.crashFixes);
  
  // Calculate weighted total security score (matching bash script logic)
  int totalSecurityScore = results.securityKeywordsCommits * 1 +  // W_COMMITS = 1
                          results.securityPatternsDiff * 1 +      // W_DIFF_SEC = 1
                          results.cvePatterns * 3 +               // W_CVE = 3
                          results.memorySafetyIssues * 2 +        // W_MEM = 2
                          results.crashFixes * 1;                 // W_CRASH = 1
  
  kv["TOTAL_SECURITY_SCORE"] = std::to_string(totalSecurityScore);
  
  // Risk level calculation (matching bash script logic)
  std::string risk = "none";
  if (totalSecurityScore >= 15) risk = "high";
  else if (totalSecurityScore >= 5) risk = "medium";
  else if (totalSecurityScore >= 1) risk = "low";
  
  kv["RISK"] = risk;
  kv["WEIGHT_COMMITS"] = "1";
  kv["WEIGHT_DIFF_SEC"] = "1";
  kv["WEIGHT_CVE"] = "3";
  kv["WEIGHT_MEMORY"] = "2";
  kv["WEIGHT_CRASH"] = "1";
  kv["ENGINE"] = "pcre"; // C++ uses std::regex which is PCRE-like
  return kv;
}

Kv convertKeywordResultsToKv(const KeywordResults &results) {
  Kv kv;
  kv["CLI_BREAKING_KEYWORDS"] = "0"; // Not tracked separately in C++ version
  kv["API_BREAKING_KEYWORDS"] = "0"; // Not tracked separately in C++ version
  kv["COMMIT_CLI_BREAKING"] = "0"; // Not tracked separately in C++ version
  kv["COMMIT_API_BREAKING"] = "0"; // Not tracked separately in C++ version
  kv["COMMIT_GENERAL_BREAKING"] = "0"; // Not tracked separately in C++ version
  kv["TOTAL_CLI_BREAKING"] = results.hasCliBreaking ? "1" : "0";
  kv["TOTAL_API_BREAKING"] = results.hasApiBreaking ? "1" : "0";
  kv["TOTAL_GENERAL_BREAKING"] = results.hasGeneralBreaking ? "1" : "0";
  kv["NEW_FEATURE_KEYWORDS"] = "0"; // Not implemented in C++ version yet
  kv["COMMIT_NEW_FEATURE"] = "0"; // Not implemented in C++ version yet
  kv["TOTAL_NEW_FEATURES"] = "0"; // Not implemented in C++ version yet
  kv["SECURITY_KEYWORDS"] = "0"; // Not tracked separately in C++ version
  kv["COMMIT_SECURITY"] = "0"; // Not tracked separately in C++ version
  kv["TOTAL_SECURITY"] = std::to_string(results.totalSecurity);
  kv["REMOVED_OPTIONS_KEYWORDS"] = std::to_string(results.removedOptionsKeywords);
  kv["ADDED_OPTIONS_KEYWORDS"] = "0"; // Not implemented in C++ version yet
  kv["HAS_CLI_BREAKING"] = results.hasCliBreaking ? "true" : "false";
  kv["HAS_API_BREAKING"] = results.hasApiBreaking ? "true" : "false";
  kv["HAS_GENERAL_BREAKING"] = results.hasGeneralBreaking ? "true" : "false";
  kv["HAS_NEW_FEATURES"] = "false"; // Not implemented in C++ version yet
  kv["HAS_SECURITY"] = (results.totalSecurity > 0) ? "true" : "false";
  kv["HAS_REMOVED_OPTIONS"] = (results.removedOptionsKeywords > 0) ? "true" : "false";
  kv["HAS_ADDED_OPTIONS"] = "false"; // Not implemented in C++ version yet
  return kv;
}

}


