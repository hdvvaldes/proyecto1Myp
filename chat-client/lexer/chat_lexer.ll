%{
#include "Token.hpp"
#include "Lexer.hpp"
#include <string>
#include <sstream>
struct LexerImpl;

using namespace std;
%}

%option c++
%option noyywrap


%x SC_ARGS
%x SC_TEXT

/* WhiteSpace */
WS      [ \t]+

WORD    [^ \t\n]+

%%

<INITIAL>{WS}           { /* skip leading whitespace */ }

<INITIAL>"/help"        { return static_cast<int>(Token::CMD_HELP);       }
<INITIAL>"/quit"        { return static_cast<int>(Token::CMD_QUIT);       }
<INITIAL>"/disconnect"  { return static_cast<int>(Token::CMD_DISCONNECT); }
<INITIAL>"/users"       { return static_cast<int>(Token::CMD_USERS);      }

<INITIAL>"/connect"     { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_CONNECT);   }
<INITIAL>"/identify"    { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_IDENTIFY);  }
<INITIAL>"/status"      { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_STATUS);    }
<INITIAL>"/msg"         { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_MSG);       }
<INITIAL>"/pub"         { BEGIN(SC_TEXT); return static_cast<int>(Token::CMD_PUB);       }
<INITIAL>"/newroom"     { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_NEWROOM);   }
<INITIAL>"/invite"      { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_INVITE);    }
<INITIAL>"/join"        { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_JOIN);      }
<INITIAL>"/roomusers"   { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_ROOMUSERS); }
<INITIAL>"/roomtext"    { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_ROOMTEXT);  }
<INITIAL>"/leave"       { BEGIN(SC_ARGS); return static_cast<int>(Token::CMD_LEAVE);     }

<INITIAL>"/"[^ \t\n]+   { return static_cast<int>(Token::UNKNOWN_CMD); }
<INITIAL>{WORD}[^\n]*   { return static_cast<int>(Token::RAW_TEXT);    }
<INITIAL>\n             { /* empty line */ }
<INITIAL><<EOF>>        { return static_cast<int>(Token::END_OF_INPUT); }

<SC_ARGS>{WS}           { /* skip */ }
<SC_ARGS>{WORD}         { return static_cast<int>(Token::ARG); }
<SC_ARGS>\n             { BEGIN(INITIAL); return static_cast<int>(Token::END_OF_LINE);  }
<SC_ARGS><<EOF>>        { BEGIN(INITIAL); return static_cast<int>(Token::END_OF_INPUT); }

<SC_TEXT>{WS}           { /* skip leading whitespace before body */ }
<SC_TEXT>[^ \t\n][^\n]* { BEGIN(INITIAL); return static_cast<int>(Token::TEXT_BODY);    }
<SC_TEXT>\n             { BEGIN(INITIAL); return static_cast<int>(Token::END_OF_LINE);  }
<SC_TEXT><<EOF>>        { BEGIN(INITIAL); return static_cast<int>(Token::END_OF_INPUT); }

%%

#include <sstream>

struct LexerImpl {
    std::istringstream stream;
    ChatFlexLexer      scanner;
    Token              lastToken  = Token::NONE;
    std::string        lastLexeme;

    LexerImpl() : scanner(&stream, nullptr) {}

    void reset(const std::string& line) {
        stream.clear();
        stream.str(line + "\n");
        scanner.switch_streams(&stream, nullptr);
        lastToken  = Token::NONE;
        lastLexeme.clear();
    }
};

Lexer::Lexer()  : impl_(std::make_unique<LexerImpl>()) {}
Lexer::~Lexer() = default;

void Lexer::setInput(const std::string& line) { impl_->reset(line); }

const std::string& Lexer::lexeme()      const { return impl_->lastLexeme; }
Token              Lexer::currentToken() const { return impl_->lastToken;  }

Token Lexer::nextToken() {
    int raw = impl_->scanner.yylex();
    impl_->lastLexeme = impl_->scanner.YYText();
    impl_->lastToken  = static_cast<Token>(raw);
    return impl_->lastToken;
}

