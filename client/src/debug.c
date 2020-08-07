#include "debug.h"

// DESCRIPTION: Sends a command in the following format to the device.
//              HOST                 TARGET
//          command (word) ------------>
//               <---------------- echo command
//          address (word) ------------>
//               <---------------- echo address
//          data (word) --------------->
//               <---------------- echo data
//                              executes command...
//                               ...    
//                                    ...
//                                         ...
//               <---------------- reply (word)
//
// ARGUMENTS:
//   serial_port: the FD of the device
//           cmd: word containing the command code (see debug.h)
//          addr: word address on which the command should be applied
//          data: word of data that should be written
//          argc: the number of arguments the command depends on
//                (i.e pause is zero, write memory is 2)
//         reply: pointer to a word that will store the read data
//
// RETURNS: Non-zero if the command files in the client (i.e. echo incorrect).
int send_cmd(int serial_port, uint32_t cmd, uint32_t addr, uint32_t data,
             int argc, uint32_t *reply) {
    uint32_t r;

    // send command bytes
    if (send_word(serial_port, cmd)) {
        fprintf(stderr, "Critical error: failed to send command bytes\n");
        exit(EXIT_FAILURE);
    }
    if (read_word(serial_port, &r)) {
        fprintf(stderr,
                "Critical error: could not read echo of command bytes\n");
        exit(EXIT_FAILURE);
    }
    if (r != cmd) {
        fprintf(stderr, "Error: echo did not match command bytes\n");
        return 1;
    }

    // send address bytes
    if (send_word(serial_port, addr)) {
        fprintf(stderr, "Critical error: failed to send command bytes\n");
        exit(EXIT_FAILURE);
    }
    if (read_word(serial_port, &r)) {
        fprintf(stderr,
                "Critical error: could not read echo of command bytes\n");
        exit(EXIT_FAILURE);
    }
    // only check that echo matches if argc includes this
    if ((argc >= 1) && (r != addr)) {
        fprintf(stderr, "Error: echo did not match address bytes\n");
        return 1;
    }

    // send data bytes
    if (send_word(serial_port, data)) {
        fprintf(stderr, "Critical error: failed to send command bytes\n");
        exit(EXIT_FAILURE);
    }
    if (read_word(serial_port, &r)) {
        fprintf(stderr,
                "Critical error: could not read echo of command bytes\n");
        exit(EXIT_FAILURE);
    }
    // only check that echo matches if argc includes this
    if ((argc >= 2) && (r != data)) {
        fprintf(stderr, "Error: echo did not match address bytes\n");
        return 1;
    }

    if (read_word(serial_port, &r)) {
        fprintf(stderr, "Critical error: did not recieve final reply\n");
        exit(EXIT_FAILURE);
    }

    // return reply and success code
    *reply = r;
    return 0;
}

// DESCRIPTION: Run a test to verify the integrity of the connection
// RETURNS: 1 if failed, 0 if success
int connection_test(int serial_port, int n, int logging) {
    int misses = 0;
    int do_log = logging;
    uint32_t r, s;
    FILE *log;

    // start stopwatch
    time_t t_start;
    time(&t_start);

    // open file for logging
    if (do_log) {
        log = fopen("test.log", "w");
        if (log == NULL) {
            fprintf(stderr, "Error: could not open test.log for writing\n");
            do_log = 0;
        }
    }

    // actual number of kilobytes transfered
    float nkb = (float)(n * 7 * 4) / 1024;
    // number of useful kilobytes transfered
    float nukb = (float)(n * 4) / 1024;
    printf("Testing connection with %d commands (%.2f kB)\n", n, nkb);

    // the following loop will:
    //   - Send a bunch of NONE commands to the MCU
    //   - Send random address/data words
    //   - Check and keep track of invalid echos
    for (int i = 0; i < n; i++) {
        fprintf(stderr, "Progress: %.1f%%\r", (float)(i * 100) / n);

        s = 0;
        if (send_word(serial_port, s)) {
            fprintf(stderr, "Error: failed to send data\n");
            return 3;
        }
        if (read_word(serial_port, &r)) {
            fprintf(stderr, "Error: did not recieve a reply\n");
            return 2;
        }
        if (r != 0)
            misses += 1;

        if (do_log)
            fprintf(log, "[%d]\nsent: 0x00000000, recieved: 0x%08X\n", i + 1,
                    r);

        // send random addr
        s = rand();
        if (send_word(serial_port, s)) {
            fprintf(stderr, "Error: failed to send data\n");
            return 3;
        }
        if (read_word(serial_port, &r)) {
            fprintf(stderr, "Error: did not recieve a reply\n");
            return 2;
        }
        if (s != r)
            misses += 1;

        if (do_log)
            fprintf(log, "sent: 0x%08X, recieved: 0x%08X\n", s, r);

        // send random data
        s = rand();
        if (send_word(serial_port, s)) {
            fprintf(stderr, "Error: failed to send data\n");
            return 3;
        }
        if (read_word(serial_port, &r)) {
            fprintf(stderr, "Error: did not recieve a reply\n");
            return 2;
        }
        if (s != r)
            misses += 1;

        if (do_log)
            fprintf(log, "sent: 0x%08X, recieved: 0x%08X\n\n", s, r);

        // wait for final reply
        read_word(serial_port, &r);
    }

    // stop the stopwatch
    time_t t_fin;
    time(&t_fin);

    // print out some useful data
    int dt = (int)(t_fin - t_start);
    float acc = (float)((3 * n) - misses) / (3 * n);
    printf("                           ");
    printf("\n  Actual: %.2f kB in %ds (%.2f kB/s)\n", nkb, dt, nkb / dt);
    printf("Apparent: %.2f kB in %ds (%.2f kB/s)\n", nukb, dt, nukb / dt);
    printf((acc > 0.99999) ? GREEN : RED);
    printf("Accuracy: %.2f\n", acc);
    printf(RESET);
    if (do_log)
        printf("\nSee details in test.log\n");

    if (acc < 0.95) {
        fprintf(
            stderr,
            "Error: Connection test failed due to low transmission accuracy\n");
        fprintf(stderr, "Make sure the connection is secure or try a higher "
                        "quality cable.\n");
        return 1;
    } else
        return 0;
}

////// DEBUGGER FUNCTIONS /////////////////////////////
// Request that the MCU perform some sort of operation

int mcu_pause(int serial_port) {
    uint32_t r;
    return send_cmd(serial_port, FN_PAUSE, 0, 0, 0, &r);
}

int mcu_resume(int serial_port) {
    uint32_t r;
    return send_cmd(serial_port, FN_RESUME, 0, 0, 0, &r);
}

int mcu_step(int serial_port) {
    uint32_t r;
    return send_cmd(serial_port, FN_STEP, 0, 0, 0, &r);
}

int mcu_reset(int serial_port) {
    uint32_t r;
    return send_cmd(serial_port, FN_RESET, 0, 0, 0, &r);
}

int mcu_status(int serial_port, int *status) {
    uint32_t r;
    if (send_cmd(serial_port, FN_STATUS, 0, 0, 0, &r))
        return 1;
    *status = r;
    return 0;
}

int mcu_add_breakpoint(int serial_port, uint32_t addr) {
    uint32_t r;
    return send_cmd(serial_port, FN_BR_PT_ADD, addr, 0, 1, &r);
}

int mcu_rm_breakpoint(int serial_port, uint32_t index) {
    uint32_t r;
    return send_cmd(serial_port, FN_BR_PT_RM, index, 0, 1, &r);
}

int mcu_reg_read(int serial_port, uint32_t addr, uint32_t *data) {
    uint32_t r;
    if (send_cmd(serial_port, FN_REG_RD, addr, 0, 1, &r))
        return 1;
    *data = r;
    return 0;
}

int mcu_reg_write(int serial_port, uint32_t addr, uint32_t data) {
    uint32_t r;
    return send_cmd(serial_port, FN_REG_WR, addr, data, 2, &r);
}

int mcu_mem_read_byte(int serial_port, uint32_t addr, byte_t *data) {
    uint32_t r;
    if (send_cmd(serial_port, FN_MEM_WR_BYTE, addr, 0, 1, &r))
        return 1;
    *data = r;
    return 0;
}

int mcu_mem_write_word(int serial_port, uint32_t addr, uint32_t data) {
    uint32_t r;
    return send_cmd(serial_port, FN_MEM_WR_WORD, addr, data, 2, &r);
}

int mcu_mem_write_byte(int serial_port, uint32_t addr, byte_t data) {
    uint32_t r;
    return send_cmd(serial_port, FN_MEM_WR_BYTE, addr, data, 2, &r);
}

int mcu_mem_read_word(int serial_port, uint32_t addr, uint32_t *data) {
    uint32_t r;
    if (send_cmd(serial_port, FN_MEM_RD_WORD, addr, 0, 1, &r))
        return 1;
    *data = r;
    return 0;
}

int mcu_program(int serial_port, char *path) {
    off_t n;
    uint32_t w, addr = 0x0;
    int f;

    if ((f = open_file(path, &n)) == -1) {
        fprintf(stderr, "Error: could not program with %s\n", path);
        return 1;
    }
    for (int i = 0; i < n; i++) {
        fprintf(stderr, "Progress: %.1f%%\r", (float)i * 100 / n);
        if (read_word_file(f, &w))
            return 1;
        if (mcu_mem_write_word(serial_port, addr, w))
            return 1;
        addr += 0x4;
    }
    printf("\nProgramming successful!\n");
    return 0;
}
