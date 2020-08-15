#ifndef TYPES_H
#define TYPES_H

#include <inttypes.h>

#define byte_t unsigned char

#ifdef RV32
    #define word_t uint32_t
    #define WORD_SIZE 4
    #define RF_SIZE 32
#elif RV64
    #define word_t uint64_t
    #define WORD_SIZE 8
    #define WIDTH 64
#else
    #define word_t uint32_t
    #define WORD_SIZE 4
    #define RF_SIZE 32
#endif

#endif
