CC=gcc
CFLAGS=-Wall -Wextra -Werror -g -O2 -Wno-unused-function
all: q

q: q.l q.y dyn.h
	bison -d q.y
	flex q.l
	$(CC) $(CFLAGS) -o q lex.yy.c q.tab.c -lm

clean:  
	rm -f q.tab.c lex.yy.c q.tab.h q.tab.o lex.yy.o q

