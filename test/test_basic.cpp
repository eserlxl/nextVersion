// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include <iostream>
#include <fstream>
#include <string>
#include <string_view>
#include <vector>
#include <cassert>
#include <sstream>
#include <regex>
#include "test_helpers.h"

// Simple test framework
// Remove TEST_ASSERT, TEST_PASS, trim, regex_replace_all, canon definitions

// Test helper functions (simplified versions of the main functions)
// Remove TEST_ASSERT, TEST_PASS, trim, regex_replace_all, canon definitions

// Add RAII file cleanup helper

bool test_version_reading() {
    // Test that version can be read from local VERSION file
    if (std::ifstream version_file("VERSION"); version_file) {
        std::string version;
        std::getline(version_file, version);
        TEST_ASSERT(!version.empty(), "Version should not be empty");
        TEST_PASS("Version file reading works");
        return true;
    } else {
        std::cout << "SKIP: VERSION file not found in current directory" << std::endl;
        return true;
    }
}

int main() {
    std::cout << "Running comprehensive tests for nextVersion..." << std::endl;
    
    bool all_passed = true;
    
    all_passed &= test_version_reading();
    
    if (all_passed) {
        std::cout << "\nAll tests passed!" << std::endl;
        return 0;
    } else {
        std::cout << "\nSome tests failed!" << std::endl;
        return 1;
    }
} 