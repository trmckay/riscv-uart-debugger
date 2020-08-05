#ifndef FILE_IO_H
#define FILE_IO_H

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

int open_file(char *path, off_t *num_words);
int read_word_file(int file, uint32_t *w);

#endif
