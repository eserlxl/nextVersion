#!/usr/bin/env bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# nv-generators: content generators for random repositories

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=nv-common.sh
source "${SCRIPT_DIR}/nv-common.sh"

# ---- tiny utils (auxiliary, non-breaking) ----
_whence()  { command -v -- "$1" >/dev/null 2>&1; }
_jitter()  { sleep "0.$((RANDOM%7))" 2>/dev/null || true; }
# 1 in N chance helper (defaults to N=2)
_one_in()  { local n="${1:-2}"; (( n<1 )) && n=1; (( RANDOM % n == 0 )); }
_rpick()   { if (($#>0)); then rand_pick "$@"; else printf '%s' "a"; fi }

# ---- content helpers ----
# Introduce controlled whitespace noise, or normalize, randomly.
# Uses /tmp for temp files per project rules.
whitespace_nudge() {
  local f=${1:?file}
  if (( $(rand_bool 33) )); then
    sed -E -i 's/[[:space:]]+/ /g' "$f" || true
  else
    local tmp
    tmp="$(mktemp /tmp/nvws.XXXXXX 2>/dev/null || echo /tmp/nvws.$$)"
    awk '{
      if (NR % 3 == 0) { gsub(/ /, "  "); }
      if (NR % 5 == 0) { $0=$0"\t"; }
      print
    }' "$f" > "$tmp" 2>/dev/null && mv "$tmp" "$f" || true
  fi
}
touch_version()    { printf "%s\n" "${1:-1.0.0}" > VERSION; }

append_doc() {
  mkdir -p doc
  local paras; paras="$(c_range 2 5)"
  local bullets; bullets="$(c_range 2 7)"
  local code_lines; code_lines="$(c_lines 5)"
  {
    printf "# %s %s\n\n" "$(rand_word | tr '[:lower:]' '[:upper:]')" "$(rand_word)"
    printf "_Auto-generated %s doc._\n\n" "$(rand_word)"
    printf "## Overview\n\n"
    printf "%s %s %s %s.\n\n" "$(rand_word)" "$(rand_word)" "$(rand_word)" "$(rand_word)"
    printf "## Features\n\n"
    local i
    for ((i=0;i<bullets;i++)); do
      printf "- %s %s %s\n" "$(rand_word)" "$(rand_word)" "$(rand_word)"
    done
    printf "\n## Example\n\n\`\`\`cpp\n"
    for ((i=0;i<code_lines;i++)); do
      printf "int f%d(int x){ return (x*x) + %d; }\n" "$i" "$((RANDOM%97))"
    done
    printf "\`\`\`\n\n## Details\n\n"
    for ((i=0;i<paras;i++)); do
      local words; words="$(c_lines 30)"
      tr -dc 'a-z \n' < /dev/urandom | tr -s ' ' | head -c $((words*5)) | sed 's/$/\n/' 
      echo
    done
  } >> doc/README.md 2>/dev/null || echo "$(rand_word) $(rand_word)" >> doc/README.md
}

rename_random_file() {
  local f; f="$(git ls-files | shuf -n 1 2>/dev/null || true)"; [[ -n "$f" ]] || return 0
  local dir base new; dir="$(dirname -- "$f")"; base="$(basename -- "$f")"
  local stamp; stamp="$(date +%s)$RANDOM"
  if [[ "$dir" == "." ]]; then new="renamed_${stamp}_$(rand_word)_${base}"; else new="${dir}/renamed_${stamp}_$(rand_word)_${base}"; fi
  [[ -e "$new" ]] && new="${new}.${RANDOM}"
  git mv -k "$f" "$new" >/dev/null 2>&1 || true
}
delete_random_file(){ local f; f="$(git ls-files | shuf -n 1 2>/dev/null || true)"; [[ -n "$f" ]] || return 0; git rm -q "$f" || true; }

maybe_tag() {
  # 30% chance; richer semver: MAJOR.MINOR.PATCH[-pre.N]+build.meta
  if (( $(rand_bool "$(c_prob 30)") )); then
    local maj min pat pre build
    maj=$((RANDOM%4 + 0))
    min=$((RANDOM%20))
    pat=$((RANDOM%50))
    if (( $(rand_bool 50) )); then pre="-alpha.$((RANDOM%10))"; fi
    if (( $(rand_bool 33) )); then build="+meta.$((RANDOM%100)).$((RANDOM%1000))"; fi
    local ver="${maj}.${min}.${pat}${pre:-}${build:-}"
    (( $(rand_bool 60) )) && git_tag_light "$ver" || git_tag_annot "$ver"
  fi
}

# ---- CMake skeleton ----
write_cmake_skel() {
  cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(nvproj LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(NV_WARNINGS_AS_ERRORS "Treat warnings as errors" OFF)
option(NV_LTO "Enable link-time optimization" OFF)

if(MSVC)
  add_compile_options(/W4 /permissive-)
else()
  add_compile_options(-Wall -Wextra -Wpedantic -Wconversion -Wshadow -Wduplicated-cond -Wduplicated-branches -Wnull-dereference -Wdouble-promotion)
  if(NV_WARNINGS_AS_ERRORS)
    add_compile_options(-Werror)
  endif()
  if(NV_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_ok OUTPUT ipo_msg)
    if(ipo_ok)
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
    endif()
  endif()
endif()

file(GLOB_RECURSE NV_SOURCES CONFIGURE_DEPENDS "src/*.cpp")
file(GLOB_RECURSE NV_TESTS   CONFIGURE_DEPENDS "test/*.cpp")
file(GLOB_RECURSE NV_HEADERS CONFIGURE_DEPENDS "include/*.h" "include/*.hpp")

add_library(nvlib STATIC ${NV_SOURCES} ${NV_HEADERS})
target_include_directories(nvlib PUBLIC include)
if(NOT MSVC)
  target_compile_definitions(nvlib PRIVATE NV_BUILD_UNIX=1)
endif()

add_executable(nvmain src/main.cpp)
target_link_libraries(nvmain PRIVATE nvlib)

enable_testing()
foreach(t ${NV_TESTS})
  get_filename_component(_n "${t}" NAME_WE)
  add_executable(${_n} "${t}")
  target_link_libraries(${_n} PRIVATE nvlib)
  add_test(NAME ${_n} COMMAND ${_n})
endforeach()
EOF
}

# ---- main.cpp (complex) ----
write_cpp_main_min() {
  mkdir -p src include
  local lines; lines="$(c_lines 160)"
  cat > src/main.cpp <<EOF
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <iostream>
#include <map>
#include <numeric>
#include <random>
#include <string>
#include <thread>
#include <vector>

namespace nv {
constexpr std::uint64_t rotl(std::uint64_t x, int s) noexcept { return (x<<s)|(x>>(64-s)); }
constexpr std::uint64_t junk_seed(std::uint64_t x) noexcept {
  return rotl((x^0x9e3779b97f4a7c15ULL)*0xbf58476d1ce4e5b9ULL, 27);
}
template<class T> concept Arithmetic = std::is_arithmetic_v<T>;
template<Arithmetic T>
constexpr T wobbly(T x) noexcept {
  for (int i=0;i<3;i++) x = (x+static_cast<T>(i*7)) ^ (x>>1);
  return x;
}
}

#ifndef NV_NOISE_SCALE
#define NV_NOISE_SCALE(x) ((x)*1337 + ((x)>>3) - ((x)<<1))
#endif

static std::atomic<std::uint64_t> g_counter{0};

int main() {
  using namespace std;
  ios::sync_with_stdio(false); cin.tie(nullptr);

  volatile long long sentinel = 0;
  for (int outer=0; outer<${lines}; ++outer) {
    long long a = NV_NOISE_SCALE(outer) ^ static_cast<long long>(nv::junk_seed(static_cast<unsigned>(outer)));
    a = nv::wobbly<long long>(a);
    if ((outer%7)==3) { // mixed control flow
      continue;
    }
    for (int inner=0; inner<(outer%13); ++inner) {
      a += (inner*outer) ^ static_cast<int>(nv::rotl(static_cast<unsigned>(inner+31), (outer%19)+1));
      if((inner&3)==1) { g_counter.fetch_add(static_cast<unsigned>(a), std::memory_order_relaxed); continue; }
      sentinel ^= (a ^ inner);
    }
    if ((outer%11)==0) {
      auto f = [outer](long long z){ return (z ^ static_cast<long long>(outer*outer)) + (z>>2); };
      sentinel += f(a);
    }
  }

  vector<int> v(1024); iota(v.begin(), v.end(), 1);
  auto res = accumulate(v.begin(), v.end(), 0LL, [](long long s, int x){ return s + (x*x) - ((x&1)?x:0); });

  // tiny parallel fragment
  thread t1([]{ for(int i=0;i<1000;i++) g_counter.fetch_add(1, std::memory_order_relaxed); });
  thread t2([]{ for(int i=0;i<1000;i++) g_counter.fetch_add(2, std::memory_order_relaxed); });
  t1.join(); t2.join();

  cout << "ok " << (sentinel ^ res ^ static_cast<long long>(g_counter.load())) << "\\n";
  return static_cast<int>((sentinel ^ res ^ static_cast<long long>(g_counter.load())) & 0xFF);
}
EOF
}

# ---- extra C++ generators ----
add_macro_maze() {
  mkdir -p include
  local h="include/maze_$(rand_word).h"
  cat > "$h" <<'EOF'
#pragma once
#define NV_CAT_(a,b) a##b
#define NV_CAT(a,b)  NV_CAT_(a,b)
#define NV_STR_(x)   #x
#define NV_STR(x)    NV_STR_(x)
#define NV_REPEAT_1(X) X
#define NV_REPEAT_2(X) NV_REPEAT_1(X) X
#define NV_REPEAT_4(X) NV_REPEAT_2(X) NV_REPEAT_2(X)
#define NV_REPEAT_8(X) NV_REPEAT_4(X) NV_REPEAT_4(X)
#define NV_UNLIKELY(x) __builtin_expect(!!(x),0)
#ifndef NV_NOISE_SCALE
#define NV_NOISE_SCALE(x) ((x)*1337 + ((x)>>5) - ((x)<<2) + 42)
#endif
#define NV_IF(c,a,b) ((c)?(a):(b))
EOF
}

add_chaotic_header() {
  mkdir -p include
  local h="include/chaos_$(rand_word).h"
  cat > "$h" <<'EOF'
#pragma once
#include <type_traits>
#include <utility>
namespace chaos {
template<class T, class=void> struct rank : std::integral_constant<int,0>{};
template<class T> struct rank<T, std::void_t<decltype(sizeof(T))>> : std::integral_constant<int,1>{};
template<class T> constexpr int rank_v = rank<T>::value;
template<class F, class... A>
constexpr auto call(F&& f, A&&... a) noexcept(noexcept(f(std::forward<A>(a)...))){
    if constexpr(noexcept(f(std::forward<A>(a)...))) return f(std::forward<A>(a)...);
    else return f(std::forward<A>(a)...);
}

template<class T>
concept SmallTrivial = std::is_trivial_v<T> && sizeof(T) <= 8;
}
EOF
}

add_cpp_noise_unit() {
  mkdir -p src include
  local f="src/noise_$(rand_word).cpp"
  local loops; loops="$(c_range 120 360)"
  local maze="maze_$(rand_word).h"
  echo '#pragma once' > "include/${maze}"
  cat > "$f" <<EOF
#include <vector>
#include <numeric>
#include <cstdint>
#include <algorithm>
#include <array>
#include "${maze}"
static std::uint64_t twiddle(std::uint64_t x){
  #pragma GCC ivdep
  for(int i=0;i<7;i++) x = (x*0x9e3779b97f4a7c15ULL) ^ (x>>((i%5)+1));
  return x ^ (x<<1);
}
int noise_${RANDOM}(){
  volatile std::uint64_t s=0;
  for(int i=0;i<$loops;i++){
    std::uint64_t a = twiddle(static_cast<std::uint64_t>(i*1337u + (i<<3)));
    for(int j=0;j<(i%9);++j){
      a ^= static_cast<std::uint64_t>(j*0xABCDEFu) + (a>>3);
      if((j&2)==0) continue;
      s += a ^ static_cast<std::uint64_t>(i*j);
    }
  }
  std::array<int,1024> arr{}; std::iota(arr.begin(), arr.end(), 1);
  return static_cast<int>((std::accumulate(arr.begin(), arr.end(), 0) ^ s) & 0x7FFFFFFF);
}
EOF
}

add_template_stress() {
  mkdir -p src include
  local h="include/meta_$(rand_word).h"
  local f="src/meta_$(rand_word).cpp"
  cat > "$h" <<'EOF'
#pragma once
#include <array>
#include <utility>
#include <cstddef>
template<std::size_t N>
struct Fib { static constexpr unsigned long long value = Fib<N-1>::value + Fib<N-2>::value; };
template<> struct Fib<1>{ static constexpr unsigned long long value = 1; };
template<> struct Fib<0>{ static constexpr unsigned long long value = 0; };

template<std::size_t N>
constexpr auto make_seq(){
  std::array<unsigned long long,N> a{};
  for(std::size_t i=0;i<N;i++) a[i] = Fib<(i%24)>::value;
  return a;
}
EOF
  cat > "$f" <<'EOF'
#include <numeric>
#include <vector>
#include <cstdint>
#include "meta_placeholder.h"
static int meta_probe(){
  constexpr auto seq = make_seq<192>();
  unsigned long long s=0;
  for(auto x:seq) s += (x*x) - (x>>1);
  return static_cast<int>(s & 0x7FFFFFFF);
}
EOF
  sed -i "s/meta_placeholder.h/$(basename "$h")/" "$f"
}

add_deadcode_garden() {
  mkdir -p src
  local f="src/dead_$(rand_word).cpp"
  local blocks; blocks="$(c_range 20 80)"
  {
    echo '#include <cstdint>'
    echo '#include <utility>'
    echo "int dead_${RANDOM}(){"
    echo "  volatile std::uint64_t z=0;"
    for ((i=0;i<blocks;i++)); do
      echo "  if (__builtin_expect(((${RANDOM}%1024)==-1),0)) { z+=${RANDOM}ull; } else { z^=${RANDOM}ull; }"
    done
    echo "  return static_cast<int>(z & 0x7FFFFFFF);"
    echo "}"
  } > "$f"
}

add_random_namespace_header() {
  mkdir -p include
  local h="include/ns_$(rand_word).h"
  local n; n="$(c_range 4 12)"
  {
    echo '#pragma once'
    for ((i=0;i<n;i++)); do
      local ns; ns="$(rand_word)"
      echo "namespace $ns { inline int v$i(){ int s=0; for(int k=0;k<${RANDOM}%60;k++) s+=k*k - (k&1); return s; } }"
    done
  } > "$h"
}

# perf/test/security/breaking/basic feature bulk
add_feature_file_once() {
  mkdir -p src include
  local fname="feature_$(rand_word)"
  local fns; fns="$(c_range 2 6)"
  {
    echo "#pragma once"
    local j; for ((j=0;j<fns;j++)); do
      printf "int %s_fn%d();\n" "${fname}" "$j"
    done
  } > "include/${fname}.h"
  {
    echo "#include <cstdlib>"
    echo "#include \"${fname}.h\""
    local j; for ((j=0;j<fns;j++)); do
      printf "int %s_fn%d(){ return %d + std::rand()%7; }\n" "${fname}" "$j" "$(rand_int 0 199)"
    done
  } > "src/${fname}.cpp"
}
add_feature_files_bulk(){ local n; n="$(c_range 1 5)"; for ((k=0;k<n;k++)); do add_feature_file_once; done; }

add_perf_code() {
  mkdir -p src
  local N; N="$(c_lines 800)"
  cat > "src/perf_$(rand_word).cpp" <<EOF
#include <vector>
#include <numeric>
int perf_fn_${RANDOM}(){
  std::vector<int> v(${N},1);
  return std::accumulate(v.begin(),v.end(),0);
}
EOF
}

add_test() {
  mkdir -p test
  local assertions; assertions="$(c_range 3 25)"
  {
    echo '#include <cassert>'
    echo '#include <cstdint>'
    echo 'int main(){'
    local i; for ((i=0;i<assertions;i++)); do echo "  assert( (static_cast<std::uint32_t>(${RANDOM}%5)) == (static_cast<std::uint32_t>(${RANDOM}%5)) );"; done
    echo '  return 0;'
    echo '}'
  } > "test/test_$(rand_word).cpp"
}

add_security_fix() {
  mkdir -p src
  local lines; lines="$(c_lines 25)"
  {
    echo '#include <cstring>'
    echo '#include <cstddef>'
    echo 'void copy_safe(char* d,const char* s,std::size_t n){ if(n){ std::strncpy(d,s,n-1); d[n-1]=0; } }'
    local i=0; while (( i < lines )); do
      echo "void shim_$i(char* d,const char* s,std::size_t n){ copy_safe(d,s,n); }"; ((++i))
    done
  } > "src/sec_$(rand_word).cpp"
}

breaking_api_change() {
  mkdir -p include src
  echo "#pragma once" > include/api.h
  local overloads; overloads="$(c_range 1 5)"
  {
    echo "#ifdef NV_API_V1_DEPRECATED"
    echo "// v1 deprecated"
    echo "#endif"
    local i; for ((i=0;i<overloads;i++)); do echo "int api_v2_$i();"; done
  } >> include/api.h
  { local i; for ((i=0;i<overloads;i++)); do echo "int api_v2_$i(){ return $((i+2)); }"; done; } > src/api.cpp
}

# ---- extra complexity units (merged, not yet wired) ----
add_ranges_unit() {
  mkdir -p src
  local f="src/ranges_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <vector>
#include <ranges>
#include <numeric>
#include <cstdint>
int ranges_probe(){
  std::vector<int> v(500); std::iota(v.begin(), v.end(), 1);
  auto rng = v | std::views::filter([](int x){ return (x&1)==0; })
               | std::views::transform([](int x){ return x*x - (x>>1); });
  long long s = 0;
  for (int x : rng) s += x;
  return static_cast<int>(s & 0x7FFFFFFF);
}
EOF
}

add_filesystem_unit() {
  mkdir -p src
  local f="src/fs_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <filesystem>
#include <string>
#include <cstdint>
int fs_probe(){
  namespace fs = std::filesystem;
  auto p = fs::path("doc") / "README.md";
  // Query only; do not create/modify FS.
  auto ok = fs::exists(p);
  return ok ? 1 : 0;
}
EOF
}

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

add_threading_unit() {
  mkdir -p src
  local f="src/thread_$(rand_word).cpp"
  cat > "$f" <<'EOF'
#include <thread>
#include <atomic>
#include <vector>
#include <cstdint>
static std::atomic<int> acc{0};
int thread_probe(){
  std::vector<std::thread> ts;
  for(int i=0;i<4;i++){
    ts.emplace_back([]{ for(int k=0;k<1000;k++) acc.fetch_add(1, std::memory_order_relaxed); });
  }
  for(auto& t:ts) t.join();
  return acc.load(std::memory_order_relaxed);
}
EOF
}

add_concepts_unit() {
  mkdir -p src include
  local h="include/concepts_$(rand_word).h"
  local f="src/concepts_$(rand_word).cpp"
  cat > "$h" <<'EOF'
#pragma once
#include <type_traits>
template<class T>
concept TinyTrivial = std::is_trivial_v<T> && (sizeof(T) <= 8);

template<TinyTrivial T>
constexpr T add3(T x){ return static_cast<T>(x + T{3}); }
EOF
  cat > "$f" <<EOF
#include "$(basename "$h")"
#include <cstdint>
int concepts_probe(){
  return static_cast<int>(add3<std::uint8_t>(5));
}
EOF
}

add_header_only_lib() {
  mkdir -p include src
  local h="include/hol_${RANDOM}.hpp"
  local f="src/hol_${RANDOM}.cpp"
  cat > "$h" <<'EOF'
#pragma once
#include <cstdint>
namespace hol {
template<class T> constexpr T mix(T a, T b){ return (a^b) + (a>>1); }
inline int call(int x){ return mix(x, 17); }
}
EOF
  cat > "$f" <<EOF
#include "$(basename "$h")"
int hol_probe(){ return hol::call(5); }
EOF
}

# ---- orchestrator (optional) ----
# Levels: low | medium | high | insane
generate_cpp_bundle() {
  local level="${1:-medium}"

  write_cmake_skel
  write_cpp_main_min

  # Always-on baseline
  add_macro_maze
  add_chaotic_header
  add_cpp_noise_unit
  add_template_stress
  add_deadcode_garden
  add_random_namespace_header
  add_feature_files_bulk
  add_perf_code
  add_test
  add_security_fix
  breaking_api_change
  add_ranges_unit
  add_optional_variant_unit
  add_header_only_lib

  case "$level" in
    low)
      ;;
    medium)
      add_threading_unit
      add_filesystem_unit
      ;;
    high)
      add_threading_unit
      add_filesystem_unit
      # duplicate some generators for volume
      add_cpp_noise_unit
      add_template_stress
      add_perf_code
      add_test
      ;;
    insane)
      add_threading_unit
      add_filesystem_unit
      # spray many units
      for _ in {1..3}; do add_cpp_noise_unit; done
      for _ in {1..2}; do add_template_stress; done
      for _ in {1..2}; do add_deadcode_garden; done
      for _ in {1..3}; do add_perf_code; done
      for _ in {1..3}; do add_test; done
      ;;
    *)
      echo "[nv-generators] Unknown level '$level' (use low|medium|high|insane)" >&2
      return 2
      ;;
  esac
}

# ---- load external generator modules (extracted) ----
# Source modular generator scripts if present; these override in-file versions.
if [[ -d "${SCRIPT_DIR}/generators" ]]; then
  for _genmod in "${SCRIPT_DIR}/generators/"*.sh; do
    [[ -e "${_genmod}" ]] || continue
    # shellcheck disable=SC1090
    source "${_genmod}"
  done
fi
