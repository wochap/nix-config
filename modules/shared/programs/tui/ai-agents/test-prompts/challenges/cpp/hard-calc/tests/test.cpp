#include "calc.hpp"

#include <cstdio>
#include <string>
#include <string_view>

static int failures = 0;

static std::string show(const std::expected<long long, EvalError> &r) {
    if (r) {
        return "value " + std::to_string(*r);
    }
    return "error {kind=" + std::to_string(static_cast<int>(r.error().kind)) +
           ", pos=" + std::to_string(r.error().pos) + ", detail=\"" + r.error().detail + "\"}";
}

static void expect_eq(int line, std::string_view what, const std::expected<long long, EvalError> &got,
                      const std::expected<long long, EvalError> &want) {
    if (got != want) {
        ++failures;
        std::printf("FAIL line %d: %.*s\n  got:  %s\n  want: %s\n", line,
                    static_cast<int>(what.size()), what.data(), show(got).c_str(),
                    show(want).c_str());
    }
}

static std::expected<long long, EvalError> err(ErrorKind k, std::size_t pos, std::string d = "") {
    return std::unexpected(EvalError{k, pos, std::move(d)});
}

#define EVAL(expr, env, want) expect_eq(__LINE__, expr, evaluate(expr, env), want)
#define EXEC(line, env, want) expect_eq(__LINE__, line, execute(line, env), want)
#define CHECK(cond)                                                                                \
    do {                                                                                           \
        if (!(cond)) {                                                                             \
            ++failures;                                                                            \
            std::printf("FAIL line %d: %s\n", __LINE__, #cond);                                    \
        }                                                                                          \
    } while (0)

using std::expected;
constexpr long long MAX = 9223372036854775807LL;
constexpr long long MIN = -MAX - 1;

int main() {
    const Env none;
    using enum ErrorKind;

    // Arithmetic and precedence
    EVAL("1 + 2 * 3", none, 7LL);
    EVAL("(1 + 2) * 3", none, 9LL);
    EVAL("10 - 4 - 3", none, 3LL);
    EVAL("100 / 10 / 5", none, 2LL);
    EVAL("2 * 3 % 4", none, 2LL);
    EVAL("-7 / 2", none, -3LL);
    EVAL("-7 % 3", none, -1LL);
    EVAL("7 % -3", none, 1LL);
    EVAL("--5", none, 5LL);
    EVAL("-(2 + 3) * -2", none, 10LL);
    EVAL("2*-3", none, -6LL);
    EVAL("  42  ", none, 42LL);
    EVAL("\t( ( 1 ) )\n", none, 1LL);
    EVAL("007", none, 7LL);

    // Variables
    const Env env{{"x", 5}, {"long_name_2", -3}, {"_", 100}};
    EVAL("x * x + long_name_2", env, 22LL);
    EVAL("_ / x", env, 20LL);
    EVAL("x + y", env, err(UnknownVariable, 4, "y"));
    EVAL("X", env, err(UnknownVariable, 0, "X"));
    EVAL("  xx", env, err(UnknownVariable, 2, "xx"));

    // Syntax errors: position of the offending character, or input length at end
    EVAL("", none, err(Syntax, 0));
    EVAL("   ", none, err(Syntax, 3));
    EVAL("1 +", none, err(Syntax, 3));
    EVAL("(1", none, err(Syntax, 2));
    EVAL("1 )", none, err(Syntax, 2));
    EVAL("1 $ 2", none, err(Syntax, 2));
    EVAL("+1", none, err(Syntax, 0));
    EVAL("2x", env, err(Syntax, 1));
    EVAL("1 2", none, err(Syntax, 2));
    EVAL("()", none, err(Syntax, 1));
    EVAL("3 * (4 + )", none, err(Syntax, 9));

    // Division by zero: position of the operator
    EVAL("1 / 0", none, err(DivideByZero, 2));
    EVAL("5 % (2 - 2)", none, err(DivideByZero, 2));
    EVAL("1/0 +", none, err(DivideByZero, 1));
    EVAL("y + 1/0", env, err(UnknownVariable, 0, "y"));

    // Overflow (no undefined behaviour allowed; tests run under UBSan)
    EVAL("9223372036854775807", none, MAX);
    EVAL("-9223372036854775807 - 1", none, MIN);
    EVAL("9223372036854775808", none, err(Overflow, 0));
    EVAL("1 + 99999999999999999999", none, err(Overflow, 4));
    EVAL("9223372036854775807 + 1", none, err(Overflow, 20));
    EVAL("-9223372036854775807 - 2", none, err(Overflow, 21));
    EVAL("4611686018427387904 * 2", none, err(Overflow, 20));
    EVAL("3037000500*3037000500", none, err(Overflow, 10));
    const Env mins{{"m", MIN}};
    EVAL("m / -1", mins, err(Overflow, 2));
    EVAL("m % -1", mins, err(Overflow, 2));
    EVAL("-m", mins, err(Overflow, 0));
    EVAL("m / 1", mins, MIN);
    EVAL("m % 7", mins, MIN % 7);

    // execute: assignment and plain expressions
    Env vars;
    EXEC("a = 2 + 3", vars, 5LL);
    EXEC("  b=a*a", vars, 25LL);
    EXEC("a = a + 1", vars, 6LL);
    EXEC("a + b", vars, 31LL);
    CHECK(vars.size() == 2);
    CHECK(vars.contains("a") && vars.at("a") == 6);
    EXEC("c = 1 / 0", vars, err(DivideByZero, 6));
    CHECK(!vars.contains("c"));
    EXEC("b = nope", vars, err(UnknownVariable, 4, "nope"));
    CHECK(vars.contains("b") && vars.at("b") == 25);
    EXEC("d =", vars, err(Syntax, 3));
    EXEC("e == 1", vars, err(Syntax, 3));
    EXEC("= 4", vars, err(Syntax, 0));
    EXEC("2 = 4", vars, err(Syntax, 2));
    EXEC("zz", vars, err(UnknownVariable, 0, "zz"));

    // describe
    CHECK(describe(EvalError{Syntax, 3, ""}) == "syntax error at 3");
    CHECK(describe(EvalError{DivideByZero, 2, ""}) == "division by zero at 2");
    CHECK(describe(EvalError{UnknownVariable, 4, "y"}) == "unknown variable 'y' at 4");
    CHECK(describe(EvalError{Overflow, 20, ""}) == "overflow at 20");

    if (failures != 0) {
        std::printf("%d failure(s)\n", failures);
        return 1;
    }
    std::printf("all tests passed\n");
    return 0;
}
