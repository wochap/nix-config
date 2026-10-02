#include "caesar.hpp"

#include <climits>
#include <cstdio>
#include <string>
#include <string_view>

static int failures = 0;

static void check(std::string_view in, int shift, std::string_view want) {
    const std::string got = caesar(in, shift);
    if (got != want) {
        ++failures;
        std::printf("FAIL caesar(\"%.*s\", %d) = \"%s\", want \"%.*s\"\n", static_cast<int>(in.size()),
                    in.data(), shift, got.c_str(), static_cast<int>(want.size()), want.data());
    }
}

int main() {
    check("abc", 1, "bcd");
    check("xyz", 3, "abc");
    check("Hello, World!", 13, "Uryyb, Jbeyq!");
    check("bcd", -1, "abc");
    check("abc", -27, "zab");
    check("Zz", 52, "Zz");
    check("Az", 27, "Ba");
    check("", 5, "");
    check("123 _-~", 4, "123 _-~");
    check("caf\xc3\xa9", 1, "dbg\xc3\xa9");
    check("abc", INT_MAX, "xyz");
    check("abc", INT_MIN, "cde");
    std::string with_nul("a\0b", 3);
    check(with_nul, 1, std::string_view("b\0c", 3));
    if (failures != 0) {
        std::printf("%d failure(s)\n", failures);
        return 1;
    }
    std::printf("all tests passed\n");
    return 0;
}
