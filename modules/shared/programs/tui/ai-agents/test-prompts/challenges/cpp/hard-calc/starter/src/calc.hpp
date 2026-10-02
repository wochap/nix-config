#pragma once

#include <cstddef>
#include <expected>
#include <functional>
#include <map>
#include <string>
#include <string_view>

enum class ErrorKind { Syntax, DivideByZero, UnknownVariable, Overflow };

struct EvalError {
    ErrorKind kind;
    std::size_t pos;    // byte offset into the input
    std::string detail; // variable name for UnknownVariable, otherwise empty
    bool operator==(const EvalError &) const = default;
};

using Env = std::map<std::string, long long, std::less<>>;

// Evaluate an integer expression; see PROMPT.md.
std::expected<long long, EvalError> evaluate(std::string_view expr, const Env &env);

// Evaluate `name = expr` (stores the value in env) or a plain expression.
std::expected<long long, EvalError> execute(std::string_view line, Env &env);

// Human-readable message for an error.
std::string describe(const EvalError &err);
