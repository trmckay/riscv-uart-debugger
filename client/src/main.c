#include <stdlib.h>
#include <stdio.h>
#include "debug.h"
#include "serial.h"

#define VERSION "v0.1"

int main(int argc, char *argv[])
{
    int serial_port = -1, connected = 0;

    printf("MCU Debugger %s\n", VERSION);
    printf("Enter 'h' or 'help' for usage details.\n");

    // if device provided, connect to it
    if (argc > 1)
    {
        printf("\n");
        connected = !(open_serial(argv[1], &serial_port) != 0);
    }

    if (!connected)
        printf("Enter 'c' or 'connect' to connect to target.\n");
    
    // launch debug cli on device at serial_port
    debug_cli(&serial_port, &connected);
}
