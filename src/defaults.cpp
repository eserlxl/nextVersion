// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "next_version/defaults.h"

namespace nv {

Kv makeDefaultFileKv() {
  return Kv{{"ADDED_FILES","0"},{"MODIFIED_FILES","0"},{"DELETED_FILES","0"},
            {"NEW_SOURCE_FILES","0"},{"NEW_TEST_FILES","0"},{"NEW_DOC_FILES","0"},
            {"DIFF_SIZE","0"}};
}

Kv makeDefaultCliKv() {
  return Kv{{"CLI_CHANGES","false"},{"BREAKING_CLI_CHANGES","false"},{"API_BREAKING","false"},
            {"MANUAL_CLI_CHANGES","false"},{"REMOVED_SHORT_COUNT","0"},{"REMOVED_LONG_COUNT","0"},
            {"MANUAL_ADDED_LONG_COUNT","0"},{"MANUAL_REMOVED_LONG_COUNT","0"}};
}

Kv makeDefaultSecurityKv() {
  return Kv{{"SECURITY_KEYWORDS","0"},{"SECURITY_PATTERNS","0"},{"CVE_PATTERNS","0"},
            {"MEMORY_SAFETY_ISSUES","0"},{"CRASH_FIXES","0"},{"TOTAL_SECURITY_SCORE","0"},
            {"WEIGHT_COMMITS","1"},{"WEIGHT_DIFF_SEC","1"},{"WEIGHT_CVE","3"},
            {"WEIGHT_MEMORY","2"},{"WEIGHT_CRASH","1"}};
}

Kv makeDefaultKeywordKv() {
  return Kv{{"HAS_CLI_BREAKING","false"},{"HAS_API_BREAKING","false"},{"TOTAL_SECURITY","0"},
            {"REMOVED_OPTIONS_KEYWORDS","0"}};
}

}


