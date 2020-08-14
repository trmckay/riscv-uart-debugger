#ifndef CLI_H
#define CLI_H

#include "debug.h"
#include "util.h"
#include "serial.h"
#include <readline/history.h>
#include <readline/readline.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#define VERDATE "2020-08-08"
#define VERSION "v1.3"

#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define MAGENTA "\x1b[35m"
#define CYAN "\x1b[36m"
#define RESET "\x1b[0m"

#define MAX_BREAK_PTS 8

void restore_term(int serial_port);
void debug_cli(char *path, int serial_port);

#endif
