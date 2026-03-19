#pragma once

/*
 * Lexer.h  –  Public interface of the chat command lexer.
 *
 */

enum class Token {
  CMD,
};

class Lexer {
public:
    Lexer();
    ~Lexer();
};
