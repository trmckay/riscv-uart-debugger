#include "ctrlr.h"

int mcu_pause(int serial_port)
{
    byte_t br;
    send_byte(serial_port, FN_PAUSE);
    br = rcv_byte(serial_port);
    if (br != 0)
        fprintf(stderr, "ERROR: MCU reported non-zero code.");
    return br;
}
