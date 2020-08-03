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
#include "serial.h"
#include "ctrlr.h"

#define HELP_MSG "Placeholder help message\n"

void debug_cli(char *path, int serial_port, int verbose);

#endif
