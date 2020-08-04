#include "cli.h"

#define match_strs(s, m1, m2) ((strcasecmp(s, m1) == 0) || (strcasecmp(s, m2) == 0))

int parse_int(char *str)
{
    char prefix[3];
    memcpy(prefix, str, 2);
    prefix[3] = 0;

    // hex formatted
    if (match_strs(prefix, "0x", "0X"))
    {
        return (uint32_t)strtol(str, NULL, 0);
    }
    // decimal formatted
    else
        return atoi(str);
}

int parse_cmd(char *line, int serial_port, int verbose)
{
    char *cmd, *s_a1, *s_a2;
    cmd = strtok(line, " ");
    uint32_t a1, a2;
    
    // help message
    if (match_strs(cmd, "h", "help"))
    {
        printf(HELP_MSG);
        return 0;
    }

    // quit/exit
    if (match_strs(cmd, "q", "quit"))
        exit(EXIT_SUCCESS);
    if (match_strs(cmd, "ex", "exit"))
        exit(EXIT_SUCCESS);
    
    s_a1 = strtok(NULL, " ");
    s_a2 = strtok(NULL, " ");

    // connection test
    if (match_strs(cmd, "t", "test"))
    {
        if (s_a1 == NULL)
        {
            fprintf(stderr, "Error: usage t <number>\n");
            return 1;
        }
        if ((a1 = parse_int(s_a1)) < 1)
        {
            fprintf(stderr, "Error: usage: t <number>\n");
            return 1;
        }
        return connection_test(serial_port, a1, 1);
    }
    
    // pause
    if (match_strs(cmd, "p", "pause"))
        return mcu_pause(serial_port);

    // resume
    if (match_strs(cmd, "r", "resume"))
        return mcu_resume(serial_port);

    if (match_strs(cmd, "pr", "program"))
    {
        if (s_a1 == NULL)
        {
            fprintf(stderr, "Error: usage: pr <mem.bin>\n");
            return 1;
        }
        return mcu_program(serial_port, s_a1);
    }

    if (match_strs(cmd, "mww", "mem-write-word"))
    {
        if (s_a1 == NULL || s_a2 == NULL)
        {
            fprintf(stderr, "Error: usage: mww <0xN | N> <0xN | N>\n");
            return 1;
        }
        if ((a1 = parse_int(s_a1)) < 0)
        {
            fprintf(stderr, "Error: address must be positive integer\n");
        }
        a2 = parse_int(s_a2);
        printf("MEM[0x%08X] <- %d (0x%X)\n", a2, a2, a1);
        return mcu_mem_write_word(serial_port, a2, a1);
    }

    fprintf(stderr, "Error: command not recognized\n");
    return 1;
}

void debug_cli(char *path, int serial_port, int verbose)
{
    char *line;
    int err = 0;
    
    printf("\nUART Debugger | %s\n", VERSION);
    printf("Enter 'h' or 'help' for usage details.\n");

    while(1)
    {
        // prompt
        printf("\nuart-db @ %s\n", path);
        line = (err) ? readline(RED "$ " RESET) : readline(CYAN "$ " RESET);

        if (!line)
            exit(EXIT_FAILURE);

        if (*line)
        {
            add_history(line);
            err = parse_cmd(line, serial_port, verbose);
        }
        free(line);
    }
}
