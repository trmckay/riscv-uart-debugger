#ifndef FILE_IO_H
#define FILE_IO_H

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <strings.h>

int open_file(char *path, off_t *num_words);
int read_word_file(int file, uint32_t *w);

#endif
