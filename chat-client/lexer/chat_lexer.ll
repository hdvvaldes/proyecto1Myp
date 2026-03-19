%{
  #include<iostream>
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

<INITIAL>"/help"        { std::cout << "found: " << yytext << std::endl; }
<INITIAL>"/quit"        { std::cout << "found: " << yytext << std::endl;  }
<INITIAL>"/disconnect"  { std::cout << "found: " << yytext << std::endl;  }
<INITIAL>"/users"       { std::cout << "found: " << yytext << std::endl;  }

<INITIAL>"/connect"     { BEGIN(SC_ARGS); }
<INITIAL>"/identify"    { BEGIN(SC_ARGS); }
<INITIAL>"/status"      { BEGIN(SC_ARGS); }
<INITIAL>"/msg"         { BEGIN(SC_ARGS); }
<INITIAL>"/pub"         { BEGIN(SC_TEXT); }
<INITIAL>"/newroom"     { BEGIN(SC_ARGS); }
<INITIAL>"/invite"      { BEGIN(SC_ARGS); }
<INITIAL>"/join"        { BEGIN(SC_ARGS); }
<INITIAL>"/roomusers"   { BEGIN(SC_ARGS); }
<INITIAL>"/roomtext"    { BEGIN(SC_ARGS); }
<INITIAL>"/leave"       { BEGIN(SC_ARGS); }

<INITIAL>"/"[^ \t\n]+   { /* otherwise case */}
<INITIAL>{WORD}[^\n]*   { /* just text  */}
<INITIAL>\n             { /* empty line */ }
<INITIAL><<EOF>>        { /* end of file*/}

<SC_ARGS>{WS}           { /* skip */ }
<SC_ARGS>{WORD}         { }
<SC_ARGS>\n             { BEGIN(INITIAL); }
<SC_ARGS><<EOF>>        { BEGIN(INITIAL); }

<SC_TEXT>{WS}           { /* skip leading whitespace before body */ }
<SC_TEXT>[^ \t\n][^\n]* { BEGIN(INITIAL); }
<SC_TEXT>\n             { BEGIN(INITIAL); }
<SC_TEXT><<EOF>>        { BEGIN(INITIAL); }

%%

 /* TODO remove this main function*/

int main() {
  FlexLexer* lexer = new yyFlexLexer;
  lexer->yylex();
  return 0;
}
