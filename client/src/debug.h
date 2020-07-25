#ifndef DEBUG_H
#define DEBUG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdint.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <stdarg.h>

#define HELP_MSG "This help message is a placeholder.\n"

void debug_cli(int serial_port);

#endif
