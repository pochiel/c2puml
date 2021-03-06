%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <map>
#include <regex>
#include "parser.hpp"

void output_to_file(std::string &);
void get_comment(std::string &buf);
std::string get_connector(std::string orig_label) ;
void clear_connector_list() ;
std::string get_function_name(std::string function_def);

uint32_t get_comment_index();

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
#include "t_token.hpp"
}

%union {
	int		itype;
	t_token	* ctype;
}

%defines
/* 終端記号 */
%token<ctype> BRACE END_BRACE IF FOR WHILE EXPR ANY_OTHER ELSE FUNCTION ENDFUNCTION SWITCH CASE DEFAULT DO BREAK CONTINUE RETRN GOTO PROTOTYPE LABEL SEMICOLON EQUAL

/* 非終端記号 */
%type<ctype> program codes block ifst forst any_other functionst switchst casest case_set_expr block_member single_line_member dowhilest retrnst breakst gotost labelst case_codes prototype_st func_pointer

%start program

%%

/* プログラムとはなんぞや */
program		:	program program					{ $$ = new t_token(*$1 + *$2); }
			|	functionst						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	prototype_st					{ }
			|	func_pointer					{ }
			;

/* 関数とはなんぞや */
functionst	:	FUNCTION BRACE codes END_BRACE	{
														std::string output_str = "@startuml " + get_function_name($1->token_str) + "\n"
																					+ ":" + ($1->token_str) + ";\n" 
																					+ ($1->get_format_comment()) + "\n" 
																					+ "start\n" 
																					+ ($3->token_str) + "\n"
																					+ ($3->get_format_comment()) + "\n" 
																					+ "@enduml\n";
														output_to_file(output_str);
														clear_connector_list();
													}
			;

func_pointer:	FUNCTION EQUAL block			{ }
prototype_st:	FUNCTION SEMICOLON				{ 													/* 暫定 */ 
													t_token *ret = new t_token();
													ret->token_str = $1->token_str + ";\n";
													$$ = ret; 
												}

codes		:	codes codes						{ $$ = new t_token(*$1 + *$2); }	
			|	block							{ $$ = $1; }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	breakst							{ $$ = $1; }
			|	CONTINUE						{
													/* 暫定 */ 
													t_token *ret = new t_token();;
													ret->token_str = ":continue;\n";
													$$ = ret; 
												}
			|	retrnst							{ $$ = $1; }
			|	gotost							{ $$ = $1; }
			|	switchst						{ $$ = $1; }
			|	labelst							{ $$ = $1; }
			;

block		:	BRACE block_member END_BRACE	{ $$ = $2; }
			|	BRACE END_BRACE					{ }
			;

block_member :	block_member block_member		{ $$ = new t_token(*$1 + *$2); }
			|	func_pointer					{ $$ = $1; }
			|	prototype_st					{ $$ = $1; }
			|	block							{ $$ = $1; }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	breakst							{ $$ = $1; }
			|	CONTINUE						{
													/* 暫定 */ 
													t_token *ret = new t_token();;
													ret->token_str = ":continue;\n";
													$$ = ret; 
												}
			|	retrnst							{ $$ = $1; }
			|	gotost							{ $$ = $1; }
			|	switchst						{ $$ = $1; }
			;

single_line_member	:	ifst							{ $$ = $1; }
					|	forst							{ $$ = $1; }
					|	dowhilest						{ $$ = $1; }
					|	any_other						{ $$ = $1; }
					|	breakst							{ $$ = $1; }
					|	CONTINUE						{
															/* 暫定 */ 
															t_token *ret = new t_token();;
															ret->token_str = ":continue;\n";
															$$ = ret; 
														}
					|	retrnst							{ $$ = $1; }
					|	gotost							{ $$ = $1; }
					|	switchst						{ $$ = $1; }
					;

ifst		: IF EXPR block						{
													t_token *ret = new t_token();;
													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n") 
																		+ $3->token_str + "\n"
																		+ "endif\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
			| IF EXPR block ELSE block			{
													t_token *ret = new t_token();;
													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n")
																		+ $3->token_str + "\n"
																		+ "else\n"
																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n")
																		+ $5->token_str + "\n"
																		+ "endif\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
			| IF EXPR block ELSE ifst			{
													t_token *ret = new t_token();;
													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n") 
																		+ $3->token_str + "\n"
																		+ "else" + $5->token_str + "\n"		/* elseif */
																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n");
													/* 末尾非終端記号の ifst で endifしているはずなので ここでは endif しない */
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
			| IF EXPR single_line_member		{
													t_token *ret = new t_token();;
													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n") 
																		+ $3->token_str + "\n"
																		+ "endif\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
			| IF EXPR single_line_member ELSE single_line_member		{
													t_token *ret = new t_token();;
													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n")
																		+ $3->token_str + "\n"
																		+ "else \n"
																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n")
																		+ $5->token_str + "\n"
																		+ "endif\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
			| IF EXPR single_line_member ELSE ifst		{
													t_token *ret = new t_token();;
													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n")
																		+ $3->token_str + "\n"
																		+ "else" + $5->token_str + "\n"		/* elseif */
																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n");
													/* 末尾非終端記号の ifst で endifしているはずなので ここでは endif しない */
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
			;

forst   :   FOR EXPR block						{
													t_token *ret = new t_token();;
													ret->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
		|	WHILE EXPR block					{
													t_token *ret = new t_token();;
													ret->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
		|	FOR EXPR single_line_member			{
													t_token *ret = new t_token();;
													ret->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
		|	WHILE EXPR single_line_member		{
													t_token *ret = new t_token();;
													ret->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
												}
        ;

dowhilest	: DO block WHILE EXPR			{
													t_token *ret = new t_token();;
													ret->token_str = 	"repeat\n"
																		+ $1->get_format_comment() + "\n" 
																		+ $2->token_str + "\n" 
																		+ "repeat while(" + $4->token_str + ")\n"
																		+ $3->get_format_comment() + "\n" ;
													ret->comment = "";	/* コメントは消しておく */
													$$ = ret;
											}
			;

switchst	: SWITCH EXPR BRACE casest END_BRACE	 {
														t_token *ret = new t_token();;
														ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $4->token_str + "\n"
																			+ "endif\n";
														ret->comment = "";	/* コメントは消しておく */
														$$ = ret;
													}
			;

/* case が連続して並んでいるときのパターン */
case_set_expr : CASE EXPR							{
														t_token *ret = new t_token();;
														ret->token_str 	= 	"(" + $2->token_str + ")";
														ret->comment	=	$1->comment;
														$$ = ret;
													}
			| case_set_expr CASE EXPR 				{
														t_token *ret = new t_token();;
														ret->token_str 	= 	"(" + $1->token_str + ") or (" + $3->token_str + ")";
														if( ($1->comment != "") && ($3->comment != "") ){
															ret->comment	=	$1->comment  + "\n" + $3->comment;
														} else {
															ret->comment	=	$1->comment  + $3->comment;
														}
														$$ = ret;
													}
			;

case_codes	:	case_codes case_codes			{ $$ = new t_token(*$1 + *$2); }	
			|	block							{ $$ = $1; }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	breakst							{ 
													/* switch文の中に break を書くとバグるので
														case処理の中の break は無視する */
													t_token *ret = new t_token();;
													ret->token_str = "";
													ret->comment = "";
													$$ = ret; 
												}
			|	CONTINUE						{
													/* 暫定 */ 
													t_token *ret = new t_token();;
													ret->token_str = ":continue;\n";
													$$ = ret; 
												}
			|	retrnst							{ $$ = $1; }
			|	gotost							{ $$ = $1; }
			|	switchst						{ $$ = $1; }
			|	labelst							{ $$ = $1; }
			;

casest		: case_set_expr case_codes				{
														t_token *ret = new t_token();;
														ret->token_str = 	"elseif (" + $1->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $2->token_str + "\n";
														ret->comment = "";	/* コメントは消しておく */
														$$ = ret;
													}
			| case_set_expr case_codes casest		{
														t_token *ret = new t_token();;
														ret->token_str = 	"elseif (" + $1->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $2->token_str + "\n"
																			+ $3->token_str + "\n";
														ret->comment = "";	/* コメントは消しておく */
														$$ = ret;
													}
			| casest DEFAULT case_codes				{
														t_token *ret = new t_token();;
														ret->token_str = 	$1->token_str + "\n"
																			+ "else\n"
																			+ $2->get_format_comment()
																			+ $3->token_str + "\n";
														ret->comment = "";	/* コメントは消しておく */
														$$ = ret;
													}
			| case_set_expr DEFAULT case_codes		{
														t_token *ret = new t_token();;
														ret->token_str = 	"elseif (" + $1->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $3->token_str + "\n";
																			+ "else\n"
																			+ $2->get_format_comment() + "\n"
																			+ $3->token_str + "\n";
														ret->comment = "";	/* コメントは消しておく */
														$$ = ret;
													}
			;

/* その他はそのまま載せる */
any_other	:	ANY_OTHER		{
									t_token *ret = new t_token();;
									ret->token_str = 	":" + $1->token_str + ";\n" 
														+ $1->get_format_comment() + "\n";
									ret->comment = "";	/* コメントは消しておく */
									$$ = ret;
								}
			;

/* return */
retrnst		:	RETRN EXPR		{
									t_token *ret = new t_token();;
									ret->token_str = 	":return " + $2->token_str + ";\n" 
														+ $1->get_format_comment() + "\n"
														+ "stop\n";
									ret->comment = "";	/* コメントは消しておく */
									$$ = ret;
								}
			;

/* break */
breakst		:	BREAK			{ 
									t_token *ret = new t_token();;
										ret->token_str = ":break;\n"
														+ $1->get_format_comment() + "\n"
														+ "break\n";
									ret->comment = "";	/* コメントは消しておく */
									$$ = ret; 
								}

/* goto */
gotost		:	GOTO EXPR		{
									t_token *ret = new t_token();;
									ret->token_str = ":goto " + $2->token_str + ";\n"
													+ $1->get_format_comment() + "\n"
													+ "(" + get_connector($2->token_str) +")\n"
													+ "detach\n";
									ret->comment = "";	/* コメントは消しておく */
									$$ = ret; 
								}

/* goto label */
labelst		:	LABEL		{
									t_token *ret = new t_token();;
									ret->token_str = "(" + get_connector($1->token_str) + ")\n"
													+ $1->get_format_comment() + "\n";
									ret->comment = "";	/* コメントは消しておく */
									$$ = ret; 
								}

%%

static std::string g_comment_buf;

void set_comment(const std::string &com) {
	g_comment_buf = com;
}

void get_comment(std::string &buf) {
	buf = g_comment_buf;
	g_comment_buf = "";
}

void output_to_file(std::string &msg){
	fprintf(output_file_ptr, "%s", msg.c_str()); // ファイルに書く
}

std::map <std::string, std::string> g_connector_map;
int connector_index = 0;
std::string get_connector(std::string orig_label) {
	std::string ret = "";
	orig_label = std::regex_replace(orig_label, std::regex("(:|;)"), "");
	if(g_connector_map.count(orig_label) == 0){
		ret = (char)('a'+(connector_index++));
		g_connector_map[orig_label] = ret;
	} else {
		ret = g_connector_map[orig_label];	
	}
	return ret;
}

void clear_connector_list() {
	g_connector_map.clear();
	connector_index=0;
}

std::string get_function_name(std::string function_def){
	return std::regex_replace(function_def, std::regex("\\*"), "(asterisk)");;
}