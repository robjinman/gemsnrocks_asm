#!/bin/sh
# fail whole script if any command fail
set -e

shopt -s expand_aliases
alias trace_on='set -x'
alias trace_off='{ PREV_STATUS=$? ; set +x; } 2>/dev/null; (exit $PREV_STATUS)'


# echho commands being executed
trace_on

mkdir -p build

nasm -f elf64 -gdwarf -o build/util.o src/util.asm
nasm -f elf64 -gdwarf -o build/draw.o src/draw.asm
nasm -f elf64 -gdwarf -o build/levels.o src/levels.asm
nasm -f elf64 -gdwarf -o build/main.o src/main.asm

ld -o build/gems build/util.o build/draw.o build/main.o build/levels.o

trace_off

echo "Done!"
