
debugout=0

all:
ifeq ($(debugout), 1)
	bison -t -v c2puml.y -o parser.cpp
	flex -d -o tokens.cpp c2puml.l
	g++ -O2 -o c2puml parser.cpp tokens.cpp t_token.cpp -lfl -ly -lm -DYYERROR_VERBOSE -DDEBUGOUT -DYYDEBUG=1
else
	bison c2puml.y -o parser.cpp
	flex -o tokens.cpp c2puml.l
	g++ -O2 -o c2puml parser.cpp tokens.cpp t_token.cpp -lfl -ly -lm -DYYDEBUG=0
endif

clean:
	rm -f parser.cpp tokens.cpp parser.hpp c2puml