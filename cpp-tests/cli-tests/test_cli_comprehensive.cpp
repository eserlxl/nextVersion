// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the LICENSE file in the project root for details.

#include "test_helpers.h"
#include "next_version/cli.h"
#include "next_version/types.h"
#include <iostream>
#include <vector>
#include <string>
#include <cassert>

using namespace nv;

void test_cli_parsing_basic() {
    std::cout << "Testing basic CLI parsing..." << std::endl;
    
    // Test basic help argument
    std::vector<std::string> help_args = {"program", "--help"};
    Options opts = parseCommandLine(help_args);
    
    // Note: We can't directly test the help flag since it's handled in main
    // But we can verify the parsing doesn't crash
    
    // Test version argument
    std::vector<std::string> version_args = {"program", "--version"};
    Options opts2 = parseCommandLine(version_args);
    
    // Test verbose argument
    std::vector<std::string> verbose_args = {"program", "--verbose"};
    Options opts3 = parseCommandLine(verbose_args);
    
    if (!opts3.verbose) {
        std::cerr << "FAIL: --verbose should set verbose flag" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Basic CLI parsing tests passed" << std::endl;
}

void test_cli_parsing_repo_options() {
    std::cout << "Testing CLI parsing with repo options..." << std::endl;
    
    // Test repo root
    std::vector<std::string> repo_args = {"program", "--repo-root", "/path/to/repo"};
    Options opts = parseCommandLine(repo_args);
    
    if (opts.repoRoot != "/path/to/repo") {
        std::cerr << "FAIL: Expected repo root /path/to/repo, got " << opts.repoRoot << std::endl;
        exit(1);
    }
    
    // Test base ref
    std::vector<std::string> base_args = {"program", "--base-ref", "main"};
    Options opts2 = parseCommandLine(base_args);
    
    if (opts2.baseRef != "main") {
        std::cerr << "FAIL: Expected base ref main, got " << opts2.baseRef << std::endl;
        exit(1);
    }
    
    // Test target ref
    std::vector<std::string> target_args = {"program", "--target-ref", "feature"};
    Options opts3 = parseCommandLine(target_args);
    
    if (opts3.targetRef != "feature") {
        std::cerr << "FAIL: Expected target ref feature, got " << opts3.targetRef << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with repo options tests passed" << std::endl;
}

void test_cli_parsing_since_options() {
    std::cout << "Testing CLI parsing with since options..." << std::endl;
    
    // Test since tag
    std::vector<std::string> tag_args = {"program", "--since-tag", "v1.0.0"};
    Options opts = parseCommandLine(tag_args);
    
    if (opts.sinceTag != "v1.0.0") {
        std::cerr << "FAIL: Expected since tag v1.0.0, got " << opts.sinceTag << std::endl;
        exit(1);
    }
    
    // Test since commit
    std::vector<std::string> commit_args = {"program", "--since-commit", "abc123"};
    Options opts2 = parseCommandLine(commit_args);
    
    if (opts2.sinceCommit != "abc123") {
        std::cerr << "FAIL: Expected since commit abc123, got " << opts2.sinceCommit << std::endl;
        exit(1);
    }
    
    // Test since date
    std::vector<std::string> date_args = {"program", "--since-date", "2024-01-01"};
    Options opts3 = parseCommandLine(date_args);
    
    if (opts3.sinceDate != "2024-01-01") {
        std::cerr << "FAIL: Expected since date 2024-01-01, got " << opts3.sinceDate << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with since options tests passed" << std::endl;
}

void test_cli_parsing_git_options() {
    std::cout << "Testing CLI parsing with git options..." << std::endl;
    
    // Test tag match
    std::vector<std::string> tag_match_args = {"program", "--tag-match", "v*"};
    Options opts = parseCommandLine(tag_match_args);
    
    if (opts.tagMatch != "v*") {
        std::cerr << "FAIL: Expected tag match v*, got " << opts.tagMatch << std::endl;
        exit(1);
    }
    
    // Test first parent
    std::vector<std::string> first_parent_args = {"program", "--first-parent"};
    Options opts2 = parseCommandLine(first_parent_args);
    
    if (!opts2.firstParent) {
        std::cerr << "FAIL: --first-parent should set firstParent flag" << std::endl;
        exit(1);
    }
    
    // Test no merge base
    std::vector<std::string> no_merge_base_args = {"program", "--no-merge-base"};
    Options opts3 = parseCommandLine(no_merge_base_args);
    
    if (!opts3.noMergeBase) {
        std::cerr << "FAIL: --no-merge-base should set noMergeBase flag" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with git options tests passed" << std::endl;
}

void test_cli_parsing_output_options() {
    std::cout << "Testing CLI parsing with output options..." << std::endl;
    
    // Test machine output
    std::vector<std::string> machine_args = {"program", "--machine"};
    Options opts = parseCommandLine(machine_args);
    
    if (!opts.machine) {
        std::cerr << "FAIL: --machine should set machine flag" << std::endl;
        exit(1);
    }
    
    // Test JSON output
    std::vector<std::string> json_args = {"program", "--json"};
    Options opts2 = parseCommandLine(json_args);
    
    if (!opts2.json) {
        std::cerr << "FAIL: --json should set json flag" << std::endl;
        exit(1);
    }
    
    // Test suggest only
    std::vector<std::string> suggest_args = {"program", "--suggest-only"};
    Options opts3 = parseCommandLine(suggest_args);
    
    if (!opts3.suggestOnly) {
        std::cerr << "FAIL: --suggest-only should set suggestOnly flag" << std::endl;
        exit(1);
    }
    
    // Test strict status
    std::vector<std::string> strict_args = {"program", "--strict-status"};
    Options opts4 = parseCommandLine(strict_args);
    
    if (!opts4.strictStatus) {
        std::cerr << "FAIL: --strict-status should set strictStatus flag" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with output options tests passed" << std::endl;
}

void test_cli_parsing_git_operation_options() {
    std::cout << "Testing CLI parsing with git operation options..." << std::endl;
    
    // Test do commit
    std::vector<std::string> commit_args = {"program", "--do-commit"};
    Options opts = parseCommandLine(commit_args);
    
    if (!opts.doCommit) {
        std::cerr << "FAIL: --do-commit should set doCommit flag" << std::endl;
        exit(1);
    }
    
    // Test do tag
    std::vector<std::string> tag_args = {"program", "--do-tag"};
    Options opts2 = parseCommandLine(tag_args);
    
    if (!opts2.doTag) {
        std::cerr << "FAIL: --do-tag should set doTag flag" << std::endl;
        exit(1);
    }
    
    // Test do push
    std::vector<std::string> push_args = {"program", "--do-push"};
    Options opts3 = parseCommandLine(push_args);
    
    if (!opts3.doPush) {
        std::cerr << "FAIL: --do-push should set doPush flag" << std::endl;
        exit(1);
    }
    
    // Test push tags
    std::vector<std::string> push_tags_args = {"program", "--push-tags"};
    Options opts4 = parseCommandLine(push_tags_args);
    
    if (!opts4.pushTags) {
        std::cerr << "FAIL: --push-tags should set pushTags flag" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with git operation options tests passed" << std::endl;
}

void test_cli_parsing_advanced_options() {
    std::cout << "Testing CLI parsing with advanced options..." << std::endl;
    
    // Test allow dirty
    std::vector<std::string> dirty_args = {"program", "--allow-dirty"};
    Options opts = parseCommandLine(dirty_args);
    
    if (!opts.allowDirty) {
        std::cerr << "FAIL: --allow-dirty should set allowDirty flag" << std::endl;
        exit(1);
    }
    
    // Test sign commit
    std::vector<std::string> sign_args = {"program", "--sign-commit"};
    Options opts2 = parseCommandLine(sign_args);
    
    if (!opts2.signCommit) {
        std::cerr << "FAIL: --sign-commit should set signCommit flag" << std::endl;
        exit(1);
    }
    
    // Test annotated tag
    std::vector<std::string> annotated_args = {"program", "--annotated-tag"};
    Options opts3 = parseCommandLine(annotated_args);
    
    if (!opts3.annotatedTag) {
        std::cerr << "FAIL: --annotated-tag should set annotatedTag flag" << std::endl;
        exit(1);
    }
    
    // Test signed tag
    std::vector<std::string> signed_args = {"program", "--signed-tag"};
    Options opts4 = parseCommandLine(signed_args);
    
    if (!opts4.signedTag) {
        std::cerr << "FAIL: --signed-tag should set signedTag flag" << std::endl;
        exit(1);
    }
    
    // Test no verify
    std::vector<std::string> no_verify_args = {"program", "--no-verify"};
    Options opts5 = parseCommandLine(no_verify_args);
    
    if (!opts5.noVerify) {
        std::cerr << "FAIL: --no-verify should set noVerify flag" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with advanced options tests passed" << std::endl;
}

void test_cli_parsing_combined_options() {
    std::cout << "Testing CLI parsing with combined options..." << std::endl;
    
    // Test multiple options together
    std::vector<std::string> combined_args = {
        "program", "--verbose", "--repo-root", "/path/to/repo",
        "--base-ref", "main", "--target-ref", "feature",
        "--machine", "--json"
    };
    
    Options opts = parseCommandLine(combined_args);
    
    if (!opts.verbose) {
        std::cerr << "FAIL: Combined options should set verbose flag" << std::endl;
        exit(1);
    }
    
    if (opts.repoRoot != "/path/to/repo") {
        std::cerr << "FAIL: Combined options should set repo root" << std::endl;
        exit(1);
    }
    
    if (opts.baseRef != "main") {
        std::cerr << "FAIL: Combined options should set base ref" << std::endl;
        exit(1);
    }
    
    if (opts.targetRef != "feature") {
        std::cerr << "FAIL: Combined options should set target ref" << std::endl;
        exit(1);
    }
    
    if (!opts.machine) {
        std::cerr << "FAIL: Combined options should set machine flag" << std::endl;
        exit(1);
    }
    
    if (!opts.json) {
        std::cerr << "FAIL: Combined options should set json flag" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ CLI parsing with combined options tests passed" << std::endl;
}

void test_edge_cases() {
    std::cout << "Testing edge cases..." << std::endl;
    
    // Test empty argument vector
    std::vector<std::string> empty_args;
    Options opts = parseCommandLine(empty_args);
    
    // Test single argument (program name only)
    std::vector<std::string> single_args = {"program"};
    Options opts2 = parseCommandLine(single_args);
    
    // Test with empty string values
    std::vector<std::string> empty_values = {"program", "--repo-root", ""};
    Options opts3 = parseCommandLine(empty_values);
    
    if (opts3.repoRoot != "") {
        std::cerr << "FAIL: Empty repo root should be preserved" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Edge case tests passed" << std::endl;
}

int main() {
    std::cout << "Running comprehensive CLI tests..." << std::endl;
    
    test_cli_parsing_basic();
    test_cli_parsing_repo_options();
    test_cli_parsing_since_options();
    test_cli_parsing_git_options();
    test_cli_parsing_output_options();
    test_cli_parsing_git_operation_options();
    test_cli_parsing_advanced_options();
    test_cli_parsing_combined_options();
    test_edge_cases();
    
    std::cout << "All CLI tests passed!" << std::endl;
    return 0;
}
