%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>

void output_to_file(std::string &);
void get_comment(std::string &buf);
uint32_t get_comment_index();
#define YYDEBUG 1

/* �O���[�o���ϐ� */
FILE * output_file_ptr = NULL;

/* �v���g�^�C�v�錾 */
extern "C" void yyerror(const char* s);
extern "C" int  yylex(void);

%}

%code requires {
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
class t_token {
	public:
	t_token(){
		token_str = "";
		comment = "";
	}
	t_token(const t_token &t){
		token_str = t.token_str;
		comment = t.comment;
	}
	std::string token_str;
	std::string comment;
	std::string get_format_comment() {
		if(comment.empty()){
			return "";
		} else {
			return "note right\n"
					+ comment + "\n"
					+ "end note\n";
		}
	}
	//  +���Z�q�̃I�[�o�[���[�h
	t_token operator+(const t_token& t2) {
		t_token ret;
		ret.token_str = this->token_str + t2.token_str;
		ret.comment = this->comment + t2.comment;
		return ret;
	}
};
}

%union {
	int		itype;
	t_token	* ctype;
}

%defines
/* �I�[�L�� */
%token<ctype> BRACE END_BRACE IF FOR WHILE EXPR ANY_OTHER ELSE FUNCTION ENDFUNCTION SWITCH CASE DEFAULT DO BREAK CONTINUE RETRN GOTO

/* ��I�[�L�� */
%type<ctype> program codes block ifst forst any_other functionst switchst casest case_set_expr block_member single_line_member dowhilest retrnst

%start program

%%

/* �v���O�����Ƃ͂Ȃ񂼂� */
program		:	functionst						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	program program					{ $$ = new t_token(*$1 + *$2); }
			;

/* �֐��Ƃ͂Ȃ񂼂� */
functionst	:	FUNCTION BRACE codes END_BRACE	{
														std::string output_str = "@startuml\n:"
																					+ ($1->token_str) + ";\n" 
																					+ ($1->get_format_comment()) + "\n" 
																					+ "start\n" 
																					+ ($3->token_str) + "\n"
																					+ ($3->get_format_comment()) + "\n" 
																					+ "stop\n"
																					+ "@enduml\n";
														output_to_file(output_str);
													}
			;

codes		:	codes codes						{ $$ = new t_token(*$1 + *$2); }
			|	block							{ $$ = $1; }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	BREAK							{ 
													/* �b�� */
													$1->token_str = ":break;\n";
													$$ = $1; 
												}
			|	CONTINUE						{
													/* �b�� */ 
													$1->token_str = ":continue;\n";
													$$ = $1; 
												}
			|	retrnst							{ $$ = $1; }
			|	GOTO EXPR						{
													/* �b�� */ 
													$1->token_str = ":goto" + $2->token_str + ";\n" + $1->get_format_comment() + "\n";
													$$ = $1; 
												}
			|	switchst						{ $$ = $1; }
			;

block		:	BRACE block_member END_BRACE	{ $$ = $2; }
			|	BRACE END_BRACE					{ $$ = new t_token(*$1 + *$2); }
			;

block_member :	block_member block_member		{ $$ = new t_token(*$1 + *$2); }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	any_other						{ $$ = $1; }
			|	BREAK							{ 
													/* �b�� */
													$1->token_str = ":break;\n";
													$$ = $1; 
												}
			|	CONTINUE						{
													/* �b�� */ 
													$1->token_str = ":continue;\n";
													$$ = $1; 
												}
			|	retrnst							{ $$ = $1; }
			|	GOTO EXPR						{
													/* �b�� */ 
													$1->token_str = ":goto" + $2->token_str + ";\n" + $1->get_format_comment() + "\n";
													$$ = $1; 
												}
			|	switchst						{ $$ = $1; }
			;

single_line_member	:	ifst							{ $$ = $1; }
					|	forst							{ $$ = $1; }
					|	dowhilest						{ $$ = $1; }
					|	any_other						{ $$ = $1; }
					|	BREAK							{ 
															/* �b�� */
															$1->token_str = ":break;\n";
															$$ = $1; 
														}
					|	CONTINUE						{
															/* �b�� */ 
															$1->token_str = ":continue;\n";
															$$ = $1; 
														}
					|	retrnst							{ $$ = $1; }
					|	GOTO EXPR						{
															/* �b�� */ 
															$1->token_str = ":goto" + $2->token_str + ";\n" + $1->get_format_comment() + "\n";
															$$ = $1; 
														}
					|	switchst						{ $$ = $1; }
					;

ifst		: IF EXPR block						{
													$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "endif\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
			| IF EXPR block ELSE block			{
													$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "else\n"
																		+ $4->get_format_comment() + "\n"
																		+ $5->token_str + "\n"
																		+ "endif\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
			| IF EXPR block ELSE ifst			{
													$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "elseif\n"
																		+ $4->get_format_comment() + "\n"
																		+ $5->token_str + "\n";
																		/* ������I�[�L���� ifst �� endif���Ă���͂��Ȃ̂� �����ł� endif ���Ȃ� */
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
			| IF EXPR single_line_member		{
													$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "endif\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
			| IF EXPR single_line_member ELSE single_line_member		{
													$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "else\n"
																		+ $4->get_format_comment() + "\n"
																		+ $5->token_str + "\n"
																		+ "endif\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
			| IF EXPR single_line_member ELSE ifst		{
													$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "elseif\n"
																		+ $4->get_format_comment() + "\n"
																		+ $5->token_str + "\n";
																		/* ������I�[�L���� ifst �� endif���Ă���͂��Ȃ̂� �����ł� endif ���Ȃ� */
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
			;

forst   :   FOR EXPR block						{
													$1->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
		|	WHILE EXPR block					{
													$1->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
		|	FOR EXPR single_line_member			{
													$1->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
		|	WHILE EXPR single_line_member		{
													$1->token_str = 	"while (" + $2->token_str + ")\n" 
																		+ $1->get_format_comment() + "\n" 
																		+ $3->token_str + "\n"
																		+ "end while\n";
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
												}
        ;

dowhilest	: DO block WHILE EXPR			{
													$1->token_str = 	"repeat\n"
																		+ $1->get_format_comment() + "\n" 
																		+ $2->token_str + "\n" 
																		+ "repeat while(" + $4->token_str + ")\n"
																		+ $3->get_format_comment() + "\n" ;
													$1->comment = "";	/* �R�����g�͏����Ă��� */
													$$ = $1;
											}
			;

switchst	: SWITCH EXPR BRACE casest END_BRACE	 {
														$1->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $4->token_str + "\n"
																			+ "endif\n";
														$1->comment = "";	/* �R�����g�͏����Ă��� */
														$$ = $1;
													}
			;

/* case ���A�����ĕ���ł���Ƃ��̃p�^�[�� */
case_set_expr : CASE EXPR							{
														$1->token_str 	= 	"(" + $2->token_str + ")";
														/* �R�����g�� case �����L���Ȃ̂ŁA�폜���Ȃ� */
														$$ = $1;
													}
			| case_set_expr CASE EXPR 				{
														$1->token_str 	= 	"(" + $1->token_str + ") or (" + $3->token_str + ")";
														$1->comment		=	$1->comment  + "\n" + $3->comment;
														$$ = $1;
													}
			;
			
casest		: case_set_expr codes					{
														$1->token_str = 	"elseif (" + $1->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $2->token_str + "\n";
														$1->comment = "";	/* �R�����g�͏����Ă��� */
														$$ = $1;
													}
			| case_set_expr codes casest			{
														$1->token_str = 	"elseif (" + $1->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $2->token_str + "\n"
																			+ $3->token_str + "\n";
														$1->comment = "";	/* �R�����g�͏����Ă��� */
														$$ = $1;
													}
			| casest DEFAULT codes					{
														$1->token_str = 	$1->token_str + "\n"
																			+ "else\n"
																			+ $2->get_format_comment()
																			+ $3->token_str + "\n";
														$1->comment = "";	/* �R�����g�͏����Ă��� */
														$$ = $1;
													}
			| case_set_expr DEFAULT codes			{
														$1->token_str = 	"elseif (" + $1->token_str + ") then (true)\n" 
																			+ $1->get_format_comment() + "\n" 
																			+ $3->token_str + "\n";
																			+ "else\n"
																			+ $2->get_format_comment() + "\n"
																			+ $3->token_str + "\n";
														$1->comment = "";	/* �R�����g�͏����Ă��� */
														$$ = $1;
													}
			;

/* ���̑��͂��̂܂܍ڂ��� */
any_other	:	ANY_OTHER		{
									$1->token_str = 	":" + $1->token_str + ";\n" 
														+ $1->get_format_comment() + "\n";
									$1->comment = "";	/* �R�����g�͏����Ă��� */
									$$ = $1;
								}
			;

/* return */
retrnst		:	RETRN EXPR		{
									$1->token_str = 	":return " + $2->token_str + ";\n" 
														+ $1->get_format_comment() + "\n";
									$1->comment = "";	/* �R�����g�͏����Ă��� */
									$$ = $1;
								}
			;
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
	fprintf(output_file_ptr, "%s", msg.c_str()); // �t�@�C���ɏ���
}
