#include "debug.h"

#define match_strs(s, m1, m2) ((strcasecmp(s, m1) == 0) || (strcasecmp(s, m2) == 0))

void debug_cmd(char *line, int serial_port)
{
    if (match_strs(line, "p", "pause"))
        mcu_pause(serial_port);
    if (match_strs(line, "r", "resume"))
        mcu_resume(serial_port);
}

void debug_cli(int *serial_port, int *connected)
{
    char *line;

    while(1)
    {
        // prompt
        line = readline("\n$ ");

        if (!line)
            exit(EXIT_FAILURE);

        if (*line)
        {
            add_history(line);

            // check for help or quit
            if (match_strs(line, "h", "help"))
                printf(HELP_MSG);
            else if (match_strs(line, "q", "quit"))
                exit(EXIT_SUCCESS);
            else if (match_strs(line, "c", "connect"))
            {
                line = readline("Enter path: ");
                *connected = !(open_serial(line, serial_port) != 0);
            }

            if (!(*connected))
                fprintf(stderr, "Connect to a target first.\n");
            else
                debug_cmd(line, *serial_port);
        }
        free(line);
    }
}
