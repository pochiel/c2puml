%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>

void output_to_file(std::string &);

#define YYDEBUG 1

/* グローバル変数 */
FILE * output_file_ptr = NULL;

/* プロトタイプ宣言 */
extern "C" void yyerror(const char* s);
extern "C" int  yylex(void);

%}

%code requires {
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
}

%union {
	int		itype;
	std::string	* ctype;
}

%defines
/* 終端記号 */
%token<ctype> BRACE END_BRACE IF FOR WHILE EXPR COMMENT ANY_OTHER ELSE FUNCTION ENDFUNCTION SWITCH CASE DEFAULT DO BREAK CONTINUE RETRN GOTO

/* 非終端記号 */
%type<ctype> program codes block ifst forst comment any_other functionst switchst casest case_set_expr block_member single_line_member dowhilest if_c else_c retrnst comment_unit

%start program

%%
/* プログラムとはなんぞや */
program		:	functionst						{ $$ = $1; }
			|	comment							{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	program program					{ $$ = new std::string(*$1 + *$2); }
			;

/* 関数とはなんぞや */
functionst	:	FUNCTION BRACE codes END_BRACE	{
														std::string output_str = "@startuml\n:" + (*$1) + ";\nstart\n" + (*$3) + "\nstop\n@enduml\n";
														output_to_file(output_str);
													}
			;

codes		:	codes codes						{ $$ = new std::string(*$1 + *$2); }
			|	block							{ $$ = $1; }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	BREAK							{ $$ = new std::string(":break;\n");	/* 暫定 */ }
			|	CONTINUE						{ $$ = new std::string(":continue;\n");	/* 暫定 */ }
			|	retrnst							{ $$ = $1; }
			|	GOTO EXPR						{ $$ = new std::string(":goto;" + *$2 + "\n");	/* 暫定 */ }
			|	switchst						{ $$ = $1; }
			;

block		:	BRACE block_member END_BRACE	{ $$ = $2; }
			;

block_member :	block_member block_member		{ $$ = new std::string(*$1 + *$2); }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	BREAK							{ $$ = new std::string(":break;\n");	/* 暫定 */ }
			|	CONTINUE						{ $$ = new std::string(":continue;\n");	/* 暫定 */ }
			|	retrnst							{ $$ = $1; }
			|	GOTO EXPR						{ $$ = new std::string(":goto;" + *$2 + "\n");	/* 暫定 */ }
			|	switchst						{ $$ = $1; }
			;

single_line_member	:	ifst							{ $$ = $1; }
					|	forst							{ $$ = $1; }
					|	dowhilest						{ $$ = $1; }
					|	any_other						{ $$ = $1; }
					|	BREAK							{ $$ = new std::string(":break;\n");	/* 暫定 */ }
					|	CONTINUE						{ $$ = new std::string(":continue;\n");	/* 暫定 */ }
					|	retrnst							{ $$ = $1; }
					|	GOTO EXPR						{ $$ = new std::string(":goto " + *$2 + ";\n");	/* 暫定 */ }
					|	switchst						{ $$ = $1; }
					;

if_c		: IF								{ std::cout << "--------------------------------------------1\n"; }
			| comment IF						{ std::cout << "--------------------------------------------2\n"; $$ = $1; }
			;
			
else_c		: ELSE								{ std::cout << "--------------------------------------------3\n"; }
			| comment ELSE						{ std::cout << "--------------------------------------------4\n"; $$ = $1; }
			;


ifst		: if_c EXPR block						{
													$$ = new std::string("if (" + (*$2) + ") then (true)\n" + (*$3) + "endif\n");
												}
			| if_c EXPR block else_c block			{
													$$ = new std::string("if (" + *$2 + ") then (true)\n" + *$3 + "else\n" + *$5 +"endif\n");
												}
			| if_c EXPR single_line_member		{
													$$ = new std::string("if (" + (*$2) + ") then (true)\n" + (*$3) + "endif\n");
												}
			| if_c EXPR single_line_member if_c single_line_member		{
													$$ = new std::string("if (" + *$2 + ") then (true)\n" + *$3 + "else\n" + *$5 +"endif\n");
												}
			;

forst   :   FOR EXPR block					{
													$$ = new std::string("while (" + *$2 + ")\n" + *$3 + "end while\n");
												}
		|	WHILE EXPR block					{
													$$ = new std::string("while (" + *$2 + ")\n" + *$3 + "end while\n");
												}
		|	FOR EXPR single_line_member					{
													$$ = new std::string("while (" + *$2 + ")\n" + *$3 + "end while\n");
												}
		|	WHILE EXPR single_line_member					{
													$$ = new std::string("while (" + *$2 + ")\n" + *$3 + "end while\n");
												}
        ;

dowhilest	: DO block WHILE EXPR			{
													$$ = new std::string("repeat\n" + *$2 + "\nrepeat while (" + *$4 + ")\n");
											}
			;

switchst	: SWITCH EXPR BRACE casest END_BRACE	 {
														$$ = new std::string("if (" + *$2 + ") then ( ) \n" + *$4 + "endif\n");
													 }
			;

/* case が連続して並んでいるときのパターン */
case_set_expr : CASE EXPR							{
														$$ = new std::string("(" + *$2 + ")");
													}
			| case_set_expr CASE EXPR 				{
														$$ = new std::string("(" + *$1 + ") or (" + *$3 + ")");
													}
			;
			
casest		: case_set_expr codes					{
														$$ = new std::string("elseif (" + *$1 + ") then (true) \n" + *$2 + "\n");
													}
			| case_set_expr codes casest			{
														$$ = new std::string("elseif (" + *$1 + ") then (true) \n" + *$2 + "\n" + *$3);
													}
			| casest DEFAULT codes				{
														$$ = new std::string( *$1 + "\n else \n" + *$3 + "\n");
													}
			| case_set_expr DEFAULT codes	{
														$$ = new std::string( *$1 + "elseif (" + *$1 + ") then (true) \n" + *$3 + "\n else \n" + *$3);
													}
			;

/* コメントの変換 */
comment_unit 	: COMMENT				{ $$ = $1; }
				| comment_unit COMMENT	{
										$$ = new std::string(*$1 + *$2);
										}
				;

comment	:	comment_unit		{ 
									$$ = new std::string("note right\n" + *$1 + "\nend note\n");
								}

/* その他はそのまま載せる */
any_other	:	ANY_OTHER		{
									$$ = new std::string(":" + *$1 + ";\n");
								}
			| 	comment ANY_OTHER		{
									$$ = new std::string(":" + *$2 + ";\n");
								}
			| 	ANY_OTHER comment		{
									$$ = new std::string(":" + *$1 + ";\n");
								}
			;

/* return */
retrnst		:	RETRN EXPR		{
									$$ = new std::string(":return " + *$2 + ";\n");
								}
			|	comment RETRN EXPR	{
									$$ = new std::string(":return " + *$2 + ";\n");
								}
			|	RETRN EXPR comment	{
									$$ = new std::string(":return " + *$2 + ";\n");
								}
%%

void output_to_file(std::string &msg){
	fprintf(output_file_ptr, "%s", msg.c_str()); // ファイルに書く
}
