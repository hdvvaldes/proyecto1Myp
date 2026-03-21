#pragma once

/*
 * Lexer.h  –  Public interface of the chat command lexer.
 *
 */


#ifndef FLEX_SCANNER
#include <FlexLexer.h>
#endif
#include "Token.hpp"
#include <sstream>
#include <string>

class Lexer : public yyFlexLexer {
public:
    explicit Lexer(std::istream& in = std::cin);
    
    ~Lexer() = default;

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
