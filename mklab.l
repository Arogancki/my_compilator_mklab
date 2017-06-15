%{
#include <stdlib.h>
#include <string.h>
#include "mklab.tab.hh"
extern int yylineno; // licznik lini
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
#ifndef ASSERT_ON
	#define ASSERT_ON true
#endif
int yyerror(const char *msg,...); // funckja wyswietlajaca msg i zwracjaca blad
%}
%%
-?[0-9]+ {/*fprintf(yyout, "liczba int\n");*/ yylval.ival = atoi(yytext);return IVAL;}
-?[0-9]*"."[0-9]+ {/*fprintf(yyout, "liczba double\n");*/ yylval.dval = atof(yytext);return DVAL;}
int {/*fprintf(yyout, "int\n");*/return INT;}
dou {/*fprintf(yyout, "dou\n");*/return DOU;}
str {/*fprintf(yyout, "str\n");*/return STR;}
\[ {/*fprintf(yyout, "[\n");*/return '[';}
\] {/*fprintf(yyout, "]\n");*/return ']';}
alloc {/*fprintf(yyout, "allokator\n");*/return ALO;}
\=	{/*fprintf(yyout, "=\n");*/return '=';}
\+ {/*fprintf(yyout, "+\n");*/return '+';}
\- {/*fprintf(yyout, "-\n");*/return '-';}
\* {/*fprintf(yyout, "*\n");*/return '*';}
\/ {/*fprintf(yyout, "/\n");*/return '/';}
\( {/*fprintf(yyout, "(\n");*/return '(';}
\) {/*fprintf(yyout, ")\n");*/return ')';}
\| {/*fprintf(yyout, "|\n");*/return '|';}
\& {/*fprintf(yyout, "&\n");*/return '&';}
\! {/*fprintf(yyout, "!\n");*/return '!';}
\? {/*fprintf(yyout, "?\n");*/return '?';}
\> {/*fprintf(yyout, ">\n");*/return '>';}
\< {/*fprintf(yyout, "<\n");*/return '<';}
\# {/*fprintf(yyout, "#\n");*/return '#';}
if {/*fprintf(yyout, "if\n");*/return IFF;}
else {/*fprintf(yyout, "else\n");*/return ELS;}
for {/*fprintf(yyout, "for\n");*/return FOR;}
while {/*fprintf(yyout, "while\n");*/return WHI;}
fun {/*fprintf(yyout, "function\n");*/return FUN;}
struct {/*fprintf(yyout, "struct\n");*/return STU;}
\{ {/*fprintf(yyout, "{\n");*/return '{';}
\} {/*fprintf(yyout, "}\n");*/return '}';}
\>\> {/*fprintf(yyout, "wypisanie tekstu\n");*/return OUT;}
\<\< {/*fprintf(yyout, "wczytanie zmiennej\n");*/return INN;}
\; {/*fprintf(yyout, ";\n");*/return ';';} 
\ |\t {/*fprintf(yyout, "znak biualy\n");*/}
\n {/*fprintf(yyout, "nowalinia\n");*/yylineno++;}
\"[^\"]*\" {/*fprintf(yyout, "test w nawiasach\n");*/ yytext[strlen(yytext)]=0; yylval.text = strdup(yytext); return TEXT;}
[A-Za-z_][.A-Za-z0-9_]* {/*fprintf(yyout, "nazwa zmiennej\n");*/yylval.text = strdup(yytext);return NAME;}
. {yyerror("Błąd leksykalny\n");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}
