#include "calc.hpp"

std::expected<long long, EvalError> evaluate(std::string_view expr, const Env &env) {
    (void)expr;
    (void)env;
    return std::unexpected(EvalError{ErrorKind::Syntax, 0, ""});
}

std::expected<long long, EvalError> execute(std::string_view line, Env &env) {
    (void)line;
    (void)env;
    return std::unexpected(EvalError{ErrorKind::Syntax, 0, ""});
}

std::string describe(const EvalError &err) {
    (void)err;
    return "";
}
