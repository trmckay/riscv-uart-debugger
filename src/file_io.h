#ifndef FILE_IO_H
#define FILE_IO_H

#include "types.h"
#include <sys/stat.h>
#include <sys/types.h>

int open_file(char *path, off_t *num_words);
int read_word_file(int file, word_t *w);

#endif
