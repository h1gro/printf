all: asm & c

asm:	printf.o
	ld -s -o printf printf.o

printf.o: c.o
	nasm -f elf64 -l printf.lst printf.s

run:
	./printf

c:	printf.o
	g++ -O0 main.o printf.o -o printf -no-pie

c.o:	main.cpp
	g++ -c -O0 main.cpp -o main.o
