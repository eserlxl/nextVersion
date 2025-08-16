// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "test_helpers.h"
#include "next_version/output_formatter.h"
#include "next_version/types.h"
#include <iostream>
#include <vector>
#include <string>
#include <cassert>
#include <sstream>

using namespace nv;

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
    
    std::string json_output = formatOutput(rr, stats, opts);
    
    // Basic validation that JSON output contains expected fields
    if (json_output.find("\"baseRef\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain baseRef field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"targetRef\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain targetRef field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"commitCount\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain commitCount field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"addedFiles\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain addedFiles field" << std::endl;
        exit(1);
    }
    
    if (json_output.find("\"insertions\"") == std::string::npos) {
        std::cerr << "FAIL: JSON output should contain insertions field" << std::endl;
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
    
    std::string machine_output = formatOutput(rr, stats, opts);
    
    // Machine output should be concise and parseable
    if (machine_output.empty()) {
        std::cerr << "FAIL: Machine output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain key information in a compact format
    if (machine_output.find("main") == std::string::npos) {
        std::cerr << "FAIL: Machine output should contain base ref" << std::endl;
        exit(1);
    }
    
    if (machine_output.find("feature") == std::string::npos) {
        std::cerr << "FAIL: Machine output should contain target ref" << std::endl;
        exit(1);
    }
    
    if (machine_output.find("5") == std::string::npos) {
        std::cerr << "FAIL: Machine output should contain commit count" << std::endl;
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
    
    std::string human_output = formatOutput(rr, stats, opts);
    
    // Human output should be descriptive and readable
    if (human_output.empty()) {
        std::cerr << "FAIL: Human output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain descriptive text
    if (human_output.find("Base ref") == std::string::npos && 
        human_output.find("base") == std::string::npos) {
        std::cerr << "FAIL: Human output should contain base ref information" << std::endl;
        exit(1);
    }
    
    if (human_output.find("Target ref") == std::string::npos && 
        human_output.find("target") == std::string::npos) {
        std::cerr << "FAIL: Human output should contain target ref information" << std::endl;
        exit(1);
    }
    
    if (human_output.find("Commits") == std::string::npos && 
        human_output.find("commit") == std::string::npos) {
        std::cerr << "FAIL: Human output should contain commit information" << std::endl;
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
    
    std::string empty_output = formatOutput(rr, stats, opts);
    
    // Should handle empty repository gracefully
    if (empty_output.empty()) {
        std::cerr << "FAIL: Empty repository output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should indicate empty repository
    if (empty_output.find("empty") == std::string::npos && 
        empty_output.find("no commits") == std::string::npos) {
        std::cerr << "FAIL: Empty repository output should indicate empty state" << std::endl;
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
    
    std::string single_output = formatOutput(rr, stats, opts);
    
    // Should handle single commit repository
    if (single_output.empty()) {
        std::cerr << "FAIL: Single commit repository output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should show appropriate information for single commit
    if (single_output.find("100") == std::string::npos) {
        std::cerr << "FAIL: Single commit output should show insertions" << std::endl;
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
    
    std::string large_output = formatOutput(rr, stats, opts);
    
    // Should handle large numbers gracefully
    if (large_output.empty()) {
        std::cerr << "FAIL: Large numbers output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain large numbers
    if (large_output.find("1000") == std::string::npos) {
        std::cerr << "FAIL: Large numbers output should show commit count" << std::endl;
        exit(1);
    }
    
    if (large_output.find("10000") == std::string::npos) {
        std::cerr << "FAIL: Large numbers output should show insertions" << std::endl;
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
    
    std::string verbose_output = formatOutput(rr, stats, opts);
    
    // Verbose output should be more detailed
    if (verbose_output.empty()) {
        std::cerr << "FAIL: Verbose output should not be empty" << std::endl;
        exit(1);
    }
    
    // Should contain more detailed information
    if (verbose_output.find("abc123") == std::string::npos) {
        std::cerr << "FAIL: Verbose output should show requested base SHA" << std::endl;
        exit(1);
    }
    
    if (verbose_output.find("def456") == std::string::npos) {
        std::cerr << "FAIL: Verbose output should show effective base SHA" << std::endl;
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
    
    std::string edge_output = formatOutput(rr, stats, opts);
    
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
    std::string output1 = formatOutput(rr, stats, opts);
    std::string output2 = formatOutput(rr, stats, opts);
    
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
