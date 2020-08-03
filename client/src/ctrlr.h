#ifndef CTRLR_H
#define CTRLR_H

#include <stdint.h>
#include <time.h>
#include "serial.h"

#define FN_NONE         0x00
#define FN_PAUSE        0x01
#define FN_RESUME       0x02
#define FN_STEP         0x03
#define FN_RESET        0x04
#define FN_STATUS       0x05
#define FN_MEM_RD_BYTE  0x06
#define FN_MEM_RD_WORD  0x07
#define FN_REG_RD       0x08
#define FN_BR_PT_ADD    0x09
#define FN_BR_PT_RM     0x0A
#define FN_MEM_WR_BYTE  0x0B
#define FN_MEM_WR_WORD  0x0C
#define FN_REG_WR       0x0D

#define word_t uint32_t

void connection_test(int serial_port, int n);
int mcu_pause(int serial_port, int verbose);
void mcu_resume(int serial_port, int verbose);
void mcu_step(int serial_port, int verbose);
void mcu_reset(int serial_port, int verbose);
byte_t mcu_mem_rd_byte(int serial_port, int verbose);
word_t mcu_mem_rd_word(int serial_port, int verbose);
word_t mcu_reg_rd(int serial_port, int verbose);
void mcu_br_pt_add(int serial_port, word_t addr, int verbose);
void mcu_br_pt_rm(int serial_port, unsigned int num, int verbose);
void mcu_mem_wr_byte(int serial_port, word_t addr, byte_t data, int verbose);
void mcu_mem_wr_word(int serial_port, word_t addr, word_t data, int verbose);
void mcu_reg_wr(int serial_port, word_t addr, word_t data, int verbose);

#endif
