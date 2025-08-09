#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generator module: add_optional_variant_unit

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../nv-common.sh"

add_optional_variant_unit() {
  mkdir -p src
  local f="src/optvar_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <variant>
#include <optional>
#include <string>
#include <cstdint>
static int visit_it(const std::variant<int,std::string>& v){
  return std::visit([](auto&& x)->int{
    using T=std::decay_t<decltype(x)>;
    if constexpr(std::is_same_v<T,int>) return x*2;
    else return static_cast<int>(x.size());
  }, v);
}
int optvar_probe(){
  std::optional<std::variant<int,std::string>> ov;
  if ((sizeof(void*)%2)==0) ov = std::variant<int,std::string>{42};
  else ov = std::variant<int,std::string>{std::string("x")};
  return visit_it(*ov);
}
EOF
}


