# Makefile - recipies for compiling epcp programs
# Modified from Ben Lerner's Makefile from Lecture 2
# Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
# See LICENSE for details

%.run: %.o
	clang -g -m64 -o $@ main.c $<

%.o: %.s
	nasm -f elf64 -o $@ $<

%.s: %.int
	dune exec ./compiler.exe $< > $@
