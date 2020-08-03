#ifndef SERIAL_H
#define SERIAL_H

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <termios.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <strings.h>
#include <readline/readline.h>
#include <readline/history.h>

typedef unsigned char byte_t;
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

int open_serial(char *path, int *serial_port, int verbose);
void send_word(int serial_port, uint32_t w, int verbose);
int expect_word(int serial_port, uint32_t w, int verbose);
uint32_t expect_any_word(int serial_port, int verbose);

#endif
