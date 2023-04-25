// main.c - "runtime" for epcp programs (prints returned 64-bit integer)
// Unmodified from Ben Lerner's

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

extern int64_t our_code_starts_here() asm("our_code_starts_here");

typedef uint64_t SNAKEVAL;
const uint64_t BOOL_TAG   = 0x0000000000000001;
const SNAKEVAL BOOL_TRUE  = 0xFFFFFFFFFFFFFFFF; // These must be the same values
const SNAKEVAL BOOL_FALSE = 0x7FFFFFFFFFFFFFFF; // as chosen in compile.ml

const int ERR_NOT_NUMBER = 1;
const int ERR_NOT_BOOLEAN = 2;
// other error codes here

void error(int errCode, int val) {
  if (errCode == ERR_NOT_NUMBER) {
    fprintf(stderr, "Expected number, but got %010x\n", val);
  } else if (errCode == ERR_NOT_BOOLEAN) {
    fprintf(stderr, "Expected boolean, but got %010x\n", val);
  } else {
    fprintf (stderr, "No entendi el error %d\n", errCode);
  } 

  exit(errCode);
}

SNAKEVAL print(SNAKEVAL val) {
  if ((val & BOOL_TAG) == 0) { // val is even ==> number
    printf("%ld", ((int64_t)(val)) / 2); // shift bits right to remove tag
  } else if (val == BOOL_TRUE) {
    printf("true");
  } else if (val == BOOL_FALSE) {
    printf("false");
  } else {
    printf("Unknown value: %#018lx", val); // print unknown val in hex
  }
  return val;
}

int main(int argc, char** argv) {
  int64_t result = our_code_starts_here();
  print(result);
  return 0;
}
