// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "../test_helpers.h"
#include "next_version/output_formatter.h"
#include "next_version/types.h"
#include <iostream>
#include <vector>
#include <string>
#include <cassert>
#include <sstream>

using namespace nv;

// Helper function to call formatOutput with proper parameters
std::string formatOutputHelper(const RefResolution& rr, const FileChangeStats& stats, const Options& opts) {
    // Create default values for missing parameters
    std::string suggestion = "patch";
    std::string currentVersion = "1.0.0";
    std::string nextVersion = "1.0.1";
    int totalBonus = 1;
    Kv CLI;
    ConfigValues cfg;
    int loc = stats.insertions + stats.deletions;
    
    // Redirect stdout to capture the output
    std::stringstream buffer;
    std::streambuf* old = std::cout.rdbuf(buffer.rdbuf());
    
    // Call the actual formatOutput function
    formatOutput(opts, suggestion, currentVersion, nextVersion, totalBonus, CLI, rr.baseRef, rr.targetRef, cfg, loc);
    
    // Restore stdout and get the captured output
    std::cout.rdbuf(old);
    return buffer.str();
}

void test_json_output_formatting() {
    std::cout << "Testing JSON output formatting..." << std::endl;
    
    // Test basic JSON formatting
    Options opts;
    opts.json = true;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "main";
    rr.targetRef = "feature";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "def456";
    rr.commitCount = 5;
    
    FileChangeStats stats;
    stats.addedFiles = 2;
    stats.modifiedFiles = 3;
    stats.deletedFiles = 1;
    stats.newSourceFiles = 1;
    stats.newTestFiles = 1;
    stats.newDocFiles = 0;
    stats.insertions = 50;
    stats.deletions = 10;
    
    std::string json_output = formatOutputHelper(rr, stats, opts);
    
    // Basic validation that JSON output contains expected fields
    if (json_output.find("\"base_ref\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain base_ref field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"target_ref\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain target_ref field" << std::endl;
        exit(1);
    }
    
    // Note: commitCount is not in the actual output, it's in the RefResolution struct
    // The actual output contains loc_delta information instead
    
    if (json_output.find("\"loc_delta\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain loc_delta field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"patch_delta\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain patch_delta field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"minor_delta\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain minor_delta field" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ JSON output formatting tests passed" << std::endl;
}

void test_machine_output_formatting() {
    std::cout << "Testing machine output formatting..." << std::endl;
    
    // Test machine-readable output
    Options opts;
    opts.json = false;
    opts.machine = true;
    
    RefResolution rr;
    rr.baseRef = "main";
    rr.targetRef = "feature";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "def456";
    rr.commitCount = 5;
    
    FileChangeStats stats;
    stats.addedFiles = 2;
    stats.modifiedFiles = 3;
    stats.deletedFiles = 1;
    stats.newSourceFiles = 1;
    stats.newTestFiles = 1;
    stats.newDocFiles = 0;
    stats.insertions = 50;
    stats.deletions = 10;
    
    std::string machine_output = formatOutputHelper(rr, stats, opts);
    
    // Machine output should be concise and parseable
    if (machine_output.empty()) {
        std::cerr << "FAIL: Machine output should not be empty" << std::endl;
        exit(1);
    }
    
    // Machine output should contain only the suggestion in key=value format
    if (machine_output.find("SUGGESTION=") == std::string::npos) {
        std::cerr << "FAIL: Machine output should contain SUGGESTION= field" << std::endl;
        exit(1);
    }
    
    if (machine_output.find("patch") == std::string::npos) {
        std::cerr << "FAIL: Machine output should contain the suggestion value" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Machine output formatting tests passed" << std::endl;
}

void test_human_readable_output_formatting() {
    std::cout << "Testing human readable output formatting..." << std::endl;
    
    // Test human-readable output (default)
    Options opts;
    opts.json = false;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "main";
    rr.targetRef = "feature";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "def456";
    rr.commitCount = 5;
    
    FileChangeStats stats;
    stats.addedFiles = 2;
    stats.modifiedFiles = 3;
    stats.deletedFiles = 1;
    stats.newSourceFiles = 1;
    stats.newTestFiles = 1;
    stats.newDocFiles = 0;
    stats.insertions = 50;
    stats.deletions = 10;
    
    std::string human_output = formatOutputHelper(rr, stats, opts);
    
    // Human output should be descriptive and readable
    if (human_output.empty()) {
        std::cerr << "FAIL: Human output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain descriptive text
    if (human_output.find("main") == std::string::npos) {
        std::cerr << "FAIL: Human output should contain base ref information" << std::endl;
        exit(1);
    }
    
    if (human_output.find("feature") == std::string::npos) {
        std::cerr << "FAIL: Human output should contain target ref information" << std::endl;
        exit(1);
    }
    
    if (human_output.find("Analyzing changes:") == std::string::npos) {
        std::cerr << "FAIL: Human output should contain change analysis information" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Human readable output formatting tests passed" << std::endl;
}

void test_empty_repository_output() {
    std::cout << "Testing empty repository output..." << std::endl;
    
    Options opts;
    opts.json = false;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "";
    rr.targetRef = "HEAD";
    rr.hasCommits = false;
    rr.emptyRepo = true;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "";
    rr.effectiveBaseSha = "";
    rr.commitCount = 0;
    
    FileChangeStats stats;
    stats.addedFiles = 0;
    stats.modifiedFiles = 0;
    stats.deletedFiles = 0;
    stats.newSourceFiles = 0;
    stats.newTestFiles = 0;
    stats.newDocFiles = 0;
    stats.insertions = 0;
    stats.deletions = 0;
    
    std::string empty_output = formatOutputHelper(rr, stats, opts);
    
    // Should handle empty repository gracefully
    if (empty_output.empty()) {
        std::cerr << "FAIL: Empty repository output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain basic output structure even for empty repository
    if (empty_output.find("=== Semantic Version Analysis v2 ===") == std::string::npos) {
        std::cerr << "FAIL: Empty repository output should contain analysis header" << std::endl;
        exit(1);
    }
    
    if (empty_output.find("SUGGESTION=") == std::string::npos) {
        std::cerr << "FAIL: Empty repository output should contain suggestion" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Empty repository output tests passed" << std::endl;
}

void test_single_commit_repository_output() {
    std::cout << "Testing single commit repository output..." << std::endl;
    
    Options opts;
    opts.json = false;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "abc123";
    rr.targetRef = "HEAD";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = true;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "abc123";
    rr.commitCount = 0;
    
    FileChangeStats stats;
    stats.addedFiles = 1;
    stats.modifiedFiles = 0;
    stats.deletedFiles = 0;
    stats.newSourceFiles = 1;
    stats.newTestFiles = 0;
    stats.newDocFiles = 0;
    stats.insertions = 100;
    stats.deletions = 0;
    
    std::string single_output = formatOutputHelper(rr, stats, opts);
    
    // Should handle single commit repository
    if (single_output.empty()) {
        std::cerr << "FAIL: Single commit repository output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should show appropriate information for single commit
    if (single_output.find("SUGGESTION=") == std::string::npos) {
        std::cerr << "FAIL: Single commit output should show suggestion" << std::endl;
        exit(1);
    }
    
    if (single_output.find("=== Semantic Version Analysis v2 ===") == std::string::npos) {
        std::cerr << "FAIL: Single commit output should show analysis header" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Single commit repository output tests passed" << std::endl;
}

void test_large_numbers_output() {
    std::cout << "Testing large numbers output..." << std::endl;
    
    Options opts;
    opts.json = false;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "main";
    rr.targetRef = "feature";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "def456";
    rr.commitCount = 1000;
    
    FileChangeStats stats;
    stats.addedFiles = 100;
    stats.modifiedFiles = 200;
    stats.deletedFiles = 50;
    stats.newSourceFiles = 50;
    stats.newTestFiles = 30;
    stats.newDocFiles = 20;
    stats.insertions = 10000;
    stats.deletions = 5000;
    
    std::string large_output = formatOutputHelper(rr, stats, opts);
    
    // Should handle large numbers gracefully
    if (large_output.empty()) {
        std::cerr << "FAIL: Large numbers output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain basic output structure
    if (large_output.find("=== Semantic Version Analysis v2 ===") == std::string::npos) {
        std::cerr << "FAIL: Large numbers output should show analysis header" << std::endl;
        exit(1);
    }
    
    if (large_output.find("SUGGESTION=") == std::string::npos) {
        std::cerr << "FAIL: Large numbers output should show suggestion" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Large numbers output tests passed" << std::endl;
}

void test_verbose_output_formatting() {
    std::cout << "Testing verbose output formatting..." << std::endl;
    
    Options opts;
    opts.json = false;
    opts.machine = false;
    opts.verbose = true;
    
    RefResolution rr;
    rr.baseRef = "main";
    rr.targetRef = "feature";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "def456";
    rr.commitCount = 5;
    
    FileChangeStats stats;
    stats.addedFiles = 2;
    stats.modifiedFiles = 3;
    stats.deletedFiles = 1;
    stats.newSourceFiles = 1;
    stats.newTestFiles = 1;
    stats.newDocFiles = 0;
    stats.insertions = 50;
    stats.deletions = 10;
    
    std::string verbose_output = formatOutputHelper(rr, stats, opts);
    
    // Verbose output should be more detailed
    if (verbose_output.empty()) {
        std::cerr << "FAIL: Verbose output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain basic output structure
    if (verbose_output.find("=== Semantic Version Analysis v2 ===") == std::string::npos) {
        std::cerr << "FAIL: Verbose output should show analysis header" << std::endl;
        exit(1);
    }
    
    if (verbose_output.find("SUGGESTION=") == std::string::npos) {
        std::cerr << "FAIL: Verbose output should show suggestion" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Verbose output formatting tests passed" << std::endl;
}

void test_edge_case_outputs() {
    std::cout << "Testing edge case outputs..." << std::endl;
    
    // Test with all zero values
    Options opts;
    opts.json = false;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "";
    rr.targetRef = "";
    rr.hasCommits = false;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "";
    rr.effectiveBaseSha = "";
    rr.commitCount = 0;
    
    FileChangeStats stats;
    stats.addedFiles = 0;
    stats.modifiedFiles = 0;
    stats.deletedFiles = 0;
    stats.newSourceFiles = 0;
    stats.newTestFiles = 0;
    stats.newDocFiles = 0;
    stats.insertions = 0;
    stats.deletions = 0;
    
    std::string edge_output = formatOutputHelper(rr, stats, opts);
    
    // Should handle edge cases gracefully
    if (edge_output.empty()) {
        std::cerr << "FAIL: Edge case output should not be empty" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Edge case output tests passed" << std::endl;
}

void test_output_format_consistency() {
    std::cout << "Testing output format consistency..." << std::endl;
    
    Options opts;
    opts.json = false;
    opts.machine = false;
    
    RefResolution rr;
    rr.baseRef = "main";
    rr.targetRef = "feature";
    rr.hasCommits = true;
    rr.emptyRepo = false;
    rr.singleCommitRepo = false;
    rr.requestedBaseSha = "abc123";
    rr.effectiveBaseSha = "def456";
    rr.commitCount = 5;
    
    FileChangeStats stats;
    stats.addedFiles = 2;
    stats.modifiedFiles = 3;
    stats.deletedFiles = 1;
    stats.newSourceFiles = 1;
    stats.newTestFiles = 1;
    stats.newDocFiles = 0;
    stats.insertions = 50;
    stats.deletions = 10;
    
    // Test multiple calls produce consistent output
    std::string output1 = formatOutputHelper(rr, stats, opts);
    std::string output2 = formatOutputHelper(rr, stats, opts);
    
    if (output1 != output2) {
        std::cerr << "FAIL: Multiple calls should produce identical output" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Output format consistency tests passed" << std::endl;
}

int main() {
    std::cout << "Running comprehensive output formatter tests..." << std::endl;
    
    test_json_output_formatting();
    test_machine_output_formatting();
    test_human_readable_output_formatting();
    test_empty_repository_output();
    test_single_commit_repository_output();
    test_large_numbers_output();
    test_verbose_output_formatting();
    test_edge_case_outputs();
    test_output_format_consistency();
    
    std::cout << "All output formatter tests passed!" << std::endl;
    return 0;
}
