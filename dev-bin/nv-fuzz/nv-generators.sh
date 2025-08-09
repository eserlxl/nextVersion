#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=nv-common.sh
source "${SCRIPT_DIR}/nv-common.sh"

# ---- content helpers ----
whitespace_nudge() { sed -E 's/[[:space:]]+/ /g' -i "$1" 2>/dev/null || true; }
touch_version()    { printf "%s\n" "${1:-1.0.0}" > VERSION; }

append_doc() {
  mkdir -p doc
  local paras; paras="$(c_range 1 3)"
  {
    printf "# %s\n\n" "$(rand_word)"
    local i
    for ((i=0;i<paras;i++)); do
      local words; words="$(c_lines 20)"
      tr -dc 'a-z \n' < /dev/urandom | tr -s ' ' | head -c $((words*5)) | sed 's/$/\n/' 
      echo
    done
  } >> doc/README.md 2>/dev/null || echo "$(rand_word) $(rand_word)" >> doc/README.md
}

rename_random_file() {
  local f; f="$(git ls-files | shuf -n 1 2>/dev/null || true)"; [[ -n "$f" ]] || return 0
  local dir base new; dir="$(dirname -- "$f")"; base="$(basename -- "$f")"
  if [[ "$dir" == "." ]]; then new="renamed_$(rand_word)_${base}"; else new="${dir}/renamed_$(rand_word)_${base}"; fi
  [[ -e "$new" ]] && { [[ "$dir" == "." ]] && new="renamed_$(rand_word)_${RANDOM}_${base}" || new="${dir}/renamed_$(rand_word)_${RANDOM}_${base}"; }
  git mv "$f" "$new" >/dev/null 2>&1 || true
}
delete_random_file(){ local f; f="$(git ls-files | shuf -n 1 2>/dev/null || true)"; [[ -n "$f" ]] || return 0; git rm -q "$f" || true; }

maybe_tag() {
  if (( $(rand_bool "$(c_prob 30)") )); then
    local ver="${RANDOM%4}.$((RANDOM%10)).$((RANDOM%10))"
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

file(GLOB_RECURSE NV_SOURCES CONFIGURE_DEPENDS "src/*.cpp")
file(GLOB_RECURSE NV_TESTS   CONFIGURE_DEPENDS "test/*.cpp")
file(GLOB_RECURSE NV_HEADERS CONFIGURE_DEPENDS "include/*.h")

add_library(nvlib STATIC ${NV_SOURCES} ${NV_HEADERS})
target_include_directories(nvlib PUBLIC include)

add_executable(nvmain src/main.cpp)
target_link_libraries(nvmain PRIVATE nvlib)

foreach(t ${NV_TESTS})
  get_filename_component(_n "${t}" NAME_WE)
  add_executable(${_n} "${t}")
  target_link_libraries(${_n} PRIVATE nvlib)
endforeach()
EOF
}

# ---- main.cpp (complex) ----
write_cpp_main_min() {
  mkdir -p src include
  local lines; lines="$(c_lines 120)"
  cat > src/main.cpp <<EOF
#include <bits/stdc++.h>
using namespace std;
constexpr uint64_t rotl(uint64_t x, int s){ return (x<<s)|(x>>(64-s)); }
constexpr uint64_t junk_seed(uint64_t x){ return rotl((x^0x9e3779b97f4a7c15ULL)*0xbf58476d1ce4e5b9ULL, 27); }
template<class T> concept Arithmetic = std::is_arithmetic_v<T>;
template<Arithmetic T> T wobbly(T x){ for(int i=0;i<3;i++) x = (x+static_cast<T>(i*7)) ^ (x>>1); return x; }
#ifndef NV_NOISE_SCALE
#define NV_NOISE_SCALE(x) ((x)*1337 + ((x)>>3) - ((x)<<1))
#endif
int main(){
  ios::sync_with_stdio(false); cin.tie(nullptr);
  volatile long long sentinel = 0;
  for(int outer=0; outer<${lines}; ++outer){
    long long a = NV_NOISE_SCALE(outer) ^ junk_seed(outer);
    a = wobbly<long long>(a);
    int k=outer%7; if(k==3) goto SKIP_BLOCK;
    for(int inner=0; inner< (outer%13); ++inner){
      a += (inner*outer) ^ rotl(inner+31, (outer%19)+1);
      if((inner&3)==1) continue;
      sentinel ^= (a ^ inner);
    }
SKIP_BLOCK:
    if((outer%11)==0){
      auto f = [outer](long long z){ return (z ^ (outer*outer)) + (z>>2); };
      sentinel += f(a);
    }
  }
  vector<int> v(512); iota(v.begin(), v.end(), 1);
  auto res = accumulate(v.begin(), v.end(), 0LL, [](long long s, int x){ return s + (x*x) - ((x&1)?x:0); });
  cout << "ok " << (sentinel ^ res) << "\\n";
  return static_cast<int>((sentinel ^ res) & 0xFF);
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
}
EOF
}

add_cpp_noise_unit() {
  mkdir -p src
  local f="src/noise_$(rand_word).cpp"
  local loops; loops="$(c_range 80 300)"
  cat > "$f" <<EOF
#include <vector>
#include <numeric>
#include <cstdint>
#include "maze_$(rand_word).h"
static uint64_t twiddle(uint64_t x){
  for(int i=0;i<7;i++) x = (x*0x9e3779b97f4a7c15ULL) ^ (x>>((i%5)+1));
  return x ^ (x<<1);
}
int noise_${RANDOM}(){
  volatile uint64_t s=0;
  for(int i=0;i<$loops;i++){
    uint64_t a = twiddle(i*1337ull + (i<<3));
    for(int j=0;j<(i%9);++j){
      a ^= (j*0xABCDEFu) + (a>>3);
      if((j&2)==0) continue;
      s += a ^ (i*j);
    }
  }
  std::vector<int> v(1024);
  std::iota(v.begin(), v.end(), 1);
  return (int)((std::accumulate(v.begin(), v.end(), 0) ^ s) & 0x7FFFFFFF);
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
#include "meta_placeholder.h"
#include <numeric>
#include <vector>
static int meta_probe(){
  constexpr auto seq = make_seq<128>();
  unsigned long long s=0;
  for(auto x:seq) s += (x*x) - (x>>1);
  return (int)(s & 0x7FFFFFFF);
}
EOF
  sed -i "s/meta_placeholder.h/$(basename "$h")/" "$f"
}

add_deadcode_garden() {
  mkdir -p src
  local f="src/dead_$(rand_word).cpp"
  local blocks; blocks="$(c_range 15 60)"
  {
    echo '#include <cstdint>'
    echo "int dead_${RANDOM}(){"
    echo "  volatile uint64_t z=0;"
    for ((i=0;i<blocks;i++)); do
      echo "  if(((${RANDOM}%1024)==-1)){ z+=${RANDOM}ull; } else { z^=${RANDOM}ull; }"
    done
    echo "  return (int)(z & 0x7FFFFFFF);"
    echo "}"
  } > "$f"
}

add_random_namespace_header() {
  mkdir -p include
  local h="include/ns_$(rand_word).h"
  local n; n="$(c_range 3 12)"
  {
    echo '#pragma once'
    for ((i=0;i<n;i++)); do
      local ns; ns="$(rand_word)"
      echo "namespace $ns { inline int v$i(){ int s=0; for(int k=0;k<${RANDOM}%50;k++) s+=k*k; return s; } }"
    done
  } > "$h"
}

# perf/test/security/breaking/basic feature bulk
add_feature_file_once() {
  mkdir -p src include
  local fname="feature_$(rand_word)"
  local fns; fns="$(c_range 1 4)"
  echo "#pragma once" > "include/${fname}.h"
  {
    local j; for ((j=0;j<fns;j++)); do
      printf "int %s_fn%d(){return %d;}\n" "${fname}" "$j" "$(rand_int 0 99)"
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
  local assertions; assertions="$(c_range 1 20)"
  {
    echo '#include <cassert>'
    echo 'int main(){'
    local i; for ((i=0;i<assertions;i++)); do echo "  assert(${RANDOM}%3==${RANDOM}%3);"; done
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
    echo 'void copy_safe(char* d,const char* s,size_t n){ if(n){ std::strncpy(d,s,n-1); d[n-1]='\''\''; } }'
    local i=0; while (( i < lines )); do
      echo "void shim_$i(char* d,const char* s,size_t n){ copy_safe(d,s,n); }"; ((++i))
    done
  } > "src/sec_$(rand_word).cpp"
}

breaking_api_change() {
  mkdir -p include src
  echo "#pragma once" > include/api.h
  local overloads; overloads="$(c_range 1 5)"
  { local i; for ((i=0;i<overloads;i++)); do echo "int api_v2_$i();"; done; } >> include/api.h
  { local i; for ((i=0;i<overloads;i++)); do echo "int api_v2_$i(){ return $((i+2)); }"; done; } > src/api.cpp
}
