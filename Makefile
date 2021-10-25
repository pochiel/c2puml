all:
	bison c2puml.y -o parser.cpp
	#bison -t -v c2puml.y -o parser.cpp
	flex -o tokens.cpp c2puml.l
	#flex -d -o tokens.cpp c2puml.l
	g++ -O2 -o c2puml parser.cpp tokens.cpp -lfl -ly -lm
	#g++ -O2 -o c2puml parser.cpp tokens.cpp -lfl -ly -lm -DYYERROR_VERBOSE -DYYDEBUG=1
clean:
	rm -f *.c *.h *.cpp c2puml