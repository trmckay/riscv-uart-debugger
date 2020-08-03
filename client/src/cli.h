#ifndef CLI_H
#define CLI_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdint.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <stdarg.h>
#include "serial.h"
#include "debug.h"

#define RED     "\x1b[31m"
#define GREEN   "\x1b[32m"
#define YELLOW  "\x1b[33m"
#define BLUE    "\x1b[34m"
#define MAGENTA "\x1b[35m"
#define CYAN    "\x1b[36m"
#define RESET   "\x1b[0m"

#define HELP_MSG \
"UART Debugger\n"

void debug_cli(char *path, int serial_port, int verbose);

#endif
