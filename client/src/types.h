#ifndef TYPES_H
#define TYPES_H

#define byte_t unsigned char

#ifdef RV32
#define word_t uint32_t
#define WORD_SIZE 4
#endif

#ifdef RV64
#define word_t uint64_t
#define WORD_SIZE 8
#endif

#endif
