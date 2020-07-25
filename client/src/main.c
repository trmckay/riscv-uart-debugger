#include <stdlib.h>
#include <stdio.h>
#include "serial.h"
#include "debug.h"

int main(int argc, char *argv[])
{
    int serial_port;
    char *path = readline("Serial path: ");
    open_serial(path, &serial_port);
    debug_cli(serial_port);
}
