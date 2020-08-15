#ifndef DEBUG_H
#define DEBUG_H

#include "cli.h"
#include "file_io.h"
#include "serial.h"
#include "types.h"
#include <dirent.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define FN_NONE 0x00
#define FN_PAUSE 0x01
#define FN_RESUME 0x02
#define FN_STEP 0x03
#define FN_RESET 0x04
#define FN_STATUS 0x05
#define FN_MEM_RD_BYTE 0x06
#define FN_MEM_RD_WORD 0x07
#define FN_REG_RD 0x08
#define FN_BR_PT_ADD 0x09
#define FN_BR_PT_RM 0x0A
#define FN_MEM_WR_BYTE 0x0B
#define FN_MEM_WR_WORD 0x0C
#define FN_REG_WR 0x0D

int connection_test(int serial_port, int n, int do_log, int quiet);
int mcu_program(int serial_port, char *path, int fast);
int mcu_pause(int serial_port);
int mcu_resume(int serial_port);
int mcu_step(int serial_port);
int mcu_reset(int serial_port);
int mcu_status(int serial_port, int *status);
int mcu_mem_read_word(int serial_port, word_t addr, word_t *data);
int mcu_mem_read_byte(int serial_port, word_t addr, byte_t *data);
int mcu_reg_read(int serial_port, word_t addr, word_t *data);
int mcu_mem_write_word(int serial_port, word_t addr, word_t data);
int mcu_mem_write_byte(int serial_port, word_t addr, byte_t data);
int mcu_reg_write(int serial_port, word_t addr, word_t data);
int mcu_add_breakpoint(int serial_port, word_t addr);
int mcu_rm_breakpoint(int serial_port, word_t index);

#endif
