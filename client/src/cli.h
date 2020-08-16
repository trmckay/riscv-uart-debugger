#ifndef CLI_H
#define CLI_H

#include "debug.h"
#include "util.h"
#include "serial.h"
#include <gmodule.h>
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
#define DEF_VAR_TOKEN  "define"

#define X0  "zero"
#define X1  "ra"
#define X2  "sp"
#define X3  "gp"
#define X4  "tp"
#define X5  "t0"
#define X6  "t1"
#define X7  "t2"
#define X8  "s0"
#define X9  "s1"
#define X10 "a0"
#define X11 "a1"
#define X12 "a2"
#define X13 "a3"
#define X14 "a4"
#define X15 "a5"
#define X16 "a6"
#define X17 "a7"
#define X18 "s2"
#define X19 "s3"
#define X20 "s4"
#define X21 "s5"
#define X22 "s6"
#define X23 "s7"
#define X24 "s8"
#define X25 "s9"
#define X26 "s10"
#define X27 "s11"
#define X28 "t3"
#define X29 "t4"
#define X30 "t5"
#define X31 "t6"

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
int parse_register_addr(char *tok);

#endif
