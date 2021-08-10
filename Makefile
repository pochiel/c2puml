all:
	bison -d c2puml.y
	flex c2puml.l
	gcc -O2 -o c2puml lex.yy.c c2puml.tab.c -lfl -ly -lm -DYYERROR_VERBOSE
clean:
	rm -f *.c *.h c2puml