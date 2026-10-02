#include "caesar.hpp"

std::string caesar(std::string_view text, int shift) {
    const int k = ((shift % 26) + 26) % 26;
    std::string out(text);
    for (char &c : out) {
        if (c >= 'a' && c <= 'z') {
            c = static_cast<char>('a' + (c - 'a' + k) % 26);
        } else if (c >= 'A' && c <= 'Z') {
            c = static_cast<char>('A' + (c - 'A' + k) % 26);
        }
    }
    return out;
}
