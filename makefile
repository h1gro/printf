all: my_printf

my_printf:	printf.o
	ld -s -o printf printf.o

printf.o: printf.s
	nasm -f elf64 -l printf.lst printf.s

run:
	./printf
