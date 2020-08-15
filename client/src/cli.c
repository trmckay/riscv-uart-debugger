#include "cli.h"

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
void help() {
    printf(HELP_MSG);
}

// DESCRIPTION: takes the command as a string, and applies it to the serial port
// RETURNS: 0 for success, non-zero for error
// TODO: this probably needs to be split by command in the future
//   or it will quickly grow too large to maintain
int parse_cmd(char *line, int serial_port) {
    char *cmd, *s_a1, *s_a2;

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
            return 1;
        }
        if ((a1 = parse_int(s_a1)) < 1) {
            fprintf(stderr, "Error: usage: t <number>\n");
            return 1;
        }
        return connection_test(serial_port, a1, 1, 0);
    }

    // pause
    if (match_strs(cmd, PAUSE_TOKEN)) {
        printf("Pause MCU\n");
        if (mcu_pause(serial_port)) {
            return 1;
        } else {
            paused = 1;
            return 0;
        }
    }

    // resume
    if (match_strs(cmd, RESUME_TOKEN)) {
        printf("Resume MCU\n");
        if (mcu_resume(serial_port)) {
            return 1;
        } else {
            paused = 0;
            return 0;
        }
    }

    // program
    if (match_strs(cmd, PROGRAM_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: pr <mem.bin> [-f]\n");
            return 1;
        }

        if (mcu_pause(serial_port))
            return 1;

        if (mcu_program(serial_port, s_a1, 1)) {
            fprintf(stderr, "Error: failed to program MCU\n");
            return 1;
        }

        if (mcu_reset(serial_port))
            return 1;

        if (mcu_resume(serial_port))
            return 1;

        return 0;
    }

    // step
    if (match_strs(cmd, STEP_TOKEN)) {
        printf("Step\n");
        return mcu_step(serial_port);
    }

    // reset
    if (match_strs(cmd, RESET_TOKEN)) {
        printf("Reset MCU\n");
        return mcu_reset(serial_port);
    }

    // status (not implemented)
    if (match_strs(cmd, STATUS_TOKEN)) {
        printf("Request MCU status\n");
        fprintf(stderr, "Warning: not implemented\n");
        int s, err;
        err = (mcu_status(serial_port, &s));
        printf("Status: %d\n", s);
        return err;
    }

    // add breakpoint
    if (match_strs(cmd, BPADD_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: b <pc>\n");
            return 1;
        }
        a1 = parse_int(s_a1);

        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] < 0) {
                bps[i] = a1;
                printf("Add breakpoint %d @ pc = 0x%08X\n", i, a1);
                return mcu_add_breakpoint(serial_port, a1);
            }
        }
        fprintf(stderr, "Error: max number of breakpoints reached\n");
        return 1;
    }

    // delete breakpoint
    if (match_strs(cmd, BPDEL_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: d <bp-num>\n");
            return 1;
        }
        a1 = parse_int(s_a1);
        if (a1 < MAX_BREAK_PTS && bps[a1] >= 0) {
            printf("Delete breakpoint %d @ pc = 0x%08X\n", a1, (word_t)bps[a1]);
            int err = mcu_rm_breakpoint(serial_port, bps[a1]);
            bps[a1] = -1;
            return err;
        } else {
            fprintf(stderr, "Error: breakpoint does not exist\n");
            return 1;
        }
    }

    // clear breakpoints
    if (match_strs(cmd, BPCLR_TOKEN)) {
        printf("Clear breakpoints\n");
        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] >= 0) {
                printf("Delete breakpoint %d @ pc = 0x%08X\n", i, (word_t)bps[i]);
                if (mcu_rm_breakpoint(serial_port, bps[i]))
                    return 1;
                bps[i] = -1;
            }
        }
        return 0;
    }

    // list breakpoints
    if (match_strs(cmd, BPLIST_TOKEN)) {
        printf("List breakpoints\n");
        printf("NUM  |  PC\n");
        for (int i = 0; i < MAX_BREAK_PTS; i++) {
            if (bps[i] > 0)
                printf(" %d   |  0x%08X\n", i, (word_t)bps[i]);
        }
        return 0;
    }

    // read register file
    if (match_strs(cmd, REG_RD_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: rr <reg-num>\n");
            return 1;
        }
        if (!paused) {
            fprintf(stderr, "Error: this operation can only be performed while "
                            "the MCU is paused\n");
            return 1;
        }
        a1 = parse_int(s_a1);
        word_t r;
        int err;
        err = mcu_reg_read(serial_port, a1, &r);
        printf("x%d = %d (0x%08X)\n", a1, r, r);
        return err;
    }

    // write register file
    if (match_strs(cmd, REG_WR_TOKEN)) {
        if (s_a1 == NULL || s_a2 == NULL) {
            fprintf(stderr, "Error: usage: rw <reg-num> <data>\n");
            return 1;
        }
        if ((a1 = parse_int(s_a1)) < 0) {
            fprintf(stderr, "Error: address must be positive integer\n");
        }
        if (!paused) {
            fprintf(stderr, "Error: this operation can only be performed while "
                            "the MCU is paused\n");
            return 1;
        }
        a2 = parse_int(s_a2);
        printf("x%d <- %d (0x%08X)\n", a1, a2, a2);
        return mcu_reg_write(serial_port, a1, a2);
    }

    // read word from memory
    if (match_strs(cmd, MEM_RD_W_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: d <pc>\n");
            return 1;
        }
        if (!paused) {
            fprintf(stderr, "Error: this operation can only be performed while "
                            "the MCU is paused\n");
            return 1;
        }
        a1 = parse_int(s_a1);
        word_t r;
        int err;
        err = mcu_mem_read_word(serial_port, a1, &r);
        printf("MEM[0x%08X] = %d (0x%08X)\n", a1, r, r);
        return err;
    }

    // write word to memory
    if (match_strs(cmd, MEM_WR_W_TOKEN)) {
        if (s_a1 == NULL || s_a2 == NULL) {
            fprintf(stderr, "Error: usage: mww <addr> <data>\n");
            return 1;
        }
        if ((a1 = parse_int(s_a1)) < 0) {
            fprintf(stderr, "Error: address must be positive integer\n");
        }
        if (!paused) {
            fprintf(stderr, "Error: this operation can only be performed while "
                            "the MCU is paused\n");
            return 1;
        }
        a2 = parse_int(s_a2);
        printf("MEM[0x%08X] <- %d (0x%08X)\n", a1, a2, a2);
        return mcu_mem_write_word(serial_port, a1, a2);
    }

    // read byte from memory
    if (match_strs(cmd, MEM_RD_B_TOKEN)) {
        if (s_a1 == NULL) {
            fprintf(stderr, "Error: usage: d <pc>\n");
            return 1;
        }
        if (!paused) {
            fprintf(stderr, "Error: this operation can only be performed while "
                            "the MCU is paused\n");
            return 1;
        }
        a1 = parse_int(s_a1);
        byte_t r;
        int err;
        err = mcu_mem_read_byte(serial_port, a1, &r);
        printf("MEM[0x%08X] = %d (0x%04X)\n", a1, r, r);
        return err;
    }

    // write a byte to memory
    if (match_strs(cmd, MEM_WR_B_TOKEN)) {
        if (s_a1 == NULL || s_a2 == NULL) {
            fprintf(stderr, "Error: usage: mww <0xN | N> <0xN | N>\n");
            return 1;
        }
        if ((a1 = parse_int(s_a1)) < 0) {
            fprintf(stderr, "Error: address must be positive integer\n");
        }
        if (!paused) {
            fprintf(stderr, "Error: this operation can only be performed while "
                            "the MCU is paused\n");
            return 1;
        }
        a2 = parse_int(s_a2);
        printf("MEM[0x%08X] <- %d (0x%04X)\n", a1, a2, a2);
        return mcu_mem_write_byte(serial_port, a1, a2);
    }

    // print unrecognized cmd msg and return error
    unrecognized_cmd(line_copy);
    return 1;
}

// DESCRIPTION: launches a debugger command line interface (a la GDB)
//   on the device at the designated serial port
void debug_cli(char *path, int serial_port) {
    char *line;
    int err = 0;

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
            return;
            // I find myself constantly wanting to exit with "exit"
            // so I've included that for as well
        } else if (match_strs(line, "exit")) {
            free(line);
            return;
            // for exiting on EOD
        } else if (!line) {
            free(line);
            return;
            // parse the line
        } else if (*line) {
            add_history(line);
            err = parse_cmd(line, serial_port);
        }
        // don't forget to free!
        free(line);
    }
}
