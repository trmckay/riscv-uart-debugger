#ifndef SERIAL_H
#define SERIAL_H

#include "types.h"
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>

typedef struct termios term_sa;

#define EQUAL 0
#define ERR -1
#define CTRLC 0

// Serial parameters
// Make sure these agree with the target
#define TIMEOUT_MSEC 5000
#define BAUD B115200
#define INTER_BYTE_TIMEOUT 20
#define MIN_BYTES 4
#define BYTES_PER_SEND 4
#define BYTES_PER_RCV 4

int open_serial(char *path, int *serial_port);
int send_word(int serial_port, word_t w);
int read_word(int serial_port, word_t *w);

#endif
