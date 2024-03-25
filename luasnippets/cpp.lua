local ls = require("luasnip")

ls.add_snippets("cpp", {
    ls.parser.parse_snippet({ trig = "f" }, "for (int $1 = $2; $1 < $3; ++$1) {\n\t$0\n}"),
    ls.parser.parse_snippet({ trig = "fb" }, "for (int $1 = $2; $1 >= $3; --$1) {\n\t$0\n}"),
    ls.parser.parse_snippet({ trig = "fff" }, [[
#include <algorithm>
#include <bitset>
#include <cassert>
#include <cmath>
#include <ctime>
#include <iostream>
#include <map>
#include <numbers>
#include <numeric>
#include <queue>
#include <random>
#include <set>
#include <stack>
#include <vector>

#ifdef DDD
#define start              \
    cout.setf(ios::fixed); \
    cout.precision(10);    \
    int START = clock()
#define finish                                                                  \
    cout << "\ntime: " << (clock() - START) / (double)(CLOCKS_PER_SEC) << '\n'; \
    return 0
#else
#define start                         \
    cin.tie(NULL);                    \
    cout.tie(NULL);                   \
    ios_base::sync_with_stdio(false); \
    cout.setf(ios::fixed);            \
    cout.precision(10)
#define finish return 0
#endif

using namespace std;

using i32 = int32_t;
using i64 = int64_t;
using u32 = uint32_t;
using u64 = uint64_t;
using d80 = long double;

// vector input
template <typename T>
istream &operator>>(istream &is, vector<T> &vec) {
    for (auto &i : vec) {
        is >> i;
    }
    return is;
}

// vector output
template <typename T>
ostream &operator<<(ostream &os, vector<T> &vec) {
    for (T i : vec) {
        os << i << ' ';
    }
    return os;
}

void solve() {
    $0
}

i32 main() {
    start;

    solve();

    finish;
}
]]),
    ls.parser.parse_snippet({ trig = "en" }, "'\\n'"),
    ls.parser.parse_snippet({ trig = "be" }, "$1.begin(), $1.end()"),
})
