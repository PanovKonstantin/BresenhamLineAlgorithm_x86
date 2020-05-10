CC=gcc
ASMBIN=C:\Users\kosti\AppData\Local\bin\NASM\nasm

all : asm cc link
asm :
	$(ASMBIN) -o line.o -f elf -g -l line.lst line.asm
cc :
	$(CC) -m32 -fpack-struct -c -g -O0 main.c
link :
	$(CC) -m32 -g -o program main.o line.o

clean :
	del *.o
	del program.exe
	del line.lst