// main.c - "runtime" for epcp programs (prints returned 64-bit integer)
// Unmodified from Ben Lerner's

#include <stdio.h>
#include <stdint.h>

extern int64_t our_code_starts_here() asm("our_code_starts_here");

int main(int argc, char** argv) {
  int64_t result = our_code_starts_here();
  printf("%ld\n", result);
  return 0;
}
