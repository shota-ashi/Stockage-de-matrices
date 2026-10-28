CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g

all: main

main: main.c matrice.c matrice_alloc.c matrice_calcul.c matrice_io.c
    $(CC) $(CFLAGS) -o @ $^

clean:
    rm -f *.o *.exe main test_ex1 test_ex2 test_ex3
