%{
#include "c2puml.tab.h"
#include <string.h>
extern void push_synbol_string(char * smbl, int size);
extern void clear_synbol_string();
%}

white       [ \t]
floating    [0-9]+\.[0-9]+
integer     [0-9]+
symbol      [=+\-\^*/();\n]
letter      [_[:alpha:]][_[:alnum:]]*
other       .

%%
{white}+
{symbol}                { return(yytext[0]); }
{integer}               { sscanf(yytext, "%d", &yylval.ival);
                          return(INTNUM); }
{floating}              { sscanf(yytext, "%lf", &yylval.dval);
                          return(DOUBLENUM); }
if                      { return(IF); yymore(); }
for                     { return(FOR); }
else                    { return(ELSE); }
{letter}                { push_synbol_string(&yytext[0], strlen(&yytext[0]));
                          return(IDENTIFIER); }
%%
int main(int argc, char *argv[])
{
    FILE * fptr_r = NULL;
    FILE * fptr_w = NULL;
    /* Read file pointer */
    if(argc!=2){
        printf("usage: c2puml [C source file name] \n");
        exit(1);
    }

    if ((fptr_r = fopen(argv[1], "r"))==NULL) {
        printf("file open failed.\n");
        exit(1);
    }
    
    /* write file pointer */
    if ((fptr_w = fopen("./out,puml", "w"))==NULL) {
        printf("output file open failed.\n");
        exit(1);
    }

    /* ç\ï∂âêÕä÷êî yyparse */
    yyin = fptr_r;
    output_file_ptr = fptr_w;
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}