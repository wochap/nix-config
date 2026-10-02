# cpp cartridge — target: C++23 (C++20 fallback), GCC 15

## Rules (DON'T → DO)
- DON'T `new` / `delete` → DO `std::make_unique<T>(args)`; `std::make_shared` only for real shared ownership
- DON'T `std::unique_ptr<T>(new T)` → DO `std::make_unique<T>()`
- DON'T raw owning pointers in classes → DO `std::unique_ptr` members (rule of 0)
- DON'T write copy/move/dtor by hand → DO rule of 0; if you write one of the 5, write or `= default`/`= delete` all 5
- DON'T `printf` / `std::cout << a << b` chains → DO `std::println("{} {}", a, b)` (`<print>`, C++23)
- DON'T `sprintf` / `stringstream` for formatting → DO `std::format("{:>8.2f}", x)` (`<format>`)
- DON'T `std::sort(v.begin(), v.end())` → DO `std::ranges::sort(v)`
- DON'T hand loops to filter/transform → DO `v | std::views::filter(f) | std::views::transform(g)`
- DON'T build a vector from a view by loop → DO `| std::ranges::to<std::vector>()` (C++23)
- DON'T `for (size_t i...)` just for an index → DO `for (auto [i, x] : std::views::enumerate(v))` (C++23)
- DON'T erase-remove idiom → DO `std::erase_if(v, pred)` (C++20)
- DON'T `m.find(k) != m.end()` for existence → DO `m.contains(k)` (C++20)
- DON'T `s.substr(0, n) == p` → DO `s.starts_with(p)` / `s.ends_with(p)` (C++20)
- DON'T return error codes or throw for expected failures → DO `std::expected<T, E>` + `std::unexpected(e)` (C++23)
- DON'T return `nullptr`/sentinel for "maybe" → DO `std::optional<T>` with `.value_or(d)`
- DON'T `const std::string&` param for read-only text → DO `std::string_view` (by value)
- DON'T `(T* ptr, size_t n)` params → DO `std::span<T>` / `std::span<const T>`
- DON'T SFINAE / `enable_if` → DO concepts: `template <std::integral T>` or `void f(std::floating_point auto x)`
- DON'T `push_back(T(args))` → DO `emplace_back(args)`
- DON'T pass big objects by value read-only → DO `const T&`
- DON'T override without the keyword → DO `override` (and `final` when sealed)
- DON'T `virtual` base without virtual dtor → DO `virtual ~Base() = default;`
- DON'T `std::thread` + manual `join` → DO `std::jthread` (auto-joins, has `stop_token`)
- DON'T `lock()`/`unlock()` by hand → DO `std::scoped_lock lk(m);` / `std::unique_lock` for condvars
- DON'T C casts `(int)x` → DO `static_cast<int>(x)`
- DON'T `NULL` / `0` for pointers → DO `nullptr`
- DON'T `#define` constants → DO `constexpr` / `inline constexpr`
- DON'T `using namespace std;` in headers → DO qualify `std::`
- DON'T `enum` → DO `enum class`; convert with `std::to_underlying(e)` (C++23)

## Gotchas
- Signed integer overflow is UB; use unsigned or check before arithmetic.
- Out-of-bounds `v[i]` is UB; use `.at(i)` when unsure, or ranges/iterators.
- `push_back`/`emplace_back`/`insert` may reallocate and invalidate ALL iterators, pointers, refs to elements.
- Never keep `auto& x = v[0];` across a `push_back`.
- Erasing from a container while iterating invalidates the iterator; use `std::erase_if` or `it = v.erase(it)`.
- `std::string_view` / `std::span` don't own data; returning one into a local or temporary dangles.
- `std::string_view sv = std::string("x");` dangles immediately.
- `string_view::data()` is not null-terminated; don't pass it to C APIs.
- Lambdas capturing `[&]` dangle if stored past the scope; capture by value or `[p = std::move(p)]`.
- After `std::move(x)`, `x` is valid but unspecified; only assign or destroy it.
- `std::move` on a `const` object silently copies.
- Don't `return std::move(local);`; it blocks copy elision (NRVO).
- `auto x = expr;` drops refs and const; use `auto&` / `const auto&` to avoid copies.
- `auto` with `std::vector<bool>` element or proxy types yields a proxy, not a `bool`.
- `std::map::operator[]` inserts a default value on miss; use `find`/`contains`/`at` to read.
- Range-for over a temporary's member (`for (x : make().items)`) dangles before C++23.
- Uninitialized locals are indeterminate; always initialize: `int n{};`.
- Data races on non-atomic shared vars are UB; use `std::atomic` or a mutex.
- `shared_ptr` cycles leak; break with `std::weak_ptr` and `.lock()`.
- `std::unique_ptr` is move-only; pass ownership with `std::move`, borrow with `T*` or `T&`.
- Structured bindings copy by default; use `auto& [k, v]` / `const auto& [k, v]` over maps.
- `std::print`/`std::println` need `<print>` and `-std=c++23`; `std::format` needs `<format>`.
- GCC 15 libstdc++ has no `<mdspan>`; prefer `#include` headers over `import std;`.
- Mixing `std::endl` everywhere forces flushes; use `'\n'`.

## Correct API names
- `std::make_unique_for_overwrite` (no init) vs `std::make_unique` (value-init)
- `std::views::*` is shorthand for `std::ranges::views::*`
- `std::ranges::to<std::vector>()` (C++23), not `std::ranges::to_vector`
- `std::views::zip`, `std::views::enumerate`, `std::views::chunk`, `std::views::iota(a, b)`, `std::views::reverse`
- `std::ranges::fold_left(v, 0, std::plus{})` (C++23), not `std::ranges::accumulate`
- `std::ranges::contains(v, x)` (C++23); `std::ranges::find(v, x)`
- `std::expected::and_then`, `.transform`, `.or_else`, `.error()`, `.value_or()`
- `std::println(stderr, "...")` writes to stderr
- `std::flat_map` (`<flat_map>`, GCC 15) for sorted small maps
- `std::generator<T>` (`<generator>`, C++23) with `co_yield`
- Deducing this: `auto get(this auto&& self)` (C++23)
- `std::bit_cast<T>(x)` instead of `reinterpret_cast` / `memcpy` type punning

## Idioms
```cpp
std::expected<int, std::string> parse(std::string_view s) {
    if (s.empty()) return std::unexpected("empty");
    return static_cast<int>(s.size());
}
```
```cpp
auto odds = v | std::views::filter([](int x) { return x % 2; })
              | std::ranges::to<std::vector>();
```
```cpp
template <std::integral T> T twice(T x) { return x * 2; }
```
```cpp
struct Widget {                // rule of 0
    std::string name;
    std::unique_ptr<Impl> impl;
};
```
```cpp
for (const auto& [key, val] : m) std::println("{}={}", key, val);
```

## Tooling
- `g++ -std=c++23 -Wall -Wextra -Wpedantic -O2 main.cpp -o app`
- Debug: `-g -O0 -fsanitize=address,undefined -fno-omit-frame-pointer`
- Threads: add `-fsanitize=thread` (not with address) to catch races
- Minimal CMakeLists.txt: `cmake_minimum_required(VERSION 3.28)`, `project(app CXX)`, `set(CMAKE_CXX_STANDARD 23)`, `set(CMAKE_CXX_STANDARD_REQUIRED ON)`, `add_executable(app src/main.cpp)`, `target_compile_options(app PRIVATE -Wall -Wextra)`
- `cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build`
- `ctest --test-dir build`
- `clang-format -i src/*.cpp` (config in `.clang-format`)
- `clang-tidy src/main.cpp -p build` (needs compile_commands.json)
