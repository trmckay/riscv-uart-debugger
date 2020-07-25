#ifndef CTRLR_H
#define CTRLR_H

#include <stdint.h>
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

int mcu_pause(int serial_port);
void mcu_resume(int serial_port);
void mcu_step(int serial_port);
void mcu_reset(int serial_port);
byte_t mcu_mem_rd_byte(int serial_port);
word_t mcu_mem_rd_word(int serial_port);
word_t mcu_reg_rd(int serial_port);
void mcu_br_pt_add(int serial_port, word_t addr);
void mcu_br_pt_rm(int serial_port, unsigned int num);
void mcu_mem_wr_byte(int serial_port, word_t addr, byte_t data);
void mcu_mem_wr_word(int serial_port, word_t addr, word_t data);
void mcu_reg_wr(int serial_port, word_t addr, word_t data);

#endif
