#!/bin/bash

# Compile NASM source to object file
nasm -f elf64 sysutils.asm -o sysutil.o

# Show progress bar
bar_width=40
for i in $(seq 1 $bar_width); do
    percent=$((i * 100 / bar_width))
    bar=$(printf '%0.s#' $(seq 1 $i))
    spaces=$(printf '%0.s ' $(seq 1 $((bar_width-i))))
    echo -ne "\rCompiling: [${bar}${spaces}] ${percent}%"
    sleep 0.02
done
echo

# Link object file to executable
ld sysutil.o -o sysutil

echo -e "\n\033[1;32mDone!\033[0m Executable: ./sysutil"