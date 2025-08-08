// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of next-version and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.
#include "next_version/git_ops.h"
#include "next_version/git_helpers.h"
#include "next_version/util.h"

#include <sstream>
#include <vector>

namespace nv {

static bool isPrerelease(const std::string &v) {
  return v.find('-') != std::string::npos;
}

static int git(const std::vector<std::string> &args, const std::string &repoRoot, std::string &out) {
  return runGitCapture(args, repoRoot, out);
}

static bool hasStagedChanges(const std::string &repoRoot) {
  std::string out; // returns non-zero when there are staged changes
  int ec = runGitCapture({"diff","--cached","--quiet"}, repoRoot, out);
  return ec != 0;
}

static bool worktreeDirty(const std::string &repoRoot) {
  std::string out;
  int ec = runGitCapture({"status","--porcelain=v1"}, repoRoot, out);
  (void)ec;
  return !out.empty();
}

static bool branchIsDetached(const std::string &repoRoot) {
  std::string out;
  int ec = runGitCapture({"symbolic-ref","-q","HEAD"}, repoRoot, out);
  return ec != 0;
}

static std::string currentBranch(const std::string &repoRoot) {
  std::string out; runGitCapture({"rev-parse","--abbrev-ref","HEAD"}, repoRoot, out); return trim(out);
}

int performGitOperations(const GitOpsOptions &opts,
                        const std::string &repoRoot,
                        const std::string &newVersion,
                        const std::string &currentVersion) {
  // Basic preflight checks when committing/tagging/pushing
  if ((opts.doCommit || opts.doTag || opts.doPush || opts.pushTags) && branchIsDetached(repoRoot)) {
    std::fprintf(stderr, "Error: Detached HEAD; checkout a branch before continuing.\n");
    return 2;
  }

  // Stage VERSION unless prerelease
  if (!isPrerelease(newVersion)) {
    std::string out; int ec = git({"add","--","VERSION"}, repoRoot, out); (void)ec;
  }

  // Commit
  if (opts.doCommit && !isPrerelease(newVersion)) {
    if (!opts.allowDirty && worktreeDirty(repoRoot)) {
      std::fprintf(stderr, "Error: working tree has changes; use allowDirty to override.\n");
      return 3;
    }
    if (!hasStagedChanges(repoRoot)) {
      // Nothing to commit; not an error to keep parity with shell
    } else {
      std::vector<std::string> commitArgs = {"commit"};
      if (opts.noVerify) commitArgs.push_back("--no-verify");
      if (opts.signCommit) commitArgs.push_back("-S"); else commitArgs.push_back("--no-gpg-sign");

      std::ostringstream title;
      title << "chore(release): " << opts.tagPrefix << newVersion;
      commitArgs.push_back("-m"); commitArgs.push_back(title.str());
      if (currentVersion == "none") {
        commitArgs.push_back("-m"); commitArgs.push_back(std::string("bump: initial version ") + newVersion);
      } else if (!currentVersion.empty()) {
        commitArgs.push_back("-m"); commitArgs.push_back(std::string("bump: ") + currentVersion + " \342\206\222 " + newVersion);
      }
      if (!opts.commitMessage.empty()) { commitArgs.push_back("-m"); commitArgs.push_back(opts.commitMessage); }
      std::string out; int ec = git(commitArgs, repoRoot, out);
      if (ec != 0) { std::fprintf(stderr, "Error: git commit failed.\n"); return 4; }
    }
  }

  // Tag
  if (opts.doTag) {
    if (isPrerelease(newVersion)) {
      std::fprintf(stderr, "Error: Pre-release versions should not be tagged.\n");
      return 5;
    }
    const std::string tagName = opts.tagPrefix + newVersion;
    std::vector<std::string> tagArgs;
    if (opts.signedTag) tagArgs = {"tag","-s", tagName, "-m", std::string("Release ") + tagName};
    else if (opts.annotatedTag) tagArgs = {"tag","-a", tagName, "-m", std::string("Release ") + tagName};
    else tagArgs = {"tag", tagName};
    std::string out; int ec = git(tagArgs, repoRoot, out);
    if (ec != 0) { std::fprintf(stderr, "Error: git tag failed.\n"); return 6; }
  }

  // Push
  if (opts.doPush || opts.pushTags) {
    std::string branch = currentBranch(repoRoot);
    if (opts.doPush) {
      std::string out; int ec = git({"push", opts.remote, branch}, repoRoot, out);
      if (ec != 0) { std::fprintf(stderr, "Error: git push failed.\n"); return 7; }
    }
    if (opts.pushTags) {
      std::string out; int ec = git({"push", opts.remote, "--tags"}, repoRoot, out);
      if (ec != 0) { std::fprintf(stderr, "Error: git push --tags failed.\n"); return 8; }
    }
  }

  return 0;
}

}


