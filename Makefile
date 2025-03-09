all: clear build build_c link_c
		
only_asm: clear build link

build: 
	nasm -f elf64 main.s
build_c:
	g++ -c -o test.o test.cpp
link:
	ld -s -m elf_x86_64 -o main main.o	
link_c:
	g++ test.o main.o 
clear:
	rm -rf *.o *.lst main *.out
