CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g

ifeq ($(OS),Windows_NT)
    CLEAN_CMD = -del /f /q *.o *.exe main demo_matrices test_ex1 test_ex2 test_ex3 2>NUL
else
    CLEAN_CMD = rm -f *.o *.exe main demo_matrices test_ex1 test_ex2 test_ex3
endif

.PHONY: all clean

all: demo_matrices

demo_matrices: main.c matrice.c matrice_alloc.c matrice_calcul.c matrice_io.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	$(CLEAN_CMD)