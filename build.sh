mkdir -p build

nasm -f elf64 -gdwarf -o build/main.o src/main.asm
ld -o build/gems build/main.o
