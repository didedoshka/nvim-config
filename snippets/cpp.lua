return {
    {
        prefix = 'vi',
        body = "vector<int>"
    },

    {
        prefix = 'vvi',
        body = "vector<vector<int>>"
    },

    {
        prefix = 'ft',
        body = "for ($1 $2 = $3; $2 < $4; ++$2) {\n\t$0\n}"
    },

    {
        prefix = 'f',
        body = "for (int $1 = $2; $1 < $3; ++$1) {\n\t$0\n}"
    },

    {
        prefix = 'fb',
        body = "for (int $1 = $2; $1 >= $3; --$1) {\n\t$0\n}"
    },

    {
        prefix = 'en',
        body = '\'\\n\''
    },

    {
        prefix = 'be',
        body = "$1.begin(), $1.end()"
    },

    {
        prefix = 'fff',
        body = [[
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

#define int long long

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

int32_t main() {
    start;

    solve();

    finish;
}
]]
    },

    {
        prefix = 'ttt',
        body = [[
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

#define int long long

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

int32_t main() {
    start;

    int t;
    cin >> t;
    while (t--) {
        solve();
    }

    finish;
}
]]
    },
}
