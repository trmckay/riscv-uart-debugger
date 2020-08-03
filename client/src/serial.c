// Raw I/O UART transciever
// Updated by Trevor McKay
//
// Based on code by Keefe Johnson:
//     https://github.com/KeefeJ/otter_debugger
//
// Original terminal config code from:
//     https://www.gnu.org/software/libc/manual/html_node/Noncanon-Example.html


#include "serial.h"

/* open_serial
 *
 * DESCRIPTION
 * Opens a raw input/output serial connection for transferring bytes
 * at a time.
 *
 * RETURNS
 * Nothing; saves serial port FD to int *serial_port.
 *
 * ARGUMENTS
 * char *path: string of the path to the serial port;
 *     something like /dev/ttyX
 * int *serial_port: pointer to an integer which should be allocated in
 *     the main stack frame or dynamically
 */
int open_serial(char *path, int *serial_port, int verbose)
{
    term_sa saved_attributes;

    struct termios tattr;

    printf("Opening serial port...");
    if ((*serial_port = open(path, O_RDWR)) == -1) {
        fprintf(stderr, "Error: open(%s): %s\n", path, strerror(errno));
        return 1;
    }
    printf("done!\n");

    /* Make sure the port is a terminal. */
    if (!isatty(*serial_port)) {
        fprintf(stderr, "Error: file is not a terminal\n");
        return 2;
    }

    /* Save the terminal attributes so we can restore them later. */
    printf("Reading terminal attributes and saving for restore...");
    tcgetattr(*serial_port, &saved_attributes);
    printf("done!\n");

    printf("Flushing transmit buffer and setting raw mode...");
    // Set the funny terminal modes.
    tcgetattr(*serial_port, &tattr);
    tattr.c_oflag &= ~OPOST;  // raw output
    tattr.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG | ECHONL | IEXTEN);  // raw input
    tattr.c_cflag &= ~(CSIZE | PARENB | CSTOPB);  // 8N1 ...
    tattr.c_cflag |= (CS8 | CLOCAL | CREAD);      // ... and enable without ownership
    // more raw input, and no software flow control
    tattr.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON | IXOFF | IXANY);
    tattr.c_cc[VMIN] = MIN_BYTES;
    tattr.c_cc[VTIME] = INTER_BYTE_TIMEOUT;  // allow up to 1.0 secs between bytes received
    cfsetospeed(&tattr, BAUD);    // set baud rate
    tcsetattr(*serial_port, TCSAFLUSH, &tattr);
    printf("done!\n");

    printf("Ready to communicate!\n");
    return 0;
}

void send_word(int serial_port, uint32_t w, int verbose)
{
    if (verbose)
        printf("Sending 0x%08X...", w);

    ssize_t bw;
    w = htonl(w);
    bw = write(serial_port, &w, 4);
    if (bw == -1)
    {
        perror("write(serial)");
        exit(EXIT_FAILURE);
    }
    if (bw != 4)
    {
        fprintf(stderr, "Error: wrote only %ld of 4 bytes\n", bw);
        exit(EXIT_FAILURE);
    }
    if (verbose)
        printf("done!\n");
}

uint32_t recv_word(int serial_port)
{
    uint32_t w;
    ssize_t br;
    w = 0;
    br = read(serial_port, &w, 4);
    if (br == -1)
    {
        perror("read(serial)");
        exit(EXIT_FAILURE);
    }
    if (br != 4)
    {
        fprintf(stderr, "Error: read only %ld of 4 bytes: 0x%08X\n", br, ntohl(w));
        exit(EXIT_FAILURE);
    }
    return ntohl(w);
}

int wait_readable(int serial_port, int msec)
{
    int r;
    fd_set set;
    struct timeval timeout;
    FD_ZERO(&set);
    FD_SET(serial_port, &set);
    timeout.tv_sec = msec / 1000;
    timeout.tv_usec = (msec % 1000) * 1000;
    r = select(serial_port + 1, &set, NULL, NULL, &timeout);
    if (r == -1)
    {
        perror("select");
        exit(EXIT_FAILURE);
    }
    return FD_ISSET(serial_port, &set);
}

// returns 1 if words match
int expect_word(int serial_port, uint32_t expect, int verbose)
{
    uint32_t r;

    if (verbose)
        printf("Waiting for a response...");

    if (wait_readable(serial_port, TIMEOUT_MSEC))
    {
        if ((r = recv_word(serial_port)) != expect)
        {
            fprintf(stderr, "Error: expected 0x%08X but received 0x%08X\n", expect, r);
            return 0;
        }
    }
    else 
    {
        fprintf(stderr, "Error: expected 0x%08X but received nothing\n", expect);
        return 0;
    }
    
    if (verbose)
        printf("recieved 0x%08X\n", r);

    return 1;
}

uint32_t expect_any_word(int serial_port, int verbose)
{   
    if (verbose)
        printf("Waiting for a response...");

    if (wait_readable(serial_port, TIMEOUT_MSEC))
    {   
        uint32_t r = recv_word(serial_port);
        if (verbose)
            printf("recieved 0x%08X\n", r);
        return r;
    }
    else
    {
        fprintf(stderr, "Error: expected a word but received nothing\n");
        exit(EXIT_FAILURE);
    }
}
