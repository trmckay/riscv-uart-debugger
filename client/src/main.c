#include "cli.h"
#include "serial.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void usage(char *msg);
void parse_args(int argc, char *argv[], char **path);
void start(char *path);
void autodetect();

int main(int argc, char *argv[]) {
    char *term_path;

    parse_args(argc, argv, &term_path);
    start(term_path);
}

void usage(char *msg) {
    if (msg != NULL)
        fprintf(stderr, "%s\n", msg);
    fprintf(stderr, "Usage: uart-db [-v] <serial port>\n");
    exit(EXIT_FAILURE);
}

void retry() {
    char new_path[256];
    char *line;

    // prompt for path
    line = readline("\nEnter device: ");
    if (strlen(line) > 255) {
        fprintf(stderr, "Error: path too long\n");
        free(line);
        exit(EXIT_FAILURE);
    }
    memcpy(new_path, line, strlen(line) + 1);
    free(line);
    start(new_path);
}

void parse_args(int argc, char *argv[], char **path) {

    if (argc == 1) {
        printf("Autodetect suitible serial ports in '/dev'? ");
        char *line = readline("[y/N]: ");
        if (strcmp(line, "Y") == 0 || strcmp(line, "y") == 0) {
            autodetect();
            exit(EXIT_SUCCESS);
        } else {
            fprintf(stderr, "Not autodetecting\n");
            retry();
            exit(EXIT_FAILURE);
        }
    }
    if (argc > 2) {
        usage("Error: too many arguments");
        exit(EXIT_FAILURE);
    }

    *path = argv[1];
}

void start(char *path) {
    int serial_port = -1;

    if (open_serial(path, &serial_port))
        retry();

    // quick connection test
    if (connection_test(serial_port, 64, 0))
        retry();

    printf(
        "\nA stable connection has been established. Launching debugger...\n");

    // launch debug cli on device at serial_port
    debug_cli(path, serial_port);
    restore_term(serial_port);
}

int starts_with(char *cmp, char *str) {
    int l = strlen(str);
    for (int i = 0; i < l; i++) {
        if (cmp[i] != str[i])
            return 0;
    }
    return 1;
}

int poll(char *path) {
    int serial_port;

    if (open_serial(path, &serial_port))
        return 0;
    else if (connection_test(serial_port, 16, 0)) {
        restore_term(serial_port);
        return 0;
    }
    debug_cli(path, serial_port);
    return 1;
}

void autodetect() {
    DIR *dir;
    struct dirent *ent;
    char full_path[256] = "/dev/";

    printf("Autodetecting devices...\n");
    if ((dir = opendir("/dev")) != NULL) {
        while ((ent = readdir(dir)) != NULL) {
            if (starts_with(ent->d_name, "ttyS") ||
                starts_with(ent->d_name, "ttyUSB")) {
                printf("\nTrying %s...\n", ent->d_name);
                strcat(full_path, ent->d_name);
                if (poll(full_path)) {
                    return;
                }
            }
            full_path[5] = 0;
        }
        closedir(dir);
    } else
        perror("");
    fprintf(
        stderr,
        RED "\nError: autodetection failed\n\n" RESET
        "Note: Often times, devices will be inaccessible without first modifying permissions.\n"
        "You can grant access yourself with:\n"
        "\n    sudo chmod o+rw <device>\n\n"
        "Or, you can run the program as superuser.\n");
    
    char *line = readline("\nProceed with a different device? [y/N]: ");
    if (strcmp(line, "Y") == 0 || strcmp(line, "y") == 0)
        retry();
    else
        exit(EXIT_FAILURE);
}
