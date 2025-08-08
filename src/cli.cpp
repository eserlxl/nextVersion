// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of next-version and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.
#include "next_version/cli.h"

#include <cstdlib>
#include <iostream>

namespace nv {

void showHelp() {
  std::cout <<
R"HELP(Semantic Version Analyzer v2 for next-version

Usage: semantic-version-analyzer [options]

Options:
  --since <tag>            Analyze changes since specific tag (default: last tag)
  --since-tag <tag>        Alias for --since
  --since-commit <hash>    Analyze changes since specific commit
  --since-date <date>      Analyze changes since specific date (YYYY-MM-DD)
  --base <ref>             Set base reference for comparison (default: auto-detected)
  --target <ref>           Set target reference for comparison (default: HEAD)
  --repo-root <path>       Set repository root directory for analysis
  --no-merge-base          Disable automatic merge-base detection for disjoint branches
  --only-paths <globs>     Restrict analysis to comma-separated path globs
  --ignore-whitespace      Ignore whitespace changes in diff analysis
  --verbose                Show detailed progress and debug lines on stderr
  --machine                Output machine-readable key=value (top-level result)
  --json                   Output machine-readable JSON (top-level result)
  --suggest-only           Output only the suggestion (major/minor/patch/none)
  --strict-status          Use strict exit codes even with --suggest-only
 (bypasses trivial repo checks)
  
Git operations (optional):
  --commit                 Create a commit with VERSION update (skipped for prerelease)
  --tag                    Create a git tag (skipped for prerelease)
  --push                   Push branch to remote (default: origin)
  --push-tags              Push all tags to remote
  --allow-dirty            Allow dirty working tree when committing/tagging
  --sign-commit            Sign the commit (-S)
  --lightweight-tag        Create a lightweight tag instead of annotated
  --signed-tag             Create a signed tag
  --no-verify              Skip git hooks on commit
  --remote <name>          Remote name (default: origin)
  --tag-prefix <pfx>       Tag prefix (default: v)
  --message <msg>          Extra commit message paragraph
  --help, -h               Show this help
)HELP";
}

Options parseArgs(int argc, char **argv) {
  Options opts;
  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    auto needValue = [&](const char *opt) {
      if (i + 1 >= argc || argv[i + 1][0] == '-') {
        std::cerr << "Error: " << opt << " requires a value\n";
        std::exit(1);
      }
      return std::string(argv[++i]);
    };

    if (arg == "--since" || arg == "--since-tag") opts.sinceTag = needValue(arg.c_str());
    else if (arg == "--since-commit") opts.sinceCommit = needValue(arg.c_str());
    else if (arg == "--since-date") opts.sinceDate = needValue(arg.c_str());
    else if (arg == "--base") opts.baseRef = needValue(arg.c_str());
    else if (arg == "--target") opts.targetRef = needValue(arg.c_str());
    else if (arg == "--repo-root") opts.repoRoot = needValue(arg.c_str());
    else if (arg == "--no-merge-base") opts.noMergeBase = true;
    else if (arg == "--only-paths") opts.onlyPaths = needValue(arg.c_str());
    else if (arg == "--ignore-whitespace") opts.ignoreWhitespace = true;
    else if (arg == "--verbose") opts.verbose = true;
    else if (arg == "--machine") opts.machine = true;
    else if (arg == "--json") opts.json = true;
    else if (arg == "--suggest-only") opts.suggestOnly = true;
    else if (arg == "--strict-status") opts.strictStatus = true;
    // Git operations
    else if (arg == "--commit") opts.doCommit = true;
    else if (arg == "--tag") opts.doTag = true;
    else if (arg == "--push") opts.doPush = true;
    else if (arg == "--push-tags") opts.pushTags = true;
    else if (arg == "--allow-dirty") opts.allowDirty = true;
    else if (arg == "--sign-commit") opts.signCommit = true;
    else if (arg == "--lightweight-tag") opts.annotatedTag = false;
    else if (arg == "--signed-tag") opts.signedTag = true;
    else if (arg == "--no-verify") opts.noVerify = true;
    else if (arg == "--remote") opts.remote = needValue(arg.c_str());
    else if (arg == "--tag-prefix") opts.tagPrefix = needValue(arg.c_str());
    else if (arg == "--message") opts.commitMessage = needValue(arg.c_str());
    else if (arg == "--help" || arg == "-h") { showHelp(); std::exit(0); }
    else {
      std::cerr << "Error: Unknown option: " << arg << "\n";
      std::exit(1);
    }
  }
  return opts;
}

}


