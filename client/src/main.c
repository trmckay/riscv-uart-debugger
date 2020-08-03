#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "cli.h"
#include "serial.h"

#define VERSION "v0.1"

void usage(char *msg);
void parse_args(int argc, char *argv[], char **path, int *verbose);
void start(char *path, int verbose);

int main(int argc, char *argv[])
{
    int verbose = 0;
    char *term_path;

    parse_args(argc, argv, &term_path, &verbose);
    start(term_path, verbose);
}

void usage(char *msg)
{
    if (msg != NULL)
        fprintf(stderr, "%s\n", msg);
    fprintf(stderr, "Usage: uart-db [-v] <serial port>\n");
    exit(EXIT_FAILURE);
}

void parse_args(int argc, char *argv[], char **path, int *verbose)
{   
    if (argc < 2)
    {
        usage("Error: too few arguments");
        exit(EXIT_FAILURE);
    }
    if (argc > 3)
    {
        usage("Error: too many arguments");
        exit(EXIT_FAILURE);
    }

    for (int i = 1; i < argc; i++)
    {
        char *c_arg = argv[i];
        if (c_arg[0] == '-')
        {
            if (c_arg[1] == 'v')
                *verbose = 1;
            else
                usage("Error: unrecognized flag");
        }
        else if (c_arg[0] != '-')
            *path = c_arg;
    }
}

void retry(int verbose)
{
    char new_path[256];
    
    //print some information about possible connection candidates
    fprintf(stderr, "Error: did not establish a connection.\n\n");
    fprintf(stderr, "Searcing connected devices for terminals that may be serial connections...\n");
    fprintf(stderr, "Possible candidates:\n");
    // exec unix find to search for devices matching common patterns
    system("find /dev -name \"ttyUSB*\" -o -name \"ttyS*\" | sed 's/^/    /' > /dev/stderr");
    fprintf(stderr, "\nOn Debian/Ubuntu, the serial connection of FPGA is likely /dev/ttySX. On other distros, try /dev/ttyUSBX.\n\n");
    
    // prompt to try a new device
    char *line = readline("Try again with one of these devices? [y/N]: ");
    if (line[0] == 'y' || line[0] == 'Y')
    {
        // if user wants to try again
        free(line);
        // prompt for path
        line = readline("Device: ");
        if (strlen(line) > 255)
        {
            fprintf(stderr, "Error: path too long\n");
            free(line);
            exit(EXIT_FAILURE);
        }
        // copy into temp str pointer and free before calling to prevent mem leaks
        memcpy(new_path, line, strlen(line)+1);
        free(line);
        // try again, pass through verbose boolean
        start(new_path, verbose);
    }
    // if not, just clean up and exit
    else
    {
        free(line);
        exit(EXIT_FAILURE);
    }

}

void start(char *path, int verbose)
{
    int serial_port = -1;
    
    if (open_serial(path, &serial_port))
        retry(verbose);

    // quick connection test
    if (connection_test(serial_port, 16, 0))
        retry(verbose);

    printf("\nA stable connection has been established. Launching debugger...\n");

    // launch debug cli on device at serial_port
    debug_cli(path, serial_port, verbose);

}


