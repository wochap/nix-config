#include "calc.hpp"

#include <cctype>
#include <charconv>
#include <format>
#include <limits>

namespace {

using Result = std::expected<long long, EvalError>;

bool is_ident_start(char c) { return std::isalpha(static_cast<unsigned char>(c)) || c == '_'; }
bool is_ident_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; }

class Parser {
  public:
    Parser(std::string_view src, std::size_t start, const Env &env)
        : src_(src), pos_(start), env_(env) {}

    Result parse_all() {
        auto v = expr();
        if (!v) {
            return v;
        }
        skip_ws();
        if (pos_ != src_.size()) {
            return fail(ErrorKind::Syntax, pos_);
        }
        return v;
    }

  private:
    std::string_view src_;
    std::size_t pos_;
    const Env &env_;

    static Result fail(ErrorKind k, std::size_t at, std::string detail = {}) {
        return std::unexpected(EvalError{k, at, std::move(detail)});
    }

    void skip_ws() {
        while (pos_ < src_.size() && std::isspace(static_cast<unsigned char>(src_[pos_]))) {
            ++pos_;
        }
    }

    char peek() {
        skip_ws();
        return pos_ < src_.size() ? src_[pos_] : '\0';
    }

    Result expr() {
        auto lhs = term();
        while (lhs && (peek() == '+' || peek() == '-')) {
            const char op = src_[pos_];
            const std::size_t at = pos_++;
            auto rhs = term();
            if (!rhs) {
                return rhs;
            }
            long long r = 0;
            const bool ovf = op == '+' ? __builtin_add_overflow(*lhs, *rhs, &r)
                                       : __builtin_sub_overflow(*lhs, *rhs, &r);
            if (ovf) {
                return fail(ErrorKind::Overflow, at);
            }
            lhs = r;
        }
        return lhs;
    }

    Result term() {
        auto lhs = unary();
        while (lhs && (peek() == '*' || peek() == '/' || peek() == '%')) {
            const char op = src_[pos_];
            const std::size_t at = pos_++;
            auto rhs = unary();
            if (!rhs) {
                return rhs;
            }
            long long r = 0;
            if (op == '*') {
                if (__builtin_mul_overflow(*lhs, *rhs, &r)) {
                    return fail(ErrorKind::Overflow, at);
                }
            } else if (*rhs == 0) {
                return fail(ErrorKind::DivideByZero, at);
            } else if (*lhs == std::numeric_limits<long long>::min() && *rhs == -1) {
                return fail(ErrorKind::Overflow, at);
            } else {
                r = op == '/' ? *lhs / *rhs : *lhs % *rhs;
            }
            lhs = r;
        }
        return lhs;
    }

    Result unary() {
        if (peek() == '-') {
            const std::size_t at = pos_++;
            auto v = unary();
            if (v && *v == std::numeric_limits<long long>::min()) {
                return fail(ErrorKind::Overflow, at);
            }
            return v.transform([](long long x) { return -x; });
        }
        return primary();
    }

    Result primary() {
        const char c = peek();
        const std::size_t start = pos_;
        if (c == '(') {
            ++pos_;
            auto v = expr();
            if (!v) {
                return v;
            }
            if (peek() != ')') {
                return fail(ErrorKind::Syntax, pos_);
            }
            ++pos_;
            return v;
        }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            while (pos_ < src_.size() && std::isdigit(static_cast<unsigned char>(src_[pos_]))) {
                ++pos_;
            }
            long long v = 0;
            const auto [ptr, ec] = std::from_chars(src_.data() + start, src_.data() + pos_, v);
            (void)ptr;
            if (ec != std::errc{}) {
                return fail(ErrorKind::Overflow, start);
            }
            return v;
        }
        if (is_ident_start(c)) {
            while (pos_ < src_.size() && is_ident_char(src_[pos_])) {
                ++pos_;
            }
            const std::string_view name = src_.substr(start, pos_ - start);
            if (auto it = env_.find(name); it != env_.end()) {
                return it->second;
            }
            return fail(ErrorKind::UnknownVariable, start, std::string(name));
        }
        return fail(ErrorKind::Syntax, pos_);
    }
};

} // namespace

std::expected<long long, EvalError> evaluate(std::string_view expr, const Env &env) {
    return Parser(expr, 0, env).parse_all();
}

std::expected<long long, EvalError> execute(std::string_view line, Env &env) {
    std::size_t i = 0;
    while (i < line.size() && std::isspace(static_cast<unsigned char>(line[i]))) {
        ++i;
    }
    const std::size_t name_start = i;
    if (i < line.size() && is_ident_start(line[i])) {
        while (i < line.size() && is_ident_char(line[i])) {
            ++i;
        }
        std::size_t j = i;
        while (j < line.size() && std::isspace(static_cast<unsigned char>(line[j]))) {
            ++j;
        }
        if (j < line.size() && line[j] == '=') {
            auto v = Parser(line, j + 1, env).parse_all();
            if (v) {
                env.insert_or_assign(std::string(line.substr(name_start, i - name_start)), *v);
            }
            return v;
        }
    }
    return Parser(line, 0, env).parse_all();
}

std::string describe(const EvalError &err) {
    switch (err.kind) {
    case ErrorKind::Syntax:
        return std::format("syntax error at {}", err.pos);
    case ErrorKind::DivideByZero:
        return std::format("division by zero at {}", err.pos);
    case ErrorKind::UnknownVariable:
        return std::format("unknown variable '{}' at {}", err.detail, err.pos);
    case ErrorKind::Overflow:
        return std::format("overflow at {}", err.pos);
    }
    return "unknown error";
}
