// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.
//
// Common test macros and helpers for nextVersion tests
#pragma once
#include <iostream>
#include <string>
#include <string_view>
#include <regex>
#include <fstream>
#include <filesystem>

#define TEST_ASSERT(condition, message) \
    do { \
        if (!(condition)) { \
            std::cerr << "FAIL: " << message << std::endl; \
            return false; \
        } \
    } while(0)

#define TEST_PASS(message) \
    do { \
        std::cout << "PASS: " << message << std::endl; \
    } while(0)

inline std::string trim(std::string_view s) {
    auto start = s.find_first_not_of(" \t\r\n");
    if (start == std::string_view::npos) return "";
    auto end = s.find_last_not_of(" \t\r\n");
    return std::string(s.substr(start, end - start + 1));
}

class TempFile {
public:
    explicit TempFile(const char* filename, std::ios::openmode mode = std::ios::out) 
        : path_(std::string("/tmp/") + filename), stream_(path_, mode) {}
    
    ~TempFile() { 
        stream_.close();
        std::remove(path_.c_str()); 
    }
    
    std::ofstream& get_stream() { return stream_; }
    const char* path() const { return path_.c_str(); }
    void write(const std::string& content) { stream_ << content; }
    void close() { stream_.close(); }
    void flush() { stream_.flush(); }
    
private:
    std::string path_;
    std::ofstream stream_;
};