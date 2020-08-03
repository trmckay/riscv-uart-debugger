#ifndef DEBUG_H
#define DEBUG_H

#include <stdint.h>
#include <time.h>
#include "serial.h"
#include "cli.h"

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

int connection_test(int serial_port, int n, int do_log);
int mcu_pause(int serial_port);
int mcu_resume(int serial_port);

#endif
