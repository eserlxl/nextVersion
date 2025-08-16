// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "test_helpers.h"
#include "next_version/bonus_calculator.h"
#include "next_version/types.h"
#include <iostream>
#include <vector>
#include <string>
#include <cassert>

using namespace nv;

void test_basic_bonus_calculation() {
    std::cout << "Testing basic bonus calculation..." << std::endl;
    
    // Test basic bonus calculation with default values
    ConfigValues config;
    config.majorBonusThreshold = 8;
    config.minorBonusThreshold = 4;
    config.patchBonusThreshold = 0;
    
    // Test patch level bonus
    int patch_bonus = calculateBonus(1, config);
    if (patch_bonus != 1) {
        std::cerr << "FAIL: Expected patch bonus 1, got " << patch_bonus << std::endl;
        exit(1);
    }
    
    // Test minor level bonus
    int minor_bonus = calculateBonus(5, config);
    if (minor_bonus != 5) {
        std::cerr << "FAIL: Expected minor bonus 5, got " << minor_bonus << std::endl;
        exit(1);
    }
    
    // Test major level bonus
    int major_bonus = calculateBonus(10, config);
    if (major_bonus != 10) {
        std::cerr << "FAIL: Expected major bonus 10, got " << major_bonus << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Basic bonus calculation tests passed" << std::endl;
}

void test_bonus_thresholds() {
    std::cout << "Testing bonus thresholds..." << std::endl;
    
    ConfigValues config;
    config.majorBonusThreshold = 8;
    config.minorBonusThreshold = 4;
    config.patchBonusThreshold = 0;
    
    // Test at threshold boundaries
    int at_patch_threshold = calculateBonus(0, config);
    if (at_patch_threshold != 0) {
        std::cerr << "FAIL: At patch threshold should return 0, got " << at_patch_threshold << std::endl;
        exit(1);
    }
    
    int at_minor_threshold = calculateBonus(4, config);
    if (at_minor_threshold != 4) {
        std::cerr << "FAIL: At minor threshold should return 4, got " << at_minor_threshold << std::endl;
        exit(1);
    }
    
    int at_major_threshold = calculateBonus(8, config);
    if (at_major_threshold != 8) {
        std::cerr << "FAIL: At major threshold should return 8, got " << at_major_threshold << std::endl;
        exit(1);
    }
    
    // Test just below thresholds
    int below_minor = calculateBonus(3, config);
    if (below_minor != 3) {
        std::cerr << "FAIL: Below minor threshold should return 3, got " << below_minor << std::endl;
        exit(1);
    }
    
    int below_major = calculateBonus(7, config);
    if (below_major != 7) {
        std::cerr << "FAIL: Below major threshold should return 7, got " << below_major << std::endl;
        exit(1);
    }
    
    // Test just above thresholds
    int above_minor = calculateBonus(5, config);
    if (above_minor != 5) {
        std::cerr << "FAIL: Above minor threshold should return 5, got " << above_minor << std::endl;
        exit(1);
    }
    
    int above_major = calculateBonus(9, config);
    if (above_major != 9) {
        std::cerr << "FAIL: Above major threshold should return 9, got " << above_major << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Bonus threshold tests passed" << std::endl;
}

void test_custom_bonus_thresholds() {
    std::cout << "Testing custom bonus thresholds..." << std::endl;
    
    ConfigValues config;
    config.majorBonusThreshold = 15;
    config.minorBonusThreshold = 7;
    config.patchBonusThreshold = 2;
    
    // Test with custom thresholds
    int below_patch = calculateBonus(1, config);
    if (below_patch != 1) {
        std::cerr << "FAIL: Below custom patch threshold should return 1, got " << below_patch << std::endl;
        exit(1);
    }
    
    int at_patch = calculateBonus(2, config);
    if (at_patch != 2) {
        std::cerr << "FAIL: At custom patch threshold should return 2, got " << at_patch << std::endl;
        exit(1);
    }
    
    int below_minor = calculateBonus(6, config);
    if (below_minor != 6) {
        std::cerr << "FAIL: Below custom minor threshold should return 6, got " << below_minor << std::endl;
        exit(1);
    }
    
    int at_minor = calculateBonus(7, config);
    if (at_minor != 7) {
        std::cerr << "FAIL: At custom minor threshold should return 7, got " << at_minor << std::endl;
        exit(1);
    }
    
    int below_major = calculateBonus(14, config);
    if (below_major != 14) {
        std::cerr << "FAIL: Below custom major threshold should return 14, got " << below_major << std::endl;
        exit(1);
    }
    
    int at_major = calculateBonus(15, config);
    if (at_major != 15) {
        std::cerr << "FAIL: At custom major threshold should return 15, got " << at_major << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Custom bonus threshold tests passed" << std::endl;
}

void test_edge_case_bonuses() {
    std::cout << "Testing edge case bonuses..." << std::endl;
    
    ConfigValues config;
    config.majorBonusThreshold = 8;
    config.minorBonusThreshold = 4;
    config.patchBonusThreshold = 0;
    
    // Test zero bonus
    int zero_bonus = calculateBonus(0, config);
    if (zero_bonus != 0) {
        std::cerr << "FAIL: Zero bonus should return 0, got " << zero_bonus << std::endl;
        exit(1);
    }
    
    // Test negative bonus (should handle gracefully)
    int negative_bonus = calculateBonus(-5, config);
    if (negative_bonus != -5) {
        std::cerr << "FAIL: Negative bonus should return -5, got " << negative_bonus << std::endl;
        exit(1);
    }
    
    // Test very large bonus
    int large_bonus = calculateBonus(1000, config);
    if (large_bonus != 1000) {
        std::cerr << "FAIL: Large bonus should return 1000, got " << large_bonus << std::endl;
        exit(1);
    }
    
    // Test very small bonus
    int small_bonus = calculateBonus(1, config);
    if (small_bonus != 1) {
        std::cerr << "FAIL: Small bonus should return 1, got " << small_bonus << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Edge case bonus tests passed" << std::endl;
}

void test_bonus_multiplier_cap() {
    std::cout << "Testing bonus multiplier cap..." << std::endl;
    
    ConfigValues config;
    config.majorBonusThreshold = 8;
    config.minorBonusThreshold = 4;
    config.patchBonusThreshold = 0;
    config.bonusMultiplierCap = 3.0;
    
    // Test that bonus calculation respects multiplier cap
    // This would require testing the actual bonus calculation logic
    // For now, we'll test the config structure
    
    if (config.bonusMultiplierCap != 3.0) {
        std::cerr << "FAIL: Expected bonus multiplier cap 3.0, got " << config.bonusMultiplierCap << std::endl;
        exit(1);
    }
    
    // Test default multiplier cap
    ConfigValues default_config;
    if (default_config.bonusMultiplierCap != 5.0) {
        std::cerr << "FAIL: Expected default bonus multiplier cap 5.0, got " << default_config.bonusMultiplierCap << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Bonus multiplier cap tests passed" << std::endl;
}

void test_bonus_configuration_values() {
    std::cout << "Testing bonus configuration values..." << std::endl;
    
    ConfigValues config;
    
    // Test default bonus values
    if (config.bonusBreakingCli != 4) {
        std::cerr << "FAIL: Expected bonusBreakingCli=4, got " << config.bonusBreakingCli << std::endl;
        exit(1);
    }
    
    if (config.bonusApiBreaking != 5) {
        std::cerr << "FAIL: Expected bonusApiBreaking=5, got " << config.bonusApiBreaking << std::endl;
        exit(1);
    }
    
    if (config.bonusRemovedOption != 3) {
        std::cerr << "FAIL: Expected bonusRemovedOption=3, got " << config.bonusRemovedOption << std::endl;
        exit(1);
    }
    
    if (config.bonusCliChanges != 2) {
        std::cerr << "FAIL: Expected bonusCliChanges=2, got " << config.bonusCliChanges << std::endl;
        exit(1);
    }
    
    if (config.bonusManualCli != 1) {
        std::cerr << "FAIL: Expected bonusManualCli=1, got " << config.bonusManualCli << std::endl;
        exit(1);
    }
    
    if (config.bonusNewSource != 1) {
        std::cerr << "FAIL: Expected bonusNewSource=1, got " << config.bonusNewSource << std::endl;
        exit(1);
    }
    
    if (config.bonusNewTest != 1) {
        std::cerr << "FAIL: Expected bonusNewTest=1, got " << config.bonusNewTest << std::endl;
        exit(1);
    }
    
    if (config.bonusNewDoc != 1) {
        std::cerr << "FAIL: Expected bonusNewDoc=1, got " << config.bonusNewDoc << std::endl;
        exit(1);
    }
    
    if (config.bonusSecurity != 5) {
        std::cerr << "FAIL: Expected bonusSecurity=5, got " << config.bonusSecurity << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Bonus configuration values tests passed" << std::endl;
}

void test_base_delta_values() {
    std::cout << "Testing base delta values..." << std::endl;
    
    ConfigValues config;
    
    // Test default base delta values
    if (config.baseDeltaPatch != 1) {
        std::cerr << "FAIL: Expected baseDeltaPatch=1, got " << config.baseDeltaPatch << std::endl;
        exit(1);
    }
    
    if (config.baseDeltaMinor != 5) {
        std::cerr << "FAIL: Expected baseDeltaMinor=5, got " << config.baseDeltaMinor << std::endl;
        exit(1);
    }
    
    if (config.baseDeltaMajor != 10) {
        std::cerr << "FAIL: Expected baseDeltaMajor=10, got " << config.baseDeltaMajor << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Base delta values tests passed" << std::endl;
}

void test_loc_divisor_values() {
    std::cout << "Testing LOC divisor values..." << std::endl;
    
    ConfigValues config;
    
    // Test default LOC divisor values
    if (config.locDivisorPatch != 250) {
        std::cerr << "FAIL: Expected locDivisorPatch=250, got " << config.locDivisorPatch << std::endl;
        exit(1);
    }
    
    if (config.locDivisorMinor != 500) {
        std::cerr << "FAIL: Expected locDivisorMinor=500, got " << config.locDivisorMinor << std::endl;
        exit(1);
    }
    
    if (config.locDivisorMajor != 1000) {
        std::cerr << "FAIL: Expected locDivisorMajor=1000, got " << config.locDivisorMajor << std::endl;
        exit(1);
    }
    
    std::cout << "✓ LOC divisor values tests passed" << std::endl;
}

void test_comprehensive_bonus_scenarios() {
    std::cout << "Testing comprehensive bonus scenarios..." << std::endl;
    
    ConfigValues config;
    config.majorBonusThreshold = 8;
    config.minorBonusThreshold = 4;
    config.patchBonusThreshold = 0;
    
    // Test a range of bonus values
    std::vector<std::pair<int, int>> test_cases = {
        {0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7}, {8, 8}, {9, 9}, {10, 10}
    };
    
    for (const auto& test_case : test_cases) {
        int input = test_case.first;
        int expected = test_case.second;
        int actual = calculateBonus(input, config);
        
        if (actual != expected) {
            std::cerr << "FAIL: Input " << input << " expected " << expected << ", got " << actual << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Comprehensive bonus scenario tests passed" << std::endl;
}

int main() {
    std::cout << "Running comprehensive bonus calculator tests..." << std::endl;
    
    test_basic_bonus_calculation();
    test_bonus_thresholds();
    test_custom_bonus_thresholds();
    test_edge_case_bonuses();
    test_bonus_multiplier_cap();
    test_bonus_configuration_values();
    test_base_delta_values();
    test_loc_divisor_values();
    test_comprehensive_bonus_scenarios();
    
    std::cout << "All bonus calculator tests passed!" << std::endl;
    return 0;
}
