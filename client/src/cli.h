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

#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define MAGENTA "\x1b[35m"
#define CYAN "\x1b[36m"
#define RESET "\x1b[0m"

#define MAX_BREAK_PTS 8

#define CTEST_TOKEN    "t"
#define PAUSE_TOKEN    "p"
#define RESUME_TOKEN   "r"
#define PROGRAM_TOKEN  "pr"
#define STEP_TOKEN     "s"
#define RESET_TOKEN    "rst"
#define STATUS_TOKEN   "st"
#define BPADD_TOKEN    "b"
#define BPDEL_TOKEN    "del"
#define BPCLR_TOKEN    "bc"
#define BPLIST_TOKEN   "bl"
#define REG_RD_TOKEN   "rr"
#define REG_WR_TOKEN   "rw"
#define MEM_RD_W_TOKEN "mrw"
#define MEM_WR_W_TOKEN "mww"
#define MEM_RD_B_TOKEN "mrb"
#define MEM_WR_B_TOKEN "mwb"

#define HELP_MSG \
"============================ ABOUT ====================================\n"\
"RISC-V UART Debugger\n"\
"Version: 1.4\n"\
"Author: Trevor McKay | trmckay@calpoly.edu\n\n"\
\
"============================ USAGE ====================================\n"\
"Run with 'uart-db <device> to connect to a specific target.\n"\
"Run with no arguments to autodetect a target.\n"\
"Type a command and its arguments, then press enter to execute.\n"\
"You can also execute external shell commands by escaping them with '!'.\n\n"\
\
"======================= LIST OF COMMANDS ==============================\n"\
" h                   : view this message\n"\
" p                   : pause execution\n"\
" r                   : resume execution\n"\
" pr <mem.bin>        : program with the specified binary file\n"\
" rst                 : reset execution\n"\
" st                  : request MCU status\n"\
" b <pc>              : add a breakpoint to the specified program counter\n"\
" d <num>             : delete the specified breakpoint\n"\
" bl                  : list breakpoints\n"\
" rr <num>            : read the data at the register\n"\
" rw <num> <data>     : write the data to the register\n"\
" mww <addr> <data>   : write a word (4 bytes) to the memory\n"\
" mrb <addr>          : read a byte from the memory\n"\
" mwb <addr> >data>   : write a byte to the memory\n"

void restore_term(int serial_port);
void debug_cli(char *path, int serial_port);

#endif
