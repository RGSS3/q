
%{
#include <stdio.h>
#include "dyn.h"
#include "q.tab.h"

extern void yyerror(char *s);
%}

%x COMMENT
%x STRING
%%



"//" { BEGIN COMMENT; }

<COMMENT>. {}

<COMMENT>"\n" { BEGIN INITIAL; }








"+" { yylval.str = dyn_new(yytext); return T30; }
"-" { yylval.str = dyn_new(yytext); return T30; }
"*" { yylval.str = dyn_new(yytext); return T40; }
"/" { yylval.str = dyn_new(yytext); return T40; }
"%" { yylval.str = dyn_new("mod"); return T40; }

"="  { yylval.str = dyn_new(yytext); return T10; }
"!=" { yylval.str = dyn_new(yytext); return T10; }
">=" { yylval.str = dyn_new(yytext); return T20; }
"<=" { yylval.str = dyn_new(yytext); return T20; }
">"  { yylval.str = dyn_new(yytext); return T20; }
"<"  { yylval.str = dyn_new(yytext); return T20; }

"&&"  { yylval.str = dyn_new("and"); return T5; }
"||"  { yylval.str = dyn_new("or"); return T4; }
"/\\"  { yylval.str = dyn_new("and"); return T5; }
"\\/"  { yylval.str = dyn_new("or"); return T4; }
"==>"  { yylval.str = dyn_new("implies"); return T3; }

"~"    { yylval.str = dyn_new("not"); return U1; }
"val" { return VAL; }
"given" { return GIVEN; }
"=>" { return AS; }
":" {return COLON; }

";" { return SEMI; }
"," { return COMMA; }

"(" { return LP; }
")" { return RP; }
"{" { return LC; }
"}" { return RC; }

[ \t\n] { /* ignore whitespace */ }

"if" { return IF; }
"out" { return OUT; }
"else" { return ELSE; }
"check" { return CHECK; }

[a-z][A-Za-z0-9_]*   { yylval.str = dyn_new(yytext); return IDENT; }
[A-Z][A-Za-z0-9_]*   { yylval.str = dyn_new(yytext); return TYPE; }

[0-9]+ { yylval.str = dyn_new(yytext); return NUM; }
. { puts("Error"); yyerror(yytext); }







%%
