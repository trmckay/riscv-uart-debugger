#include "cli.h"

#define match_strs(s, m1, m2) ((strcasecmp(s, m1) == 0) || (strcasecmp(s, m2) == 0))

void parse_cmd(char *line, int serial_port, int verbose)
{
    char *tok;
    tok = strtok(line, " ");
    uint32_t a1, a2;
    
    // help message
    if (match_strs(tok, "h", "help"))
        printf(HELP_MSG);

    // quit/exit
    if (match_strs(tok, "q", "quit"))
        exit(EXIT_SUCCESS);
    if (match_strs(tok, "ex", "exit"))
        exit(EXIT_SUCCESS);
    
    // connection test
    if (match_strs(tok, "t", "test"))
    {
        if ((tok = strtok(NULL, " ")) == NULL)
        {
            fprintf(stderr, "Error: usage t <number>\n");
            return;
        }
        if ((a1 = atoi(tok)) < 1)
        {
            fprintf(stderr, "Error: usage: t <number>\n");
            return;
        }
        connection_test(serial_port, a1, 1);
    }
    
    // pause
    if (match_strs(tok, "p", "pause"))
        mcu_pause(serial_port);

    // resume
    if (match_strs(tok, "r", "resume"))
        mcu_resume(serial_port);
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
            parse_cmd(line, serial_port, verbose);
        }
        free(line);
    }
}
