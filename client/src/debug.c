#include "debug.h"

#define match_strs(s, m1, m2) ((strcasecmp(s, m1) == 0) || (strcasecmp(s, m2) == 0))

void debug_cmd(char *line, int serial_port, int verbose)
{           
    // check for built-ins
    if (match_strs(line, "h", "help"))
        printf(HELP_MSG);
    if (match_strs(line, "q", "quit"))
        exit(EXIT_SUCCESS);
    if (match_strs(line, "ex", "exit"))
        exit(EXIT_SUCCESS);
    if (match_strs(line, "t", "test"))
        connection_test(serial_port, 400);
    if (match_strs(line, "p", "pause"))
        mcu_pause(serial_port, verbose);
}

void debug_cli(char *path, int serial_port, int verbose)
{
    char *line;
    
    printf("\nUART Debugger\n");
    printf("Enter 'h' or 'help' for usage details.\n");

    while(1)
    {
        // prompt
        printf("\nuart-db @ %s\n", path);
        line = readline("$ ");

        if (!line)
            exit(EXIT_FAILURE);

        if (*line)
        {
            add_history(line);
            debug_cmd(line, serial_port, verbose);
        }
        free(line);
    }
}
