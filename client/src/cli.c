#include "cli.h"
#include "debug.h"
#include "types.h"
#include "util.h"
#include <gmodule.h>
#include <pwd.h>
#include <readline/history.h>
#include <readline/readline.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/types.h>
#include <unistd.h>

typedef GHashTable ht_t;
int parse_register_addr(ht_t *vars, char *tok);

// Array of breakpoints (also should be tracked in the module)
// -1 = none
// positive int = PC of breakpoint
// only hardware breakpoints are supported right now
int64_t bps[MAX_BREAK_PTS] = {-1, -1, -1, -1, -1, -1, -1, -1};

// keeps track of pause state
int paused = 0;

// just print a message
void unrecognized_cmd(char *line) {
    fprintf(stderr,
            "Error: unrecognized command\n"
            "Execute external shell commands with a leading '!'.\n"
            "Example: '! %s' or '!%s'\n"
            "Enter 'h' for more information.\n",
            line, line);
}

// long-form help message
void help() { printf(HELP_MSG); }

// searches defined variables, or parses as integer
word_t get_num(ht_t *vars, char *tok) {
    word_t *r;
    r = (word_t *)g_hash_table_lookup(vars, tok);
    if (r == NULL)
        return parse_int(tok);
    else
        return *r;
}

// DESCRIPTION: takes the command as a string, and applies it to the serial port
// RETURNS: 0 for success, non-zero for error
int parse_cmd(char *line, int serial_port, ht_t *vars) {
    char *cmd, *s_a1, *s_a2;
    int ec;
    word_t pc;

    // not strtok'd line for later use
    char line_copy[strlen(line) + 1];
    strcpy(line_copy, line);

    cmd = strtok(line, " ");
    word_t a1, a2;

    s_a1 = strtok(NULL, " ");
    s_a2 = strtok(NULL, " ");

    // connection test
    if (match_strs(cmd, CTEST_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage t <number>\n");
            return EXIT_FAILURE;
        }
        if ((a1 = get_num(vars, s_a1)) < 1) {
            fprintf(stderr, "Error: usage: t <number>\n");
            return EXIT_FAILURE;
        }
        return connection_test(serial_port, a1, 1, 0);
    }

    // pause
    if (match_strs(cmd, PAUSE_TOKEN)) {
        printf("Pause MCU\n");
        if (!(ec = mcu_pause(serial_port, &pc)))
            printf("pc = 0x%02X\n", pc);
        return ec;
    }

    // resume
    if (match_strs(cmd, RESUME_TOKEN)) {
        printf("Resume MCU\n");
        return (mcu_resume(serial_port));
    }

    // program
    if (match_strs(cmd, PROGRAM_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: pr <mem.bin> [-f]\n");
            return EXIT_FAILURE;
        }
        if ((ec = mcu_pause(serial_port, &pc)))
            return ec;
        if ((ec = mcu_program(serial_port, s_a1, 1)))
            return ec;
        if ((ec = mcu_reset(serial_port)))
            return ec;
        return mcu_resume(serial_port);
    }

    // step
    if (match_strs(cmd, STEP_TOKEN)) {
        printf("Step\n");
        if ((ec = mcu_pause(serial_port, &pc))) {
            return ec;
        }
        return mcu_step(serial_port);
    }

    // reset
    if (match_strs(cmd, RESET_TOKEN)) {
        printf("Reset MCU\n");
        if ((ec = mcu_pause(serial_port, &pc)))
            return ec;
        if ((ec = mcu_reset(serial_port)))
            return ec;
        return mcu_resume(serial_port);
    }

    // status (not implemented)
    if (match_strs(cmd, STATUS_TOKEN)) {
        printf("Request MCU status\n");
        fprintf(stderr, "Warning: not implemented\n");
        int s, err;
        err = mcu_status(serial_port, &s);
        printf("Status: %d\n", s);
        return err;
    }

    // add breakpoint
    if (match_strs(cmd, BPADD_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: b <pc>\n");
            return EXIT_FAILURE;
        }
        a1 = get_num(vars, s_a1);

        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] < 0) {
                bps[i] = a1;
                printf("Add breakpoint %d @ pc = 0x%08X\n", i, a1);
                return mcu_add_breakpoint(serial_port, a1);
            }
        }
        fprintf(stderr, "Error: max number of breakpoints reached\n");
        return EXIT_FAILURE;
    }

    // delete breakpoint
    if (match_strs(cmd, BPDEL_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: d <bp-num>\n");
            return EXIT_FAILURE;
        }
        a1 = get_num(vars, s_a1);
        if (a1 < MAX_BREAK_PTS && bps[a1] >= 0) {
            printf("Delete breakpoint %d @ pc = 0x%08X\n", a1, (word_t)bps[a1]);
            int err = mcu_rm_breakpoint(serial_port, bps[a1]);
            bps[a1] = -1;
            return err;
        } else {
            fprintf(stderr, "Error: breakpoint does not exist\n");
            return EXIT_FAILURE;
        }
    }

    // clear breakpoints
    if (match_strs(cmd, BPCLR_TOKEN)) {
        printf("Clear breakpoints\n");
        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] >= 0) {
                printf("Delete breakpoint %d @ pc = 0x%08X\n", i,
                       (word_t)bps[i]);
                if (mcu_rm_breakpoint(serial_port, bps[i]))
                    return EXIT_FAILURE;
                bps[i] = -1;
            }
        }
        return EXIT_SUCCESS;
    }

    // list breakpoints
    if (match_strs(cmd, BPLIST_TOKEN)) {
        int none = 1;
        printf("List breakpoints\n");
        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] > 0)
                none = 0;
        }
        if (none) {
            printf("No breakpoints set\n");
            return EXIT_SUCCESS;
        }
        printf("NUM  |  PC\n");
        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] > 0)
                printf(" %d   |  0x%08X\n", i, (word_t)bps[i]);
        }
        return EXIT_SUCCESS;
    }

    // read register file
    if (match_strs(cmd, REG_RD_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: rr <reg>\n");
            return EXIT_FAILURE;
        }
        a1 = parse_register_addr(vars, s_a1);
        if (a1 < 0 || a1 > RF_SIZE) {
            fprintf(stderr, "Error: address out of range\n");
            return EXIT_FAILURE;
        }
        if (mcu_pause(serial_port, &pc)) {
            fprintf(stderr, "Error: failed to pause MCU\n");
            return EXIT_FAILURE;
        }
        word_t r;
        int err;
        if (!(err = mcu_reg_read(serial_port, a1, &r)))
            printf("x%d = %d (0x%08X)\n", a1, r, r);
        return err;
    }

    // write register file
    if (match_strs(cmd, REG_WR_TOKEN)) {
        if (s_a1 == NULL || s_a2 == NULL) {
            fprintf(stderr, "Error: usage: rw <reg> <data>\n");
            return EXIT_FAILURE;
        }
        a1 = parse_register_addr(vars, s_a1);
        if (a1 < 0 || a1 > RF_SIZE) {
            fprintf(stderr, "Error: address out of range\n");
            return EXIT_FAILURE;
        }
        if (mcu_pause(serial_port, &pc)) {
            fprintf(stderr, "Error: failed to pause MCU\n");
            return EXIT_FAILURE;
        }
        a2 = get_num(vars, s_a2);
        int err;
        if (!(err = mcu_reg_write(serial_port, a1, a2)))
            printf("x%d <- %d (0x%08X)\n", a1, a2, a2);
        return err;
    }

    // read word from memory
    if (match_strs(cmd, MEM_RD_W_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: d <pc>\n");
            return EXIT_FAILURE;
        }
        if (mcu_pause(serial_port, &pc)) {
            fprintf(stderr, "Error: failed to pause MCU\n");
            return EXIT_FAILURE;
        }
        a1 = get_num(vars, s_a1);
        if (a1 < 0 || a1 > 0xFFFFFFFF) {
            fprintf(stderr, "Error: address out of range\n");
            return EXIT_FAILURE;
        }
        word_t r;
        int err;
        if (!(err = mcu_mem_read_word(serial_port, a1, &r)))
            printf("MEM[0x%08X] = %d (0x%08X)\n", a1, r, r);
        return err;
    }

    // write word to memory
    if (match_strs(cmd, MEM_WR_W_TOKEN)) {
        if (s_a1 == NULL || s_a2 == NULL) {
            fprintf(stderr, "Error: usage: mww <addr> <data>\n");
            return EXIT_FAILURE;
        }
        a1 = get_num(vars, s_a1);
        a2 = get_num(vars, s_a2);
        if (a1 < 0 || a1 > 0xFFFFFFFF) {
            fprintf(stderr, "Error: address out of range\n");
            return EXIT_FAILURE;
        }
        if (mcu_pause(serial_port, &pc)) {
            fprintf(stderr, "Error: failed to pause MCU\n");
            return EXIT_FAILURE;
        }
        int err;
        if (!(err = mcu_mem_write_word(serial_port, a1, a2)))
            printf("MEM[0x%08X] <- %d (0x%08X)\n", a1, a2, a2);
        return err;
    }

    // read byte from memory
    if (match_strs(cmd, MEM_RD_B_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: d <pc>\n");
            return EXIT_FAILURE;
        }
        if (mcu_pause(serial_port, &pc)) {
            fprintf(stderr, "Error: failed to pause MCU\n");
            return EXIT_FAILURE;
        }
        a1 = get_num(vars, s_a1);
        byte_t r;
        int err;
        if (!(err = mcu_mem_read_byte(serial_port, a1, &r)))
            printf("MEM[0x%08X] = %d (0x%04X)\n", a1, r, r);
        return err;
    }

    // write a byte to memory
    if (match_strs(cmd, MEM_WR_B_TOKEN)) {
        if (s_a1 == NULL || s_a2 == NULL) {
            fprintf(stderr, "Error: usage: mww <addr> <data>\n");
            return EXIT_FAILURE;
        }
        if ((a1 = get_num(vars, s_a1)) < 0) {
            fprintf(stderr, "Error: address must be positive integer\n");
        }
        if (mcu_pause(serial_port, &pc)) {
            fprintf(stderr, "Error: failed to pause MCU\n");
            return EXIT_FAILURE;
        }
        a2 = get_num(vars, s_a2);
        int err;
        if (!(err = mcu_mem_write_byte(serial_port, a1, a2)))
            printf("MEM[0x%08X] <- %d (0x%04X)\n", a1, a2, a2);
        return err;
    }

    // print unrecognized cmd msg and return error
    unrecognized_cmd(line_copy);
    return EXIT_FAILURE;
}

// loads user defined variables into program from path
// default: ~/.config/uart-db/config
// returns number of variables found
int populate_vars(ht_t *vars_ht, char **keys, word_t *values, char *path) {
    char *line_buf = NULL, *str_key;
    word_t value;
    size_t line_buf_size = 0;
    int line_count = 0, var_count = 0;
    ssize_t line_size;
    FILE *fp = fopen(path, "r");

    if (!fp) {
        fprintf(stderr, "Error opening file '%s'\n", path);
        return 0;
    }

    /* Get the first line of the file. */
    line_size = getline(&line_buf, &line_buf_size, fp);

    /* Loop through until we are done with the file. */
    while (line_size >= 0 && var_count < MAX_VAR_COUNT) {
        /* Increment our line count */
        line_count++;

        // get pointer to key, and integer value
        str_key = strtok(line_buf, " ");
        value = parse_int(strtok(NULL, " "));

        // save value
        values[var_count] = value;

        // dynamically allocate key
        if ((keys[var_count] = malloc(strlen(str_key) + 1)) == NULL) {
            perror("");
            exit(EXIT_FAILURE);
        }
        strcpy(keys[var_count], str_key);

        // add the key-value pair to the hash table
        g_hash_table_insert(vars_ht, keys[var_count], &values[var_count]);

        var_count++;

        /* Get the next line */
        line_size = getline(&line_buf, &line_buf_size, fp);
    }

    /* Free the allocated line buffer */
    free(line_buf);
    line_buf = NULL;

    /* Close the file now that we are done with it */
    fclose(fp);

    return var_count;
}

void ht_destroy(ht_t *ht, char **keys, int count) {
    g_hash_table_destroy(ht);
    for (int i = 0; i < count; i ++)
        free(keys[i]);
}

// DESCRIPTION: launches a debugger command line interface (a la GDB)
//   on the device at the designated serial port
void debug_cli(char *path, int serial_port) {
    char *line;
    int err = 0;

    // create and populate a hash table of variables
    char *keys[MAX_VAR_COUNT];
    word_t values[MAX_VAR_COUNT];
    ht_t *vars_ht = g_hash_table_new(g_str_hash, g_str_equal);

    // get path to config file
    const char *home_dir = getenv("HOME");
    char config_path[strlen(home_dir) + strlen(REL_CONFIG_PATH) + 1];
    strcpy(config_path, home_dir);
    strcat(config_path, REL_CONFIG_PATH);
    // populate variables from file
    int vc = populate_vars(vars_ht, keys, values, config_path);

    if (vc > 0) {
        printf("\nUsing variables:\n");
        for (int i = 0; i < vc; i++) {
            printf("  %s = 0x%08X (%d)\n", keys[i], values[i], values[i]);
        }
    }

    printf("\n" CYAN "UART Debugger\n" RESET);
    printf("Enter 'h' for usage details.\n");

    // run until EOD is read
    while (1) {
        // prompt
        printf("\nuart-db @ %s", path);
        if (paused)
            printf(" (paused)\n");
        else
            printf("\n");
        line = (err) ? readline(RED "$ " RESET) : readline(GREEN "$ " RESET);

        if (line[0] == '!') {
            err = 0;
            system(line + 1);
        }

        // help message
        else if (match_strs(line, "h")) {
            help();
            err = 0;
        }

        // quit/exit
        else if (match_strs(line, "q")) {
            free(line);
            ht_destroy(vars_ht, keys, vc);
            return;
        } else if (match_strs(line, "exit")) {
            free(line);
            ht_destroy(vars_ht, keys, vc);
            return;
        } else if (!line) {
            free(line);
            ht_destroy(vars_ht, keys, vc);
            return;
        } else if (*line) {
            add_history(line);
            err = parse_cmd(line, serial_port, vars_ht);
        }

        // don't forget to free!
        free(line);
        line = (char *)NULL;
    }
}

// god help us
int parse_register_addr(ht_t *vars, char *tok) {
    if (tok[0] == 'x')
        return parse_int(tok + sizeof(char));
    if (match_strs(tok, X0))
        return 0;
    else if (match_strs(tok, X1))
        return 1;
    else if (match_strs(tok, X2))
        return 2;
    else if (match_strs(tok, X3))
        return 3;
    else if (match_strs(tok, X4))
        return 4;
    else if (match_strs(tok, X5))
        return 5;
    else if (match_strs(tok, X6))
        return 6;
    else if (match_strs(tok, X7))
        return 7;
    else if (match_strs(tok, X8))
        return 8;
    else if (match_strs(tok, X9))
        return 9;
    else if (match_strs(tok, X10))
        return 10;
    else if (match_strs(tok, X11))
        return 11;
    else if (match_strs(tok, X12))
        return 12;
    else if (match_strs(tok, X13))
        return 13;
    else if (match_strs(tok, X14))
        return 14;
    else if (match_strs(tok, X15))
        return 15;
    else if (match_strs(tok, X16))
        return 16;
    else if (match_strs(tok, X17))
        return 17;
    else if (match_strs(tok, X18))
        return 18;
    else if (match_strs(tok, X19))
        return 19;
    else if (match_strs(tok, X20))
        return 20;
    else if (match_strs(tok, X21))
        return 21;
    else if (match_strs(tok, X22))
        return 22;
    else if (match_strs(tok, X23))
        return 23;
    else if (match_strs(tok, X24))
        return 24;
    else if (match_strs(tok, X25))
        return 25;
    else if (match_strs(tok, X26))
        return 26;
    else if (match_strs(tok, X27))
        return 27;
    else if (match_strs(tok, X28))
        return 28;
    else if (match_strs(tok, X29))
        return 29;
    else if (match_strs(tok, X30))
        return 30;
    else if (match_strs(tok, X31))
        return 31;
    else
        return get_num(vars, tok);
}
