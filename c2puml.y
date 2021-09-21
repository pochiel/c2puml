%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void output_to_file(char * smbl, int size);
void clear_synbol_string();

/* define�}�N�� */
#define C_MAX_SYNBOL_NAME	(1024)


/* �O���[�o���ϐ� */
int g_symbol_index = 0;
char synbol_name[C_MAX_SYNBOL_NAME];
FILE * output_file_ptr = NULL;

/* �O���[�o���ϐ��i�I�v�V���������j */
int is_comment_locate_after = 1;			/* �R�����g�̑}���ʒu��1�s�x�点�� */
int is_generate_global_scope_code = 0;		/* �֐��̊O�ɏ����ꂽ�R�[�h���o�͂��� */

/* �v���g�^�C�v�錾 */
void yyerror(const char* s);
int  yylex(void);

/******************************/
/* indent���`����ݏ���       */
/******************************/
int indent_level = 0;
#define C_INDENT_MAX	(128)
char indent_head[C_INDENT_MAX] = "";
char* get_indent_head(){
	int i=0;
	for(i=0;i<indent_level;i++){
		indent_head[i] = '\t';
	}
	indent_head[indent_level] = '\0';
	return indent_head;
}
#define INDENT_STR	(get_indent_head())

void push_indent() { indent_level++; }
void pop_indent() { 
			if( indent_level > 0 ){
				indent_level--; 
			} else {
				printf("*** [ERROR] Wrong Indent Level Pop!! ***\n");			
			}
}

int is_in_function(){
	return (indent_level>0);
}

/******************************/
/* �R�����g��s��������ݏ��� */
/******************************/
typedef struct __t_comment_list {
	char* msg;
	int size;
	struct __t_comment_list * next;
} t_comment_list;

t_comment_list * g_first_comment_node = NULL;
void backup_comment_message(char* msg_ptr, int len){
	t_comment_list * node = g_first_comment_node;
	/* ������������܂Ń��X�g�����ǂ� */
	while(node != NULL){
		if(node->next == NULL) break;
		node = node->next;
	}
	/* �V�����m�[�h�𐶐����A�o�^ */
	if(node == NULL){
		g_first_comment_node = malloc(sizeof(t_comment_list));
		node = g_first_comment_node;
	} else {
		node->next = malloc(sizeof(t_comment_list));
	}
	node->msg = malloc(len + 1);
	strncpy(node->msg, msg_ptr, (len));
	node->msg[len] = '\0';
	node->size = len;
	node->next = NULL;
}

void output_all_comment(){
	t_comment_list * node = g_first_comment_node;
	t_comment_list * temp_node = g_first_comment_node;
	printf("start output_all_comment\n");
	/* ������������܂Ń��X�g�����ǂ�A�t�@�C���ɃA�E�g�v�b�g���� */
	while(node != NULL){
		temp_node = node;
		node = node->next;
		output_to_file(temp_node->msg, temp_node->size);
		/* �������̈����� */
		free(temp_node->msg);
		free(temp_node);
	}
	g_first_comment_node = NULL;
}


%}

%union {
	int		itype;
	char*	ctype;
}

%defines
%token<ctype> NUM IF FOR WHILE EXPR COMMENT ENDIF ENDWHILE END_OF_FILE ANY_OTHER ELSE ELSE_IF FUNCTION ENDFUNCTION ENDIF_SINGLE ENDWHILE_SINGLE
%type<ctype> program block expr term factor ifst forst whilest comment endif any_other else else_if functionst endfunction endif_s endwhile_s endwhile
%left '+' '-'
%left '*' '/'
%left NEG
%right '^'

%start program

%%
/* ���̂͂��� */
program : block ';'             {  }
        | block		            {  }
        | program block		    {  }
        ;

block   : expr                  {  }
        | ifst                  { printf("ifst ok\n");  }
        | forst                 { printf("forst ok\n");  }
        | endif					{ printf("endif\n");  }
        | endwhile				{ printf("endfor\n");  }
        | else                  { printf("else\n");  }
        | else_if                  { printf("else if\n");  }
        | functionst			{ printf("function\n"); }
        | endfunction			{ printf("end function\n"); }
        | endif_s				{ printf("endif single\n");  }
        | endwhile_s			{ printf("endfor single\n");  }
        ;

expr    : term                  {  }
        | expr '+' term         {  }
        | expr '-' term         {  }
        ;

term    : factor                {  }
        | term '*' factor       {  }
        | term '/' factor       {  }
        ;

factor  : EXPR                	{  }
		|  '(' expr ')'         {  }
		| any_other				{ printf("any other\n");  }
        | comment				{ printf("comment\n"); }
		| END_OF_FILE			{ return 0; }
        ;

/*******************************************************************************************************************
			if��
			In	�F synbol_name �� if������
			Out	�F else �̂݁B
			���l�F 
*/
ifst    :   IF      			{	char format_str[] = "%sif (%s) then (true)\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, synbol_name );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									push_indent();
									clear_synbol_string(); }
        ;

forst   :   FOR      			{	char format_str[] = "%swhile (%s)\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, synbol_name );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									push_indent();
									clear_synbol_string(); }
        ;

whilest :   WHILE      			{	char format_str[] = "%swhile (%s)\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, synbol_name );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									push_indent();
									clear_synbol_string(); }
        ;

endif	:	ENDIF				{	pop_indent();
									char format_str[] = "%sendif\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									clear_synbol_string(); }
        ;

endwhile:	ENDWHILE			{	pop_indent();
									char format_str[] = "%sendwhile\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									clear_synbol_string(); }
        ;

endif_s	:	ENDIF_SINGLE			{	pop_indent();
									char format_str[] = "%s:%s;\n%sendif\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, synbol_name, INDENT_STR );
									printf(" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;;;%s\n", message_str);
									output_to_file(message_str, strlen(message_str));
									output_all_comment();
									clear_synbol_string(); }
        ;

endwhile_s:	ENDWHILE_SINGLE			{	pop_indent();
									char format_str[] = "%s:%s;\n%sendwhile\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, synbol_name, INDENT_STR );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									clear_synbol_string(); }
        ;

/*******************************************************************************************************************
			else��
			In	�F ����
			Out	�F else �̂݁B
			���l�F 
*/
else	:	ELSE				{	pop_indent();
									char format_str[] = "%selse\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, "else" );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									push_indent();
									clear_synbol_string(); }
        ;
/*******************************************************************************************************************
			else if ��
			In	�F synbol_name= else if ������
			Out	�F elseif(������) then (true)
			���l�F 
*/
else_if :	ELSE_IF				{	pop_indent();
									char format_str[] = "%selseif (%s) then (true)\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, INDENT_STR, synbol_name );
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									push_indent();
									clear_synbol_string(); }
        ;

functionst	:	FUNCTION		{	char format_str[] = "@startuml\n:%s;\nstart\n";
									char message_str[sizeof(format_str) + g_symbol_index + indent_level];
									sprintf( message_str, format_str, synbol_name );
									push_indent();											// ���Indent
									output_to_file(message_str, sizeof(message_str));
									output_all_comment();
									clear_synbol_string(); }
        ;
endfunction	:	ENDFUNCTION		{	
									char format_str[] = "stop\n";
									output_to_file("stop\n", sizeof("stop\n"));
									output_all_comment();
									output_to_file("@enduml\n", sizeof("@enduml\n"));
									pop_indent();											// ���Indent
									clear_synbol_string(); }
        ;

/* �R�����g�̕ϊ� */
comment	:	COMMENT				{ 	
									char comment_format_str[] = "%snote right\n"
																"%s%s\n"
																"%send note\n";
									printf("g_symbol_index=%d\n", 						g_symbol_index);
									char comment_message_str[			sizeof(comment_format_str) + 	g_symbol_index + (indent_level*3)];
									sprintf( comment_message_str, comment_format_str, INDENT_STR, INDENT_STR, synbol_name, INDENT_STR );
									if(is_comment_locate_after){
										backup_comment_message(comment_message_str, strlen(comment_message_str));
									} else {
										output_to_file(comment_message_str, sizeof(comment_message_str));
										output_all_comment();
									}
									clear_synbol_string(); }

/* ���̑��͂��̂܂܍ڂ��� */
any_other	:	ANY_OTHER		{ 	char comment_format_str[] = "%s:%s;\n";
									char comment_message_str[sizeof(comment_format_str) + g_symbol_index + indent_level];
									sprintf( comment_message_str, comment_format_str, INDENT_STR, synbol_name );
									output_to_file(comment_message_str, sizeof(comment_message_str));
									output_all_comment();
									clear_synbol_string(); }

/* �t�@�C���I�[ */

%%

void output_to_file(char * smbl, int size){
	if( (is_generate_global_scope_code) || is_in_function()){
		fprintf(output_file_ptr, "%s ", smbl); // �t�@�C���ɏ���
	}
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
