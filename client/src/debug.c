#include "debug.h"

int match_strs(char *s, int n, ...)
{
    va_list valist;
    va_start(valist, n);

    for (int i = 0; i < n; i++)
        if (strcasecmp(s, (char *)va_arg(valist, char *)) == 1)
            return 1;
    return 0;
}

void parse_line(char *line)
{
    if (match_strs(line, 2, "h", "help"))
        printf(HELP_MSG);
    if (match_strs(line, 2, "q", "quit"))
        exit(EXIT_SUCCESS);   
}

void debug_cli(int serial_port)
{
    while(1)
    {
        char *line = readline(">| ");
        if (!line)
            exit(EXIT_FAILURE);
        if (*line)
        {
            add_history(line);
            parse_line(line);
        }
        free(line);
    }
}
