%{
#include "c2puml.tab.h"
#include <string.h>
extern void push_synbol_string(char * smbl, int size);
extern void clear_synbol_string();
extern FILE * output_file_ptr;
int g_bracket_cnt = 0;

enum {
	C_UNRELATED_ELSE = 0,
	C_WITH_ELSE_SINGLE,
	C_WITH_ELSE_BLOCK,
};

enum {
	C_UNRELATED_WHILE = 0,
	C_WITH_BLOCK,
	C_WITHOUT_BLOCK,
};

// if節がどのように始まったかを記憶しておくフラグ、現在のブロックが { ありか、なしかを示す。
// { の無いシングル if の場合、１行後にすぐ endif もしくは else しないといけない。
int is_else_in_if = C_UNRELATED_ELSE;

// for節がどのように始まったかを記憶しておくフラグ、現在のブロックが { ありか、なしかを示す。
// { の無いシングル for の場合、１行後にすぐ endforしなければならない。
int is_block_of_for = C_UNRELATED_WHILE;

/* 指定した任意の1文字を削除する */
void remove_char(char target, char converted_char, char* in_str, int in_length){
	for(int i=0;i<in_length;i++){
		if( in_str[i] == target ){
			in_str[i] = converted_char;
		}
	}
}

/* 改行を削除する */
void remove_line_feed(const char* in_str, int in_length, char* out_str, int *out_length){
	sprintf(out_str, "%s", in_str);
	remove_char('\n', ' ', out_str, in_length);
	remove_char('\r', ' ', out_str, in_length);
}

/* ブロック情報保持スタック */
typedef enum {
	C_BLOCK_TYPE_NONE = 0,
	C_BLOCK_TYPE_FUNCTION,
	C_BLOCK_TYPE_IF,
	C_BLOCK_TYPE_FOR,
	C_BLOCK_TYPE_WHILE,
	C_BLOCK_TYPE_ELSE,
	C_BLOCK_TYPE_WRONG = -10,
} t_blocktype;
#define MAX_OF_BLOCK_STACK	(128)



t_blocktype block_stack[MAX_OF_BLOCK_STACK] = {C_BLOCK_TYPE_NONE};
int block_stack_index = 0;

void push_block_stack(t_blocktype stc)	{
		printf("*************************** [push] blockstack[%d->%d]=%d\n", block_stack_index, block_stack_index+1, stc);
		block_stack[++	block_stack_index] = stc;
	}
t_blocktype pop_block_stack()	{
	printf("*************************** [pop] blockstack[%d->%d]=%d\n", block_stack_index, block_stack_index-1, block_stack[block_stack_index]);
	if(block_stack_index==0){ return C_BLOCK_TYPE_WRONG; }
	return block_stack[block_stack_index--];
	}

t_blocktype get_block_stack()	{
	return block_stack[block_stack_index];
}
%}

white       [ |\t|\r|\n]
floating    [0-9]+\.[0-9]+
integer     [0-9]+
symbol      [=+\-\^*/();\n]
letter      [_[:alpha:]][_[:alnum:]]*
other       .

%x STRING
%x CHARA
%x ST_COMMENT
%x ST_LINE_COMMENT
%x ST_IF_EXPR
%x ST_FOR_EXPR
%x ST_1LINE_FOR
%x ST_WHILE_EXPR
%x ST_ANY_OTHER

TYPE            void|char|int|float|double|short|long|signed|unsigned|sizeof
STO_CLASS       extern|static|auto|register
TYPEDEF         typedef|enum|struct|union
CONTROL         if|else|for|while|do|switch|case|default|goto|return|break|continue
TYPE_QUAL       const|volatile
C_KEYWORDS      {TYPE}|{STO_CLASS}|{TYPEDEF}|{TYPE_QUAL}

ALLOC           new|delete
BOOL            bool|false|true
EXCEPTION       try|catch|throw
CLASS           class|public|protected|private|friend|explicit|mutable|inline|virtual|operator|this
CAST            static_cast|reinterpret_cast|const_cast|dynamic_cast
TEMPLATE        template|typename
NAMESPACE       namespace|using
TYPEID          typeid

%%

{white}+

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* 関数宣言を検出して通知する
	*	責務：関数宣言を push_synbol_string し、return(FUNCTION)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
{C_KEYWORDS}*{white}*{letter}+{white}*\(.*\){white}*\{	{
												char buf[yyleng+1];
												int buf_leng = yyleng;
												if(block_stack_index != 0) {
													/* 関数宣言は stack 0 でのみ検出
													（もうちょっとうまいやり方ないかなあ・・・） */
													printf("[Info] function def rejected.\n");
													REJECT;
												} else {
													remove_line_feed(yytext, yyleng, buf, &buf_leng);
													printf("start function:%s\n", buf);
													push_synbol_string(buf, buf_leng);
													push_block_stack(C_BLOCK_TYPE_FUNCTION);
													return(FUNCTION);
												}
											}

#.+[\r\n]

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* if条件を検出して通知する
	*	責務：if条件式を push_synbol_string し、BEGIN(INITIAL) し、return(IF)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}

%{  /*********************************************************************************
	* if条件式検出開始
	*/ %}
if{white}*\(				{
								printf("start if g_bracket_cnt=%d\n", g_bracket_cnt);
								BEGIN(ST_IF_EXPR); 
								g_bracket_cnt++; 
							}

%{  /*********************************************************************************
	* if条件式検出中の ( 検出. g_bracke_cntが0になるまで式が完結したとはみなさない
	*/ %}
<ST_IF_EXPR>\(				{
								g_bracket_cnt++;
								// printf("if bracket cnt=%d\n", g_bracket_cnt);
								yymore();
							}

%{  /*********************************************************************************
	* if条件式検出中の ) -> { 検出. if条件式検出中に{ が入ってくることはないので、if条件式検出完了
	*/ %}
<ST_IF_EXPR>\){white}*\{	{
								g_bracket_cnt--;
								if(g_bracket_cnt == 0) {
									// if条件式検出完了
									char buf[yyleng+1];
									int buf_leng = yyleng;

									printf("bracket closed\n");
									printf("if block\n");
	
									// if block を1段積む
									push_block_stack(C_BLOCK_TYPE_IF);
									// 改行除去して push_symbol_string する
									remove_line_feed(yytext, yyleng, buf, &buf_leng);
									push_synbol_string(buf, buf_leng);
									BEGIN(INITIAL);
									is_else_in_if = C_WITH_ELSE_BLOCK;
									return(IF);
								} else {
									// 通常ここに入ってくることはないはずだが・・・
									printf(" ********* [Error!!] bracket more! ********* \n");
									yymore();
								}
							}

%{  /*********************************************************************************
	* if条件式中にコメント
	*/ %}
<ST_IF_EXPR>"/*".*"*/"	{
								// とりあえず無視。
							}

%{  /*********************************************************************************
	* if条件式検出中の ) 検出. g_bracket_cnt == 0 ならば、if条件式検出完了
	* { が検出されないので { 無し1行 if文。 ほんとこれやめてほしい。
	*/ %}
<ST_IF_EXPR>\)   			{
								g_bracket_cnt--;
								if(g_bracket_cnt == 0) {
									// if条件式検出完了
									char buf[yyleng+1];
									int buf_leng = yyleng;

									printf("bracket closed\n");
									printf("if single\n");

									// if block を1段積む
									push_block_stack(C_BLOCK_TYPE_IF);
									// 改行除去して push_symbol_string する
									remove_line_feed(yytext, yyleng, buf, &buf_leng);
									push_synbol_string(buf, buf_leng);
									BEGIN(INITIAL);
									is_else_in_if = C_WITH_ELSE_SINGLE;
									return(IF);
								} else {
									yymore();
								}
							}

%{  /*********************************************************************************
	*  それ以外の文字。 if条件式を構成する文字であるため、普通に yymore() する。
	*/ %}
<ST_IF_EXPR>.  				{
								yymore();
							}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* else節検出して通知する、else if はここでは扱わない
	*	責務：return(else)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
%{  /*********************************************************************************
	*  { つき else の検出
	*/ %}
else{white}*\{				{
								printf("start else block\n");
								pop_block_stack();
								push_block_stack(C_BLOCK_TYPE_ELSE);
								yymore();
								return(ELSE);
							}
%{  /*********************************************************************************
	*  { なし else の検出
	*/ %}
else						{
								// if条件式検出完了
								char buf[yyleng+1];
								int buf_leng = yyleng;

								printf("start else single\n");
								pop_block_stack();

								// if block を1段積む
								push_block_stack(C_BLOCK_TYPE_IF);
								// 改行除去して push_symbol_string する
								remove_line_feed(yytext, yyleng, buf, &buf_leng);
								push_synbol_string(buf, buf_leng);

								is_else_in_if = C_WITH_ELSE_SINGLE;

								push_block_stack(C_BLOCK_TYPE_ELSE);
								return(ELSE);
							}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* else if 検出して通知する
	*	責務：if条件式を push_synbol_string し、BEGIN(INITIAL) し、return(elseif)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
%{  /*********************************************************************************
	*  { つき else if の検出
	*  この関数がないと、 ifブロック中の } を受けた時点で end if を出力してしまう。
	*/ %}
else{white}+if{white}*\(.*\){white}*\{							{
								printf("Start else if block\n");
								pop_block_stack();
								push_block_stack(C_BLOCK_TYPE_ELSE);
								char buf[yyleng+1];
								int buf_leng = yyleng;
								remove_line_feed(yytext, yyleng, buf, &buf_leng);
								printf("else if(s):        (%s) len=%d \n", buf, buf_leng);
								BEGIN(INITIAL);
								push_synbol_string(buf, buf_leng);
								return(ELSE_IF);
							}
%{  /*********************************************************************************
	*  { なし else if の検出
	*/ %}
else{white}+if{white}*\(.*\){white}*(\r|\n)							{	
								printf("Start else if block\n");
								pop_block_stack();
								push_block_stack(C_BLOCK_TYPE_ELSE);
								char buf[yyleng+1];
								int buf_leng = yyleng;
								remove_line_feed(yytext, yyleng, buf, &buf_leng);
								printf("else if(s):        (%s) len=%d \n", buf, buf_leng);
								BEGIN(INITIAL);
								push_synbol_string(buf, buf_leng);

								is_else_in_if = C_WITH_ELSE_SINGLE;
								return(ELSE_IF);
							}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* for 検出して通知する
	*	責務：for条件式を push_synbol_string し、BEGIN(INITIAL) し、return(FOR)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
%{  /*********************************************************************************
	* for条件式検出開始
	*/ %}
for{white}*\(				{
								printf("start for g_bracket_cnt=%d\n", g_bracket_cnt);
								BEGIN(ST_FOR_EXPR);
								g_bracket_cnt++;
							}
%{  /*********************************************************************************
	* for条件式検出中の ( 検出. g_bracke_cntが0になるまで式が完結したとはみなさない
	*/ %}
<ST_FOR_EXPR>\(				{
								g_bracket_cnt++;
								printf("for bracket cnt=%d", g_bracket_cnt);
								yymore();
							}
%{  /*********************************************************************************
	* for条件式検出中の ) -> { 検出. for条件式検出中に{ が入ってくることはないので、for条件式検出完了
	*/ %}
<ST_FOR_EXPR>\){white}*\{	{
								printf("for block\n");
								printf("for(s):(%s) len=%d g_bracket_cnt = %d\n", yytext, yyleng, g_bracket_cnt);
								g_bracket_cnt--;
								if(g_bracket_cnt == 0) {
									push_block_stack(C_BLOCK_TYPE_FOR);
									char buf[yyleng+1];
									int buf_leng = yyleng;
									printf("bracket closed\n");
									remove_line_feed(yytext, yyleng, buf, &buf_leng);
									BEGIN(INITIAL); push_synbol_string(buf, buf_leng);
									is_block_of_for = C_WITH_BLOCK;
									return(FOR);
								} else {
									printf("bracket more!\n");
									yymore();
								}
							}

%{  /*********************************************************************************
	* for条件式検出中の ) 検出.  g_bracket_cnt == 0 ならば、for条件式検出完了
	* { が検出されないので { 無し1行 for文。 ほんとこれやめてほしい。
	*/ %}
<ST_FOR_EXPR>\)   			{
								g_bracket_cnt--;
								if(g_bracket_cnt == 0) {
									printf("for(s): (%s) len=%d g_bracket_cnt = %d\n", yytext, yyleng, g_bracket_cnt);
									char buf[yyleng+1];
									int buf_leng = yyleng;
									printf("bracket closed\n");
									remove_line_feed(yytext, yyleng, buf, &buf_leng);
									BEGIN(INITIAL);
									push_synbol_string(buf, buf_leng);
									is_block_of_for = C_WITHOUT_BLOCK;
									return(FOR);
								} else {
									printf("bracket more!\n");
									yymore();
								}
							}

%{  /*********************************************************************************
	* for条件式中にコメント
	*/ %}
<ST_FOR_EXPR>"/*".*"*/"		{
								// とりあえず無視。
							}

%{  /*********************************************************************************
	*  それ以外の文字。 for条件式を構成する文字であるため、普通に yymore() する。
	*/ %}
<ST_FOR_EXPR>.  			{	yymore(); }

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* for 検出して通知する
	*	責務：for条件式を push_synbol_string し、BEGIN(INITIAL) し、return(FOR)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
%{  /*********************************************************************************
	* while条件式検出開始
	*/ %}
while{white}*\(				{
								printf("start for g_bracket_cnt=%d\n", g_bracket_cnt);
								BEGIN(ST_WHILE_EXPR);
								g_bracket_cnt++;
							}
%{  /*********************************************************************************
	* while 条件式検出中の ( 検出. g_bracke_cntが0になるまで式が完結したとはみなさない
	*/ %}
<ST_WHILE_EXPR>\(			{
								g_bracket_cnt++;
								printf("while bracket cnt=%d", g_bracket_cnt);
								yymore();
							}
%{  /*********************************************************************************
	* while条件式検出中の ) -> { 検出. whilte条件式検出中に{ が入ってくることはないので、while条件式検出完了
	*/ %}
<ST_WHILE_EXPR>\){white}*\{	{
								g_bracket_cnt--;
								if(g_bracket_cnt == 0) {
									printf("while block\n");
									printf("for(s): (%s) len=%d g_bracket_cnt = %d\n", yytext, yyleng, g_bracket_cnt);
									push_block_stack(C_BLOCK_TYPE_WHILE);
									char buf[yyleng+1];
									int buf_leng = yyleng;
									remove_line_feed(yytext, yyleng, buf, &buf_leng);
									BEGIN(INITIAL); push_synbol_string(buf, buf_leng);
									is_block_of_for = C_WITH_BLOCK;
									return(FOR);
								} else {
									printf("bracket more!\n");
									yymore();
								}
							}

%{  /*********************************************************************************
	* while 条件式検出中の ) 検出.  g_bracket_cnt == 0 ならば、while条件式検出完了
	* { が検出されないので { 無し1行 while 文。 ほんとこれやめてほしい。
	*/ %}
<ST_WHILE_EXPR>\)   		{
								g_bracket_cnt--;
								if(g_bracket_cnt == 0) {
									printf("while single\n");
									printf("for(s): (%s) len=%d g_bracket_cnt = %d\n", yytext, yyleng, g_bracket_cnt);
									push_block_stack(C_BLOCK_TYPE_WHILE);
									char buf[yyleng+1];
									int buf_leng = yyleng;
									remove_line_feed(yytext, yyleng, buf, &buf_leng);
									BEGIN(INITIAL); push_synbol_string(buf, buf_leng);
									is_block_of_for = C_WITHOUT_BLOCK;
									return(FOR);
								} else {
									printf("bracket more!\n");
									yymore();
								}
							}

%{  /*********************************************************************************
	* while 条件式中にコメント
	*/ %}
<ST_WHILE_EXPR>"/*".*"*/"		{
								// とりあえず無視。
							}


%{  /*********************************************************************************
	*  それ以外の文字。 while条件式を構成する文字であるため、普通に yymore() する。
	*/ %}
<ST_WHILE_EXPR>.  			{	yymore(); }

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* コメントの検出処理
	*	責務：コメント内容を push_synbol_string し、BEGIN(INITIAL) し、return(ST_COMMENT)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
"/*"            		{	BEGIN(ST_COMMENT); yymore();	}
<ST_COMMENT>"*/"   		{	printf("Comment(s):        (%s) len=%d\n", yytext, yyleng); BEGIN(INITIAL); push_synbol_string(yytext, yyleng); return(COMMENT); }
<ST_COMMENT>"*"    		{	yymore(); }
<ST_COMMENT>[^*]+  		{	yymore(); }

"//".*(\r|\n)            		{	printf("Comment(s):        (%s) len=%d\n", yytext, yyleng); push_synbol_string(yytext, yyleng); return(COMMENT); }


%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* switch case処理
	*	責務：switch条件式を push_synbol_string し、BEGIN(INITIAL) し、return(IF)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
%{  /*********************************************************************************
	*  { つき switch 開始を検出する。
	*/ %}
switch{white}*\(.+\){white}*\{		{
										char buf[yyleng+1];

										printf("Start switch case block\n");
										push_block_stack(C_BLOCK_TYPE_IF);
										// switch条件式検出完了
										int buf_leng = yyleng;

										// if block を1段積む
										push_block_stack(C_BLOCK_TYPE_IF);
										// 改行除去して push_symbol_string する
										remove_line_feed(yytext, yyleng, buf, &buf_leng);
										push_synbol_string(buf, buf_leng);
										BEGIN(INITIAL);
										// is_else_in_if = C_WITH_ELSE_BLOCK;
										return(IF);
									}

%{  /*********************************************************************************
	*  caseを検出する。
	*   else if 条件式をpush_synbol_string し、BEGIN(INITIAL) し、return(ELSE_IF)する 
	*/ %}
case{white}+.+:			{
							char buf[yyleng+1];
							int buf_leng = yyleng;

							printf("Start switch case in Case block\n");
							pop_block_stack();
							push_block_stack(C_BLOCK_TYPE_ELSE);
							remove_line_feed(yytext, yyleng, buf, &buf_leng);
							printf("else if(s):        (%s) len=%d \n", buf, buf_leng);
							BEGIN(INITIAL); push_synbol_string(buf, buf_leng);
							return(ELSE_IF);
						}
%{  /*********************************************************************************
	*  default句を検出する。
	*   return(ELSE)する 
	*/ %}

default{white}*:		{
							printf("Start switch case in default block\n");
							pop_block_stack();
							push_block_stack(C_BLOCK_TYPE_ELSE);
							return(ELSE);
						}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* 閉じカッコ } 処理 blockの終端処理
	*	責務：現在の block_stack からpopし、閉じた block の種類に応じて適切な終端処理を行う
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
\}   					{
							printf("defind brace\n");
							/* block stack が0なのに終端しようとした、破綻している */
							if(block_stack_index==0){
								yyerror ("[ERROR] block stack wrong\n");
								
							}
							switch(pop_block_stack()){
								case C_BLOCK_TYPE_FUNCTION:
									printf("function block closed\n");
									push_synbol_string("stop\n@enduml", sizeof("stop\n@enduml"));
									return(ENDFUNCTION);
									break;
								case C_BLOCK_TYPE_IF:
								case C_BLOCK_TYPE_ELSE:
									printf("if block closed\n");
									return(ENDIF);
									break;
								case C_BLOCK_TYPE_FOR:
								case C_BLOCK_TYPE_WHILE:
									printf("while block closed\n");
									return(ENDWHILE);
									break;
								default:
									yyerror("[ERROR] invalid block type poped.\n");
									break;
							}
						}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* Any other 系処理。
	*	責務：1行まるごと push_synbol_string し、BEGIN(INITIAL) し、return(IF)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
%{  /*********************************************************************************
	*  ST_ANY_OTHER状態を開始する。 １行まるごとを yytext に取り込むために yymore する。
	*/ %}
.					{
						BEGIN(ST_ANY_OTHER);
						yymore();
					}

%{  /*********************************************************************************
	*  なんか入ってきたら取り込む。コンマを終端記号として１行を終える。
	*/ %}
<ST_ANY_OTHER>.*;	{
						printf("any other(s):        (%s) len=%d is_else_in_if=%d is_block_of_for=%d \n", yytext, yyleng, is_else_in_if, is_block_of_for);
						BEGIN(INITIAL); 
						push_synbol_string(yytext, yyleng); 
						/* 現在何のブロック上いるのかに応じて処理を変える */
						switch( get_block_stack() ) {
							case C_BLOCK_TYPE_WHILE:
							case C_BLOCK_TYPE_FOR:
								/* for/while block 上であれば、single for の処理 */
								if(is_block_of_for==C_WITHOUT_BLOCK) {
									printf("#### %s(%d)\n", __func__, __LINE__);
									/* single while(or for)なので、endwhileする */
									is_block_of_for=C_UNRELATED_WHILE;
									return(ENDWHILE_SINGLE);
								}
							break;
							case C_BLOCK_TYPE_IF:
							case C_BLOCK_TYPE_ELSE:
								/* if/else block 上であれば、single if の処理 */
								if(is_else_in_if==C_WITH_ELSE_SINGLE) {
									printf("#### %s(%d)\n", __func__, __LINE__);
									/* single if なので endifする */
									is_else_in_if=C_UNRELATED_WHILE;
									return(ENDIF_SINGLE);
								}
							break;
							case C_BLOCK_TYPE_FUNCTION:
							default:
								/* do nothing. */
								break;
						}
						printf("#### %s(%d)\n", __func__, __LINE__);
						return(ANY_OTHER);
					}

%{  /*********************************************************************************
	*  なんか入ってきた後、else と続いていたら、if節のあとの 1行 else とみなす。
	*/ %}
<ST_ANY_OTHER>.*;{white}*else					{
						char buf[yyleng+1];
						int buf_leng = yyleng;

						// printf("any other(s):        (%s) len=%d is_else_in_if=%d\n", yytext, yyleng, is_else_in_if);
						
						BEGIN(INITIAL);
						remove_line_feed(yytext, yyleng, buf, &buf_leng);
						push_synbol_string(buf, buf_leng); 
						
						if(is_else_in_if==C_WITH_ELSE_SINGLE) {
							/* single if なので elseする */
							return(ELSE);
						}
						return(ANY_OTHER);
					}

%{  /*********************************************************************************
	*  なんか入ってきた後、else if と続いていたら、if節のあとの 1行 else ifとみなす。
	*/ %}
<ST_ANY_OTHER>.*;{white}*else{white}+if{white}*\(					{
						char buf[yyleng+1];
						int buf_leng = yyleng;
						remove_line_feed(yytext, yyleng, buf, &buf_leng);
						push_synbol_string(buf, buf_leng); 
						printf("any other(s):        (%s) len=%d is_else_in_if=%d\n", buf, buf_leng, is_else_in_if);
						printf("start if                           g_bracket_cnt=%d\n", g_bracket_cnt);
						BEGIN(ST_IF_EXPR);
						g_bracket_cnt++;
						return(ANY_OTHER);
					}


%{  /*********************************************************************************
	*  それ以外の何かが入ってきた。
	*/ %}
<ST_ANY_OTHER>. {	yymore(); }

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* ファイル終端処理。ここが終わり。 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
<<EOF>>			{ printf("end of file\n"); return(END_OF_FILE); }

%%

#define C_OUTPUT_FILE_MAX    (256)
extern int is_comment_locate_after;			/* コメントの挿入位置を1行遅らせる 		*/
extern int is_generate_global_scope_code;	/* 関数の外に書かれたコードを出力する 	*/

/*****************************************************************************************************************************************************************
	エントリーポイント
******************************************************************************************************************************************************************/
int main(int argc, char *argv[])
{
    FILE * fptr_r = NULL;
    FILE * fptr_w = NULL;
    int i;
    char opt;
    char output_filne_name[C_OUTPUT_FILE_MAX] = {0};
    char input_filne_name[C_OUTPUT_FILE_MAX] = {0};

    /* default name. */
    strncpy(output_filne_name, "out.puml", C_OUTPUT_FILE_MAX);

    for(i = 1; i < argc; ++i){
        if(*argv[i] == '-'){
            opt = *(argv[i]+1);
            switch(opt){
                case 'o':
                    strncpy(output_filne_name, argv[i+1], C_OUTPUT_FILE_MAX);
                    break;
                case 'b':
                	/* コメント逆順設定 */
                    is_comment_locate_after = 0;
                    break;
                case 'g':
                	/* 関数の外に書かれたコードを出力する */
                    is_generate_global_scope_code = 1;
                    break;
                default:
                    printf("Undefined Option.\n");
                    break;
            }
            i++;
        } else {
            sprintf(input_filne_name, "%s", argv[i]);
        }
    }
    /* input filename error check */
    if(strlen(input_filne_name) == 0) {
        printf("input filename error.\n");
        exit(1);
    }
    /* Read file pointer */
    if ((fptr_r = fopen(input_filne_name, "r"))==NULL) {
        printf("file open failed.\n");
        exit(1);
    }
    
    /* write file pointer */
    if ((fptr_w = fopen(output_filne_name, "w"))==NULL) {
        printf("output file open failed.\n");
        exit(1);
    }

    /* 構文解析関数 yyparse */
    yyin = fptr_r;
    output_file_ptr = fptr_w;
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}
