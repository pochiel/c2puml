%{
#include <stdio.h>

void output_to_file(char * smbl, int size);
void clear_synbol_string();

#define C_MAX_SYNBOL_NAME	(1024)
char synbol_name[C_MAX_SYNBOL_NAME];
int g_symbol_index = 0;
FILE * output_file_ptr = ULL;
%}
%union {
    int ival;
    double dval;
    char cval;
}

%token <ival> INTNUM MEMLOAD MEMSTORE FOR IN TO STEP IF THEN ELSE END EXIT
%token <dval> DOUBLENUM
%token <cval> IDENTIFIER
%type <dval> program block expr term factor ifst

%start program

%%
/* ï∂ÇÃÇÕÇ∂Çﬂ */
program : block ';'             { $$ = $1; }
        | block '\n'            { $$ = $1; }
        | program block '\n'    { $$ = $2; }
        ;

block   : expr                  { $$ = $1; printf("expr=%d\n", $1); }
        | ifst                  { printf("$1=%s\n", $1); return 0; }	

expr    : term                  { $$ = $1; printf("term=%d\n", $1); }
        | expr '+' term         { $$ = $1 + $3; printf("$1=%d $3=%d\n", $1, $3);    }
        | expr '-' term         { $$ = $1 - $3; }
        ;

term    : factor                { $$ = $1; printf("factor=%d\n", $1); }
        | term '*' factor       { $$ = $1 * $3; }
        | term '/' factor       { $$ = $1 / $3; }
        ;

factor  : INTNUM                { $$ = $1;printf("INTVAL=%d\n", $1); }
        | IDENTIFIER            { $$ = 0;printf("IDENTIFIER $1=%s\n", &$1); }
        | DOUBLENUM             { $$ = $1;printf("double\n"); }
        | '(' expr ')'          { $$ = $2;;printf("expr in expr\n"); }
        ;

/* ifï∂ÇÃïœä∑ */
ifst    :   IF'(' expr ')'      { printf("if (%s) then (true)", synbol_name); clear_synbol_string(); }
        ;
%%

void output_to_file(char * smbl, int size){
	fprintf(output_file_ptr, "%s ", smbl); // ÉtÉ@ÉCÉãÇ…èëÇ≠
}

void push_synbol_string(char * smbl, int size){
	strncpy(&synbol_name[g_symbol_index], smbl, size);
	synbol_name[g_symbol_index + size] = 0;
	g_symbol_index += size;
}

void clear_synbol_string(){
	memset(synbol_name, 0, C_MAX_SYNBOL_NAME);
	g_symbol_index = 0;
}