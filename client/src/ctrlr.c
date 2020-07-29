#include "ctrlr.h"

int mcu_issue_cmd(int serial_port, byte_t command)
{
    byte_t br = 0;
    int attempts = 0;

    #ifdef VERBOSE
        printf("Issuing command: %x.\n", command);
    #endif

    while (br != FN_PAUSE && attempts++ < 5)
    {
        #ifdef VERBOSE
            printf("Attempt %d", attempts);
            printf("Sending command byte.\n");
        #endif

        // send byte containing pause command
        send_byte(serial_port, command);

        #ifdef VERBOSE
            printf("Byte sent, waiting for response.\n");
        #endif
        
        // wait for mcu to echo byte
        br = rcv_byte(serial_port);

        #ifdef VERBOSE
            printf("Byte recieved: %x.\n", br);
        #endif
    }

    if (br != FN_PAUSE) {
        fprintf(stderr, "ERROR: MCU failed to echo data.");
        return 1;
    }

    #ifdef VERBOSE
        printf("Command issued successfully!");
    #endif

    return 0;
}

int mcu_pause(int serial_port)
{
    #ifdef VERBOSE
        printf("Pause MCU\n");
    #endif
    return mcu_issue_cmd(serial_port, FN_PAUSE);
}

void mcu_resume(int serial_port)
{
    #ifdef VERBOSE
        printf("Resume MCU\n");
    #endif
    mcu_issue_cmd(serial_port, FN_RESUME);
}
