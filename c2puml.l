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
int is_else_in_if = C_UNRELATED_ELSE;
#define process_if_block(__with_else)	({																				\
								printf("if(s):        (%s) len=%d g_bracket_cnt = %d\n", yytext, yyleng, g_bracket_cnt);						\
								g_bracket_cnt--;															\
								if(g_bracket_cnt == 0) {													\
									char buf[yyleng+1];														\
									int buf_leng = yyleng;													\
									printf("bracket closed\n");												\
									remove_line_feed(yytext, yyleng, buf, &buf_leng);						\
									BEGIN(INITIAL); push_synbol_string(buf, buf_leng);						\
									is_else_in_if = __with_else;											\
									return(IF);																\
								} else {                                                                    \
									printf("bracket more!\n");                                              \
									yymore();                                                               \
								}																			\
							})
							
enum {
	C_UNRELATED_WHILE = 0,
	C_WITH_BLOCK,
	C_WITHOUT_BLOCK,
};

void remove_char(char target, char converted_char, char* in_str, int in_length){
	for(int i=0;i<in_length;i++){
		if( in_str[i] == target ){
			in_str[i] = converted_char;
		}
	}
}
void remove_line_feed(const char* in_str, int in_length, char* out_str, int *out_length){
	sprintf(out_str, "%s", in_str);
	remove_char('\n', ' ', out_str, in_length);
	remove_char('\r', ' ', out_str, in_length);
}

int is_block_of_for = C_UNRELATED_WHILE;
#define process_for_block(__with_block)	({																	\
								printf("for(s):        (%s) len=%d g_bracket_cnt = %d\n", yytext, yyleng, g_bracket_cnt);						\
								g_bracket_cnt--;															\
								if(g_bracket_cnt == 0) {													\
									char buf[yyleng+1];														\
									int buf_leng = yyleng;													\
									printf("bracket closed\n");												\
									remove_line_feed(yytext, yyleng, buf, &buf_leng);						\
									BEGIN(INITIAL); push_synbol_string(buf, buf_leng);						\
									is_block_of_for = __with_block;											\
									return(FOR);															\
								} else {                                                                    \
									printf("bracket more!\n");                                              \
									yymore();                                                               \
								}																			\
							})

#define process_elseif_block()	({																\
								char buf[yyleng+1];														\
								int buf_leng = yyleng;													\
								remove_line_feed(yytext, yyleng, buf, &buf_leng);						\
								printf("else if(s):        (%s) len=%d \n", buf, buf_leng);					\
								BEGIN(INITIAL); push_synbol_string(buf, buf_leng);						\
								return(ELSE_IF);																\
							})


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
C_KEYWORDS      {TYPE}|{STO_CLASS}|{TYPEDEF}|{CONTROL}|{TYPE_QUAL}

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

{C_KEYWORDS}*{white}*{letter}+{white}*\(.*\){white}*\{	{
												char buf[yyleng+1];
												int buf_leng = yyleng;
												if(block_stack_index!=0) {
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

if{white}*\(				{ 	printf("start if                           g_bracket_cnt=%d\n", g_bracket_cnt); BEGIN(ST_IF_EXPR); yymore(); g_bracket_cnt++; }
<ST_IF_EXPR>\(			{	g_bracket_cnt++; printf("if bracket                      cnt=%d", g_bracket_cnt); yymore(); }
<ST_IF_EXPR>\){white}*\{	{	printf("if block\n"); push_block_stack(C_BLOCK_TYPE_IF); process_if_block(C_WITH_ELSE_BLOCK); }
<ST_IF_EXPR>\)   		{	printf("if single\n"); process_if_block(C_WITH_ELSE_SINGLE);	}
<ST_IF_EXPR>\){white}*else	{	printf("if single with else\n"); process_if_block(C_WITH_ELSE_SINGLE);	}
<ST_IF_EXPR>.  			{	yymore(); }

for{white}*\(			{ 	printf("start for                          g_bracket_cnt=%d\n", g_bracket_cnt); BEGIN(ST_FOR_EXPR); yymore(); g_bracket_cnt++; }
<ST_FOR_EXPR>\(			{	g_bracket_cnt++; printf("for                          bracket cnt=%d", g_bracket_cnt); yymore(); }
<ST_FOR_EXPR>\){white}*\{	{	printf("for block\n"); push_block_stack(C_BLOCK_TYPE_FOR); process_for_block(C_WITH_BLOCK); }
<ST_FOR_EXPR>\)   		{	printf("for single\n"); process_for_block(C_WITHOUT_BLOCK);	}
<ST_FOR_EXPR>.  			{	yymore(); }

while{white}*\(			{ 	printf("start for                     g_bracket_cnt=%d\n", g_bracket_cnt); BEGIN(ST_WHILE_EXPR); yymore(); g_bracket_cnt++; }
<ST_WHILE_EXPR>\(			{	g_bracket_cnt++; printf("while bracket                      cnt=%d", g_bracket_cnt); yymore(); }
<ST_WHILE_EXPR>\){white}*\{	{	printf("while block\n"); push_block_stack(C_BLOCK_TYPE_WHILE); process_for_block(C_WITH_BLOCK); }
<ST_WHILE_EXPR>\)   		{	printf("while single\n"); process_for_block(C_WITHOUT_BLOCK);	}
<ST_WHILE_EXPR>.  			{	yymore(); }

"/*"            		{	BEGIN(ST_COMMENT); yymore();	}
<ST_COMMENT>"*/"   		{	printf("Comment(s):        (%s) len=%d\n", yytext, yyleng); BEGIN(INITIAL); push_synbol_string(yytext, yyleng); return(COMMENT); }
<ST_COMMENT>"*"    		{	yymore(); }
<ST_COMMENT>[^*]+  		{	yymore(); }

"//".*(\r|\n)            		{	printf("Comment(s):        (%s) len=%d\n", yytext, yyleng); push_synbol_string(yytext, yyleng); return(COMMENT); }

\}{white}*else{white}*\{		{ 	printf("start else block\n");
							pop_block_stack();
							push_block_stack(C_BLOCK_TYPE_ELSE);
							printf("else(s):        (%s) len=%d\n", yytext, yyleng); 
							push_synbol_string("else", sizeof("else"));
							yymore();
							return(ELSE); }

\}{white}*else{white}+if{white}*\(.*\){white}*\{		{	printf("Start else if block\n");
						pop_block_stack();
						push_block_stack(C_BLOCK_TYPE_ELSE);
						process_elseif_block();
						}

switch{white}*\(.+\){white}*\{		{	printf("Start switch case block\n"); push_block_stack(C_BLOCK_TYPE_IF); g_bracket_cnt++; process_if_block(C_WITH_ELSE_BLOCK); }
case{white}+.+:			{	printf("Start switch case in Case block\n");
							pop_block_stack();
							push_block_stack(C_BLOCK_TYPE_ELSE);
							process_elseif_block();
						}
default{white}*:			{ 	printf("Start switch case in default block\n");
							pop_block_stack();
							push_block_stack(C_BLOCK_TYPE_ELSE);
							push_synbol_string("else", sizeof("else"));
							return(ELSE); }

\}   					{
							printf("defind brace\n");
							if(block_stack_index==0){
								printf("block stack wrong\n");
							}
							switch(pop_block_stack()){
								case C_BLOCK_TYPE_FUNCTION:
									printf("function block closed");
									push_synbol_string("stop\n@enduml", sizeof("stop\n@enduml"));
									return(ENDFUNCTION);
									break;
								case C_BLOCK_TYPE_IF:
								case C_BLOCK_TYPE_ELSE:
									printf("if block closed");
									return(ENDIF);
									break;
								case C_BLOCK_TYPE_FOR:
								case C_BLOCK_TYPE_WHILE:
									printf("while block closed");
									return(ENDWHILE);
									break;
								default:
									printf("whats wrong!?");
									break;
							}
						}

.				{	BEGIN(ST_ANY_OTHER); yymore();	}
<ST_ANY_OTHER>.*;	{	printf("any other(s):        (%s) len=%d is_else_in_if=%d\n", yytext, yyleng, is_else_in_if);
					BEGIN(INITIAL); 
					push_synbol_string(yytext, yyleng); 
					if(is_block_of_for==C_WITHOUT_BLOCK) { is_block_of_for=C_UNRELATED_WHILE; return(ENDWHILE_SINGLE); }
					if(is_else_in_if==C_WITH_ELSE_SINGLE) { is_else_in_if=C_UNRELATED_WHILE; return(ENDIF_SINGLE); }
					return(ANY_OTHER); }
<ST_ANY_OTHER>.*;{white}*else	{
					char buf[yyleng+1];
					int buf_leng = yyleng;
					printf("any other(s):        (%s) len=%d is_else_in_if=%d\n", yytext, yyleng, is_else_in_if);
					BEGIN(INITIAL); 
					remove_line_feed(yytext, yyleng, buf, &buf_leng);
					push_synbol_string(buf, buf_leng); 
					if(is_else_in_if==C_WITH_ELSE_SINGLE) {  return(ENDIF_SINGLE); }
					return(ANY_OTHER); }

<ST_ANY_OTHER>.*;{white}*else{white}+if{white}*\(	{
					char buf[yyleng+1];
					int buf_leng = yyleng;
					remove_line_feed(yytext, yyleng, buf, &buf_leng);
					push_synbol_string(buf, buf_leng); 
					printf("any other(s):        (%s) len=%d is_else_in_if=%d\n", buf, buf_leng, is_else_in_if);
					printf("start if                           g_bracket_cnt=%d\n", g_bracket_cnt);
					BEGIN(ST_IF_EXPR);
					g_bracket_cnt++;
					return(ANY_OTHER); }


<ST_ANY_OTHER>. {	yymore(); }

<<EOF>>			{ printf("end of file\n"); return(END_OF_FILE); }

%%

#define C_OUTPUT_FILE_MAX    (256)
extern int is_comment_locate_after;			/* コメントの挿入位置を1行遅らせる 		*/
extern int is_generate_global_scope_code;	/* 関数の外に書かれたコードを出力する 	*/
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

    for(i = 0; i < argc; ++i){
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
