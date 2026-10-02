#pragma once

#include <string>
#include <string_view>

// Shift ASCII letters by `shift` positions; see PROMPT.md.
std::string caesar(std::string_view text, int shift);
