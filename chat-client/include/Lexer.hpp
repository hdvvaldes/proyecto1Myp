#pragma once

/*
 * Lexer.h  –  Public interface of the chat command lexer.
 *
 */

#include "Token.hpp"
#include <FlexLexer.h>
#include <sstream>
#include <string>

class Lexer : public yyFlexLexer {
public:
    explicit Lexer(std::istream& in = std::cin);

    // Feed a new line to the scanner; resets all internal state.
    void  setInput(const std::string& line);

    // Advance one token and return its type.
    Token nextToken();

    // String value of the last token (meaningful for ARG, TEXT_BODY,
    // RAW_TEXT, UNKNOWN_CMD).
    const std::string& lexeme() const;

    // Type of the last token without advancing.
    Token currentToken() const;

private:
    int yylex() override;

    Token              token_  = Token::NONE;
    std::string        lexeme_;
    std::istringstream lineStream_;
};
