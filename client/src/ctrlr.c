#include "ctrlr.h"

int mcu_issue_cmd(int serial_port, byte_t command)
{
    return 0;
}

int mcu_pause(int serial_port)
{
    #ifdef VERBOSE
        printf("Pause MCU\n");
    #endif

    return 0;
}

void mcu_resume(int serial_port)
{
    #ifdef VERBOSE
        printf("Resume MCU\n");
    #endif
}
